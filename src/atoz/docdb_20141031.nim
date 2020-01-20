
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon DocumentDB with MongoDB compatibility
## version: 2014-10-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon DocumentDB API documentation
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
  awsServiceName = "docdb"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTagsToResource_606183 = ref object of OpenApiRestCall_605573
proc url_PostAddTagsToResource_606185(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTagsToResource_606184(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606186 = query.getOrDefault("Action")
  valid_606186 = validateParameter(valid_606186, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_606186 != nil:
    section.add "Action", valid_606186
  var valid_606187 = query.getOrDefault("Version")
  valid_606187 = validateParameter(valid_606187, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_606195 = formData.getOrDefault("Tags")
  valid_606195 = validateParameter(valid_606195, JArray, required = true, default = nil)
  if valid_606195 != nil:
    section.add "Tags", valid_606195
  var valid_606196 = formData.getOrDefault("ResourceName")
  valid_606196 = validateParameter(valid_606196, JString, required = true,
                                 default = nil)
  if valid_606196 != nil:
    section.add "ResourceName", valid_606196
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606197: Call_PostAddTagsToResource_606183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_606197.validator(path, query, header, formData, body)
  let scheme = call_606197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606197.url(scheme.get, call_606197.host, call_606197.base,
                         call_606197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606197, url, valid)

proc call*(call_606198: Call_PostAddTagsToResource_606183; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-10-31"): Recallable =
  ## postAddTagsToResource
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   Version: string (required)
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  var query_606199 = newJObject()
  var formData_606200 = newJObject()
  add(query_606199, "Action", newJString(Action))
  if Tags != nil:
    formData_606200.add "Tags", Tags
  add(query_606199, "Version", newJString(Version))
  add(formData_606200, "ResourceName", newJString(ResourceName))
  result = call_606198.call(nil, query_606199, nil, formData_606200, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_606183(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_606184, base: "/",
    url: url_PostAddTagsToResource_606185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_605911 = ref object of OpenApiRestCall_605573
proc url_GetAddTagsToResource_605913(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddTagsToResource_605912(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_606025 = query.getOrDefault("Tags")
  valid_606025 = validateParameter(valid_606025, JArray, required = true, default = nil)
  if valid_606025 != nil:
    section.add "Tags", valid_606025
  var valid_606026 = query.getOrDefault("ResourceName")
  valid_606026 = validateParameter(valid_606026, JString, required = true,
                                 default = nil)
  if valid_606026 != nil:
    section.add "ResourceName", valid_606026
  var valid_606040 = query.getOrDefault("Action")
  valid_606040 = validateParameter(valid_606040, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_606040 != nil:
    section.add "Action", valid_606040
  var valid_606041 = query.getOrDefault("Version")
  valid_606041 = validateParameter(valid_606041, JString, required = true,
                                 default = newJString("2014-10-31"))
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

proc call*(call_606071: Call_GetAddTagsToResource_605911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_606071.validator(path, query, header, formData, body)
  let scheme = call_606071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606071.url(scheme.get, call_606071.host, call_606071.base,
                         call_606071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606071, url, valid)

proc call*(call_606142: Call_GetAddTagsToResource_605911; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-10-31"): Recallable =
  ## getAddTagsToResource
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606143 = newJObject()
  if Tags != nil:
    query_606143.add "Tags", Tags
  add(query_606143, "ResourceName", newJString(ResourceName))
  add(query_606143, "Action", newJString(Action))
  add(query_606143, "Version", newJString(Version))
  result = call_606142.call(nil, query_606143, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_605911(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_605912, base: "/",
    url: url_GetAddTagsToResource_605913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_606219 = ref object of OpenApiRestCall_605573
proc url_PostApplyPendingMaintenanceAction_606221(protocol: Scheme; host: string;
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

proc validate_PostApplyPendingMaintenanceAction_606220(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606222 = query.getOrDefault("Action")
  valid_606222 = validateParameter(valid_606222, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_606222 != nil:
    section.add "Action", valid_606222
  var valid_606223 = query.getOrDefault("Version")
  valid_606223 = validateParameter(valid_606223, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606223 != nil:
    section.add "Version", valid_606223
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606224 = header.getOrDefault("X-Amz-Signature")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Signature", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Content-Sha256", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Date")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Date", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Credential")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Credential", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Security-Token")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Security-Token", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Algorithm")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Algorithm", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-SignedHeaders", valid_606230
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceIdentifier: JString (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   ApplyAction: JString (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   OptInType: JString (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ResourceIdentifier` field"
  var valid_606231 = formData.getOrDefault("ResourceIdentifier")
  valid_606231 = validateParameter(valid_606231, JString, required = true,
                                 default = nil)
  if valid_606231 != nil:
    section.add "ResourceIdentifier", valid_606231
  var valid_606232 = formData.getOrDefault("ApplyAction")
  valid_606232 = validateParameter(valid_606232, JString, required = true,
                                 default = nil)
  if valid_606232 != nil:
    section.add "ApplyAction", valid_606232
  var valid_606233 = formData.getOrDefault("OptInType")
  valid_606233 = validateParameter(valid_606233, JString, required = true,
                                 default = nil)
  if valid_606233 != nil:
    section.add "OptInType", valid_606233
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606234: Call_PostApplyPendingMaintenanceAction_606219;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_606234.validator(path, query, header, formData, body)
  let scheme = call_606234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606234.url(scheme.get, call_606234.host, call_606234.base,
                         call_606234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606234, url, valid)

proc call*(call_606235: Call_PostApplyPendingMaintenanceAction_606219;
          ResourceIdentifier: string; ApplyAction: string; OptInType: string;
          Action: string = "ApplyPendingMaintenanceAction";
          Version: string = "2014-10-31"): Recallable =
  ## postApplyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ##   ResourceIdentifier: string (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   ApplyAction: string (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   Action: string (required)
  ##   OptInType: string (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  ##   Version: string (required)
  var query_606236 = newJObject()
  var formData_606237 = newJObject()
  add(formData_606237, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_606237, "ApplyAction", newJString(ApplyAction))
  add(query_606236, "Action", newJString(Action))
  add(formData_606237, "OptInType", newJString(OptInType))
  add(query_606236, "Version", newJString(Version))
  result = call_606235.call(nil, query_606236, nil, formData_606237, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_606219(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_606220, base: "/",
    url: url_PostApplyPendingMaintenanceAction_606221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_606201 = ref object of OpenApiRestCall_605573
proc url_GetApplyPendingMaintenanceAction_606203(protocol: Scheme; host: string;
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

proc validate_GetApplyPendingMaintenanceAction_606202(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceIdentifier: JString (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   ApplyAction: JString (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   Action: JString (required)
  ##   OptInType: JString (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `ResourceIdentifier` field"
  var valid_606204 = query.getOrDefault("ResourceIdentifier")
  valid_606204 = validateParameter(valid_606204, JString, required = true,
                                 default = nil)
  if valid_606204 != nil:
    section.add "ResourceIdentifier", valid_606204
  var valid_606205 = query.getOrDefault("ApplyAction")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = nil)
  if valid_606205 != nil:
    section.add "ApplyAction", valid_606205
  var valid_606206 = query.getOrDefault("Action")
  valid_606206 = validateParameter(valid_606206, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_606206 != nil:
    section.add "Action", valid_606206
  var valid_606207 = query.getOrDefault("OptInType")
  valid_606207 = validateParameter(valid_606207, JString, required = true,
                                 default = nil)
  if valid_606207 != nil:
    section.add "OptInType", valid_606207
  var valid_606208 = query.getOrDefault("Version")
  valid_606208 = validateParameter(valid_606208, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606208 != nil:
    section.add "Version", valid_606208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606209 = header.getOrDefault("X-Amz-Signature")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Signature", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Content-Sha256", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Date")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Date", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Credential")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Credential", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Security-Token")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Security-Token", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Algorithm")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Algorithm", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-SignedHeaders", valid_606215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606216: Call_GetApplyPendingMaintenanceAction_606201;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_606216.validator(path, query, header, formData, body)
  let scheme = call_606216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606216.url(scheme.get, call_606216.host, call_606216.base,
                         call_606216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606216, url, valid)

proc call*(call_606217: Call_GetApplyPendingMaintenanceAction_606201;
          ResourceIdentifier: string; ApplyAction: string; OptInType: string;
          Action: string = "ApplyPendingMaintenanceAction";
          Version: string = "2014-10-31"): Recallable =
  ## getApplyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ##   ResourceIdentifier: string (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   ApplyAction: string (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   Action: string (required)
  ##   OptInType: string (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  ##   Version: string (required)
  var query_606218 = newJObject()
  add(query_606218, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_606218, "ApplyAction", newJString(ApplyAction))
  add(query_606218, "Action", newJString(Action))
  add(query_606218, "OptInType", newJString(OptInType))
  add(query_606218, "Version", newJString(Version))
  result = call_606217.call(nil, query_606218, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_606201(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_606202, base: "/",
    url: url_GetApplyPendingMaintenanceAction_606203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_606257 = ref object of OpenApiRestCall_605573
proc url_PostCopyDBClusterParameterGroup_606259(protocol: Scheme; host: string;
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

proc validate_PostCopyDBClusterParameterGroup_606258(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Copies the specified DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606260 = query.getOrDefault("Action")
  valid_606260 = validateParameter(valid_606260, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_606260 != nil:
    section.add "Action", valid_606260
  var valid_606261 = query.getOrDefault("Version")
  valid_606261 = validateParameter(valid_606261, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606261 != nil:
    section.add "Version", valid_606261
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606262 = header.getOrDefault("X-Amz-Signature")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Signature", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Content-Sha256", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Date")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Date", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Credential")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Credential", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Security-Token")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Security-Token", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Algorithm")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Algorithm", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-SignedHeaders", valid_606268
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied DB cluster parameter group.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBClusterParameterGroupIdentifier` field"
  var valid_606269 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_606269 = validateParameter(valid_606269, JString, required = true,
                                 default = nil)
  if valid_606269 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_606269
  var valid_606270 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_606270 = validateParameter(valid_606270, JString, required = true,
                                 default = nil)
  if valid_606270 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_606270
  var valid_606271 = formData.getOrDefault("Tags")
  valid_606271 = validateParameter(valid_606271, JArray, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "Tags", valid_606271
  var valid_606272 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_606272 = validateParameter(valid_606272, JString, required = true,
                                 default = nil)
  if valid_606272 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_606272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606273: Call_PostCopyDBClusterParameterGroup_606257;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_606273.validator(path, query, header, formData, body)
  let scheme = call_606273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606273.url(scheme.get, call_606273.host, call_606273.base,
                         call_606273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606273, url, valid)

proc call*(call_606274: Call_PostCopyDBClusterParameterGroup_606257;
          TargetDBClusterParameterGroupIdentifier: string;
          SourceDBClusterParameterGroupIdentifier: string;
          TargetDBClusterParameterGroupDescription: string;
          Action: string = "CopyDBClusterParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterParameterGroup
  ## Copies the specified DB cluster parameter group.
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   Version: string (required)
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied DB cluster parameter group.
  var query_606275 = newJObject()
  var formData_606276 = newJObject()
  add(formData_606276, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(formData_606276, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_606275, "Action", newJString(Action))
  if Tags != nil:
    formData_606276.add "Tags", Tags
  add(query_606275, "Version", newJString(Version))
  add(formData_606276, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  result = call_606274.call(nil, query_606275, nil, formData_606276, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_606257(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_606258, base: "/",
    url: url_PostCopyDBClusterParameterGroup_606259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_606238 = ref object of OpenApiRestCall_605573
proc url_GetCopyDBClusterParameterGroup_606240(protocol: Scheme; host: string;
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

proc validate_GetCopyDBClusterParameterGroup_606239(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Copies the specified DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Action: JString (required)
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TargetDBClusterParameterGroupDescription` field"
  var valid_606241 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_606241 = validateParameter(valid_606241, JString, required = true,
                                 default = nil)
  if valid_606241 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_606241
  var valid_606242 = query.getOrDefault("Tags")
  valid_606242 = validateParameter(valid_606242, JArray, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "Tags", valid_606242
  var valid_606243 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_606243 = validateParameter(valid_606243, JString, required = true,
                                 default = nil)
  if valid_606243 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_606243
  var valid_606244 = query.getOrDefault("Action")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_606244 != nil:
    section.add "Action", valid_606244
  var valid_606245 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_606245 = validateParameter(valid_606245, JString, required = true,
                                 default = nil)
  if valid_606245 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_606245
  var valid_606246 = query.getOrDefault("Version")
  valid_606246 = validateParameter(valid_606246, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606246 != nil:
    section.add "Version", valid_606246
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606247 = header.getOrDefault("X-Amz-Signature")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Signature", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Content-Sha256", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Date")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Date", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Credential")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Credential", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Security-Token")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Security-Token", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Algorithm")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Algorithm", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-SignedHeaders", valid_606253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606254: Call_GetCopyDBClusterParameterGroup_606238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_606254.validator(path, query, header, formData, body)
  let scheme = call_606254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606254.url(scheme.get, call_606254.host, call_606254.base,
                         call_606254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606254, url, valid)

proc call*(call_606255: Call_GetCopyDBClusterParameterGroup_606238;
          TargetDBClusterParameterGroupDescription: string;
          TargetDBClusterParameterGroupIdentifier: string;
          SourceDBClusterParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCopyDBClusterParameterGroup
  ## Copies the specified DB cluster parameter group.
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Action: string (required)
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_606256 = newJObject()
  add(query_606256, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    query_606256.add "Tags", Tags
  add(query_606256, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_606256, "Action", newJString(Action))
  add(query_606256, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_606256, "Version", newJString(Version))
  result = call_606255.call(nil, query_606256, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_606238(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_606239, base: "/",
    url: url_GetCopyDBClusterParameterGroup_606240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_606298 = ref object of OpenApiRestCall_605573
proc url_PostCopyDBClusterSnapshot_606300(protocol: Scheme; host: string;
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

proc validate_PostCopyDBClusterSnapshot_606299(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606301 = query.getOrDefault("Action")
  valid_606301 = validateParameter(valid_606301, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_606301 != nil:
    section.add "Action", valid_606301
  var valid_606302 = query.getOrDefault("Version")
  valid_606302 = validateParameter(valid_606302, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606302 != nil:
    section.add "Version", valid_606302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606303 = header.getOrDefault("X-Amz-Signature")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Signature", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Content-Sha256", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Date")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Date", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Credential")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Credential", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Security-Token")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Security-Token", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Algorithm")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Algorithm", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-SignedHeaders", valid_606309
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_606310 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_606310 = validateParameter(valid_606310, JString, required = true,
                                 default = nil)
  if valid_606310 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_606310
  var valid_606311 = formData.getOrDefault("KmsKeyId")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "KmsKeyId", valid_606311
  var valid_606312 = formData.getOrDefault("PreSignedUrl")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "PreSignedUrl", valid_606312
  var valid_606313 = formData.getOrDefault("CopyTags")
  valid_606313 = validateParameter(valid_606313, JBool, required = false, default = nil)
  if valid_606313 != nil:
    section.add "CopyTags", valid_606313
  var valid_606314 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_606314 = validateParameter(valid_606314, JString, required = true,
                                 default = nil)
  if valid_606314 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_606314
  var valid_606315 = formData.getOrDefault("Tags")
  valid_606315 = validateParameter(valid_606315, JArray, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "Tags", valid_606315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606316: Call_PostCopyDBClusterSnapshot_606298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_606316.validator(path, query, header, formData, body)
  let scheme = call_606316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606316.url(scheme.get, call_606316.host, call_606316.base,
                         call_606316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606316, url, valid)

proc call*(call_606317: Call_PostCopyDBClusterSnapshot_606298;
          SourceDBClusterSnapshotIdentifier: string;
          TargetDBClusterSnapshotIdentifier: string; KmsKeyId: string = "";
          PreSignedUrl: string = ""; CopyTags: bool = false;
          Action: string = "CopyDBClusterSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Version: string (required)
  var query_606318 = newJObject()
  var formData_606319 = newJObject()
  add(formData_606319, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_606319, "KmsKeyId", newJString(KmsKeyId))
  add(formData_606319, "PreSignedUrl", newJString(PreSignedUrl))
  add(formData_606319, "CopyTags", newJBool(CopyTags))
  add(formData_606319, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_606318, "Action", newJString(Action))
  if Tags != nil:
    formData_606319.add "Tags", Tags
  add(query_606318, "Version", newJString(Version))
  result = call_606317.call(nil, query_606318, nil, formData_606319, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_606298(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_606299, base: "/",
    url: url_PostCopyDBClusterSnapshot_606300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_606277 = ref object of OpenApiRestCall_605573
proc url_GetCopyDBClusterSnapshot_606279(protocol: Scheme; host: string;
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

proc validate_GetCopyDBClusterSnapshot_606278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Action: JString (required)
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_606280 = query.getOrDefault("Tags")
  valid_606280 = validateParameter(valid_606280, JArray, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "Tags", valid_606280
  var valid_606281 = query.getOrDefault("KmsKeyId")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "KmsKeyId", valid_606281
  var valid_606282 = query.getOrDefault("PreSignedUrl")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "PreSignedUrl", valid_606282
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_606283 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_606283
  var valid_606284 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_606284 = validateParameter(valid_606284, JString, required = true,
                                 default = nil)
  if valid_606284 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_606284
  var valid_606285 = query.getOrDefault("Action")
  valid_606285 = validateParameter(valid_606285, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_606285 != nil:
    section.add "Action", valid_606285
  var valid_606286 = query.getOrDefault("CopyTags")
  valid_606286 = validateParameter(valid_606286, JBool, required = false, default = nil)
  if valid_606286 != nil:
    section.add "CopyTags", valid_606286
  var valid_606287 = query.getOrDefault("Version")
  valid_606287 = validateParameter(valid_606287, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606287 != nil:
    section.add "Version", valid_606287
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606288 = header.getOrDefault("X-Amz-Signature")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Signature", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Content-Sha256", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Date")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Date", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Credential")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Credential", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Security-Token")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Security-Token", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Algorithm")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Algorithm", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-SignedHeaders", valid_606294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606295: Call_GetCopyDBClusterSnapshot_606277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_606295.validator(path, query, header, formData, body)
  let scheme = call_606295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606295.url(scheme.get, call_606295.host, call_606295.base,
                         call_606295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606295, url, valid)

proc call*(call_606296: Call_GetCopyDBClusterSnapshot_606277;
          TargetDBClusterSnapshotIdentifier: string;
          SourceDBClusterSnapshotIdentifier: string; Tags: JsonNode = nil;
          KmsKeyId: string = ""; PreSignedUrl: string = "";
          Action: string = "CopyDBClusterSnapshot"; CopyTags: bool = false;
          Version: string = "2014-10-31"): Recallable =
  ## getCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Action: string (required)
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Version: string (required)
  var query_606297 = newJObject()
  if Tags != nil:
    query_606297.add "Tags", Tags
  add(query_606297, "KmsKeyId", newJString(KmsKeyId))
  add(query_606297, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_606297, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_606297, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_606297, "Action", newJString(Action))
  add(query_606297, "CopyTags", newJBool(CopyTags))
  add(query_606297, "Version", newJString(Version))
  result = call_606296.call(nil, query_606297, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_606277(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_606278, base: "/",
    url: url_GetCopyDBClusterSnapshot_606279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_606353 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBCluster_606355(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBCluster_606354(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606356 = query.getOrDefault("Action")
  valid_606356 = validateParameter(valid_606356, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_606356 != nil:
    section.add "Action", valid_606356
  var valid_606357 = query.getOrDefault("Version")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606357 != nil:
    section.add "Version", valid_606357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606358 = header.getOrDefault("X-Amz-Signature")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Signature", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Content-Sha256", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Date")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Date", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Credential")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Credential", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Security-Token")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Security-Token", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Algorithm")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Algorithm", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-SignedHeaders", valid_606364
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   DBSubnetGroupName: JString
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  section = newJObject()
  var valid_606365 = formData.getOrDefault("Port")
  valid_606365 = validateParameter(valid_606365, JInt, required = false, default = nil)
  if valid_606365 != nil:
    section.add "Port", valid_606365
  var valid_606366 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "PreferredMaintenanceWindow", valid_606366
  var valid_606367 = formData.getOrDefault("PreferredBackupWindow")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "PreferredBackupWindow", valid_606367
  assert formData != nil, "formData argument is necessary due to required `MasterUserPassword` field"
  var valid_606368 = formData.getOrDefault("MasterUserPassword")
  valid_606368 = validateParameter(valid_606368, JString, required = true,
                                 default = nil)
  if valid_606368 != nil:
    section.add "MasterUserPassword", valid_606368
  var valid_606369 = formData.getOrDefault("MasterUsername")
  valid_606369 = validateParameter(valid_606369, JString, required = true,
                                 default = nil)
  if valid_606369 != nil:
    section.add "MasterUsername", valid_606369
  var valid_606370 = formData.getOrDefault("EngineVersion")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "EngineVersion", valid_606370
  var valid_606371 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_606371 = validateParameter(valid_606371, JArray, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "VpcSecurityGroupIds", valid_606371
  var valid_606372 = formData.getOrDefault("AvailabilityZones")
  valid_606372 = validateParameter(valid_606372, JArray, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "AvailabilityZones", valid_606372
  var valid_606373 = formData.getOrDefault("BackupRetentionPeriod")
  valid_606373 = validateParameter(valid_606373, JInt, required = false, default = nil)
  if valid_606373 != nil:
    section.add "BackupRetentionPeriod", valid_606373
  var valid_606374 = formData.getOrDefault("Engine")
  valid_606374 = validateParameter(valid_606374, JString, required = true,
                                 default = nil)
  if valid_606374 != nil:
    section.add "Engine", valid_606374
  var valid_606375 = formData.getOrDefault("KmsKeyId")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "KmsKeyId", valid_606375
  var valid_606376 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_606376 = validateParameter(valid_606376, JArray, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "EnableCloudwatchLogsExports", valid_606376
  var valid_606377 = formData.getOrDefault("Tags")
  valid_606377 = validateParameter(valid_606377, JArray, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "Tags", valid_606377
  var valid_606378 = formData.getOrDefault("DBSubnetGroupName")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "DBSubnetGroupName", valid_606378
  var valid_606379 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "DBClusterParameterGroupName", valid_606379
  var valid_606380 = formData.getOrDefault("StorageEncrypted")
  valid_606380 = validateParameter(valid_606380, JBool, required = false, default = nil)
  if valid_606380 != nil:
    section.add "StorageEncrypted", valid_606380
  var valid_606381 = formData.getOrDefault("DBClusterIdentifier")
  valid_606381 = validateParameter(valid_606381, JString, required = true,
                                 default = nil)
  if valid_606381 != nil:
    section.add "DBClusterIdentifier", valid_606381
  var valid_606382 = formData.getOrDefault("DeletionProtection")
  valid_606382 = validateParameter(valid_606382, JBool, required = false, default = nil)
  if valid_606382 != nil:
    section.add "DeletionProtection", valid_606382
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606383: Call_PostCreateDBCluster_606353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_606383.validator(path, query, header, formData, body)
  let scheme = call_606383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606383.url(scheme.get, call_606383.host, call_606383.base,
                         call_606383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606383, url, valid)

proc call*(call_606384: Call_PostCreateDBCluster_606353;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBClusterIdentifier: string; Port: int = 0;
          PreferredMaintenanceWindow: string = "";
          PreferredBackupWindow: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZones: JsonNode = nil;
          BackupRetentionPeriod: int = 0; KmsKeyId: string = "";
          EnableCloudwatchLogsExports: JsonNode = nil;
          Action: string = "CreateDBCluster"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; DBClusterParameterGroupName: string = "";
          Version: string = "2014-10-31"; StorageEncrypted: bool = false;
          DeletionProtection: bool = false): Recallable =
  ## postCreateDBCluster
  ## Creates a new Amazon DocumentDB DB cluster.
  ##   Port: int
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   DBSubnetGroupName: string
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   Version: string (required)
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  var query_606385 = newJObject()
  var formData_606386 = newJObject()
  add(formData_606386, "Port", newJInt(Port))
  add(formData_606386, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_606386, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_606386, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_606386, "MasterUsername", newJString(MasterUsername))
  add(formData_606386, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_606386.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_606386.add "AvailabilityZones", AvailabilityZones
  add(formData_606386, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_606386, "Engine", newJString(Engine))
  add(formData_606386, "KmsKeyId", newJString(KmsKeyId))
  if EnableCloudwatchLogsExports != nil:
    formData_606386.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_606385, "Action", newJString(Action))
  if Tags != nil:
    formData_606386.add "Tags", Tags
  add(formData_606386, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_606386, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_606385, "Version", newJString(Version))
  add(formData_606386, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_606386, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_606386, "DeletionProtection", newJBool(DeletionProtection))
  result = call_606384.call(nil, query_606385, nil, formData_606386, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_606353(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_606354, base: "/",
    url: url_PostCreateDBCluster_606355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_606320 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBCluster_606322(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBCluster_606321(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   Action: JString (required)
  ##   Port: JInt
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DBSubnetGroupName: JString
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_606323 = query.getOrDefault("StorageEncrypted")
  valid_606323 = validateParameter(valid_606323, JBool, required = false, default = nil)
  if valid_606323 != nil:
    section.add "StorageEncrypted", valid_606323
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_606324 = query.getOrDefault("Engine")
  valid_606324 = validateParameter(valid_606324, JString, required = true,
                                 default = nil)
  if valid_606324 != nil:
    section.add "Engine", valid_606324
  var valid_606325 = query.getOrDefault("DeletionProtection")
  valid_606325 = validateParameter(valid_606325, JBool, required = false, default = nil)
  if valid_606325 != nil:
    section.add "DeletionProtection", valid_606325
  var valid_606326 = query.getOrDefault("Tags")
  valid_606326 = validateParameter(valid_606326, JArray, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "Tags", valid_606326
  var valid_606327 = query.getOrDefault("KmsKeyId")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "KmsKeyId", valid_606327
  var valid_606328 = query.getOrDefault("DBClusterIdentifier")
  valid_606328 = validateParameter(valid_606328, JString, required = true,
                                 default = nil)
  if valid_606328 != nil:
    section.add "DBClusterIdentifier", valid_606328
  var valid_606329 = query.getOrDefault("DBClusterParameterGroupName")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "DBClusterParameterGroupName", valid_606329
  var valid_606330 = query.getOrDefault("AvailabilityZones")
  valid_606330 = validateParameter(valid_606330, JArray, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "AvailabilityZones", valid_606330
  var valid_606331 = query.getOrDefault("MasterUsername")
  valid_606331 = validateParameter(valid_606331, JString, required = true,
                                 default = nil)
  if valid_606331 != nil:
    section.add "MasterUsername", valid_606331
  var valid_606332 = query.getOrDefault("BackupRetentionPeriod")
  valid_606332 = validateParameter(valid_606332, JInt, required = false, default = nil)
  if valid_606332 != nil:
    section.add "BackupRetentionPeriod", valid_606332
  var valid_606333 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_606333 = validateParameter(valid_606333, JArray, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "EnableCloudwatchLogsExports", valid_606333
  var valid_606334 = query.getOrDefault("EngineVersion")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "EngineVersion", valid_606334
  var valid_606335 = query.getOrDefault("Action")
  valid_606335 = validateParameter(valid_606335, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_606335 != nil:
    section.add "Action", valid_606335
  var valid_606336 = query.getOrDefault("Port")
  valid_606336 = validateParameter(valid_606336, JInt, required = false, default = nil)
  if valid_606336 != nil:
    section.add "Port", valid_606336
  var valid_606337 = query.getOrDefault("VpcSecurityGroupIds")
  valid_606337 = validateParameter(valid_606337, JArray, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "VpcSecurityGroupIds", valid_606337
  var valid_606338 = query.getOrDefault("MasterUserPassword")
  valid_606338 = validateParameter(valid_606338, JString, required = true,
                                 default = nil)
  if valid_606338 != nil:
    section.add "MasterUserPassword", valid_606338
  var valid_606339 = query.getOrDefault("DBSubnetGroupName")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "DBSubnetGroupName", valid_606339
  var valid_606340 = query.getOrDefault("PreferredBackupWindow")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "PreferredBackupWindow", valid_606340
  var valid_606341 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "PreferredMaintenanceWindow", valid_606341
  var valid_606342 = query.getOrDefault("Version")
  valid_606342 = validateParameter(valid_606342, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606342 != nil:
    section.add "Version", valid_606342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606343 = header.getOrDefault("X-Amz-Signature")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Signature", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Content-Sha256", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Date")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Date", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Credential")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Credential", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Security-Token")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Security-Token", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Algorithm")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Algorithm", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-SignedHeaders", valid_606349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606350: Call_GetCreateDBCluster_606320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_606350.validator(path, query, header, formData, body)
  let scheme = call_606350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606350.url(scheme.get, call_606350.host, call_606350.base,
                         call_606350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606350, url, valid)

proc call*(call_606351: Call_GetCreateDBCluster_606320; Engine: string;
          DBClusterIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; StorageEncrypted: bool = false;
          DeletionProtection: bool = false; Tags: JsonNode = nil; KmsKeyId: string = "";
          DBClusterParameterGroupName: string = "";
          AvailabilityZones: JsonNode = nil; BackupRetentionPeriod: int = 0;
          EnableCloudwatchLogsExports: JsonNode = nil; EngineVersion: string = "";
          Action: string = "CreateDBCluster"; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; DBSubnetGroupName: string = "";
          PreferredBackupWindow: string = "";
          PreferredMaintenanceWindow: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBCluster
  ## Creates a new Amazon DocumentDB DB cluster.
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   Action: string (required)
  ##   Port: int
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DBSubnetGroupName: string
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   Version: string (required)
  var query_606352 = newJObject()
  add(query_606352, "StorageEncrypted", newJBool(StorageEncrypted))
  add(query_606352, "Engine", newJString(Engine))
  add(query_606352, "DeletionProtection", newJBool(DeletionProtection))
  if Tags != nil:
    query_606352.add "Tags", Tags
  add(query_606352, "KmsKeyId", newJString(KmsKeyId))
  add(query_606352, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_606352, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if AvailabilityZones != nil:
    query_606352.add "AvailabilityZones", AvailabilityZones
  add(query_606352, "MasterUsername", newJString(MasterUsername))
  add(query_606352, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if EnableCloudwatchLogsExports != nil:
    query_606352.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_606352, "EngineVersion", newJString(EngineVersion))
  add(query_606352, "Action", newJString(Action))
  add(query_606352, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_606352.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_606352, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_606352, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606352, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_606352, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_606352, "Version", newJString(Version))
  result = call_606351.call(nil, query_606352, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_606320(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_606321,
    base: "/", url: url_GetCreateDBCluster_606322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_606406 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBClusterParameterGroup_606408(protocol: Scheme; host: string;
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

proc validate_PostCreateDBClusterParameterGroup_606407(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606409 = query.getOrDefault("Action")
  valid_606409 = validateParameter(valid_606409, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_606409 != nil:
    section.add "Action", valid_606409
  var valid_606410 = query.getOrDefault("Version")
  valid_606410 = validateParameter(valid_606410, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606410 != nil:
    section.add "Version", valid_606410
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##              : The description for the DB cluster parameter group.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The DB cluster parameter group family name.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_606418 = formData.getOrDefault("Description")
  valid_606418 = validateParameter(valid_606418, JString, required = true,
                                 default = nil)
  if valid_606418 != nil:
    section.add "Description", valid_606418
  var valid_606419 = formData.getOrDefault("Tags")
  valid_606419 = validateParameter(valid_606419, JArray, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "Tags", valid_606419
  var valid_606420 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_606420 = validateParameter(valid_606420, JString, required = true,
                                 default = nil)
  if valid_606420 != nil:
    section.add "DBClusterParameterGroupName", valid_606420
  var valid_606421 = formData.getOrDefault("DBParameterGroupFamily")
  valid_606421 = validateParameter(valid_606421, JString, required = true,
                                 default = nil)
  if valid_606421 != nil:
    section.add "DBParameterGroupFamily", valid_606421
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606422: Call_PostCreateDBClusterParameterGroup_606406;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_606422.validator(path, query, header, formData, body)
  let scheme = call_606422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606422.url(scheme.get, call_606422.host, call_606422.base,
                         call_606422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606422, url, valid)

proc call*(call_606423: Call_PostCreateDBClusterParameterGroup_606406;
          Description: string; DBClusterParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBClusterParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterParameterGroup
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Description: string (required)
  ##              : The description for the DB cluster parameter group.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##                         : The DB cluster parameter group family name.
  var query_606424 = newJObject()
  var formData_606425 = newJObject()
  add(formData_606425, "Description", newJString(Description))
  add(query_606424, "Action", newJString(Action))
  if Tags != nil:
    formData_606425.add "Tags", Tags
  add(formData_606425, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_606424, "Version", newJString(Version))
  add(formData_606425, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_606423.call(nil, query_606424, nil, formData_606425, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_606406(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_606407, base: "/",
    url: url_PostCreateDBClusterParameterGroup_606408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_606387 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBClusterParameterGroup_606389(protocol: Scheme; host: string;
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

proc validate_GetCreateDBClusterParameterGroup_606388(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The DB cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Action: JString (required)
  ##   Description: JString (required)
  ##              : The description for the DB cluster parameter group.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_606390 = query.getOrDefault("DBParameterGroupFamily")
  valid_606390 = validateParameter(valid_606390, JString, required = true,
                                 default = nil)
  if valid_606390 != nil:
    section.add "DBParameterGroupFamily", valid_606390
  var valid_606391 = query.getOrDefault("Tags")
  valid_606391 = validateParameter(valid_606391, JArray, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "Tags", valid_606391
  var valid_606392 = query.getOrDefault("DBClusterParameterGroupName")
  valid_606392 = validateParameter(valid_606392, JString, required = true,
                                 default = nil)
  if valid_606392 != nil:
    section.add "DBClusterParameterGroupName", valid_606392
  var valid_606393 = query.getOrDefault("Action")
  valid_606393 = validateParameter(valid_606393, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_606393 != nil:
    section.add "Action", valid_606393
  var valid_606394 = query.getOrDefault("Description")
  valid_606394 = validateParameter(valid_606394, JString, required = true,
                                 default = nil)
  if valid_606394 != nil:
    section.add "Description", valid_606394
  var valid_606395 = query.getOrDefault("Version")
  valid_606395 = validateParameter(valid_606395, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606395 != nil:
    section.add "Version", valid_606395
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606396 = header.getOrDefault("X-Amz-Signature")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Signature", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Content-Sha256", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Date")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Date", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Credential")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Credential", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Security-Token")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Security-Token", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Algorithm")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Algorithm", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-SignedHeaders", valid_606402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_GetCreateDBClusterParameterGroup_606387;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_GetCreateDBClusterParameterGroup_606387;
          DBParameterGroupFamily: string; DBClusterParameterGroupName: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterParameterGroup
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   DBParameterGroupFamily: string (required)
  ##                         : The DB cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Action: string (required)
  ##   Description: string (required)
  ##              : The description for the DB cluster parameter group.
  ##   Version: string (required)
  var query_606405 = newJObject()
  add(query_606405, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_606405.add "Tags", Tags
  add(query_606405, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_606405, "Action", newJString(Action))
  add(query_606405, "Description", newJString(Description))
  add(query_606405, "Version", newJString(Version))
  result = call_606404.call(nil, query_606405, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_606387(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_606388, base: "/",
    url: url_GetCreateDBClusterParameterGroup_606389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_606444 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBClusterSnapshot_606446(protocol: Scheme; host: string;
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

proc validate_PostCreateDBClusterSnapshot_606445(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a snapshot of a DB cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606447 = query.getOrDefault("Action")
  valid_606447 = validateParameter(valid_606447, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_606447 != nil:
    section.add "Action", valid_606447
  var valid_606448 = query.getOrDefault("Version")
  valid_606448 = validateParameter(valid_606448, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606448 != nil:
    section.add "Version", valid_606448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606449 = header.getOrDefault("X-Amz-Signature")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Signature", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Content-Sha256", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Date")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Date", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Credential")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Credential", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Security-Token")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Security-Token", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Algorithm")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Algorithm", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-SignedHeaders", valid_606455
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_606456 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_606456 = validateParameter(valid_606456, JString, required = true,
                                 default = nil)
  if valid_606456 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_606456
  var valid_606457 = formData.getOrDefault("Tags")
  valid_606457 = validateParameter(valid_606457, JArray, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "Tags", valid_606457
  var valid_606458 = formData.getOrDefault("DBClusterIdentifier")
  valid_606458 = validateParameter(valid_606458, JString, required = true,
                                 default = nil)
  if valid_606458 != nil:
    section.add "DBClusterIdentifier", valid_606458
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606459: Call_PostCreateDBClusterSnapshot_606444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_606459.validator(path, query, header, formData, body)
  let scheme = call_606459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606459.url(scheme.get, call_606459.host, call_606459.base,
                         call_606459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606459, url, valid)

proc call*(call_606460: Call_PostCreateDBClusterSnapshot_606444;
          DBClusterSnapshotIdentifier: string; DBClusterIdentifier: string;
          Action: string = "CreateDBClusterSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterSnapshot
  ## Creates a snapshot of a DB cluster. 
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  var query_606461 = newJObject()
  var formData_606462 = newJObject()
  add(formData_606462, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_606461, "Action", newJString(Action))
  if Tags != nil:
    formData_606462.add "Tags", Tags
  add(query_606461, "Version", newJString(Version))
  add(formData_606462, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_606460.call(nil, query_606461, nil, formData_606462, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_606444(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_606445, base: "/",
    url: url_PostCreateDBClusterSnapshot_606446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_606426 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBClusterSnapshot_606428(protocol: Scheme; host: string;
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

proc validate_GetCreateDBClusterSnapshot_606427(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a snapshot of a DB cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_606429 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_606429 = validateParameter(valid_606429, JString, required = true,
                                 default = nil)
  if valid_606429 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_606429
  var valid_606430 = query.getOrDefault("Tags")
  valid_606430 = validateParameter(valid_606430, JArray, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "Tags", valid_606430
  var valid_606431 = query.getOrDefault("DBClusterIdentifier")
  valid_606431 = validateParameter(valid_606431, JString, required = true,
                                 default = nil)
  if valid_606431 != nil:
    section.add "DBClusterIdentifier", valid_606431
  var valid_606432 = query.getOrDefault("Action")
  valid_606432 = validateParameter(valid_606432, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_606432 != nil:
    section.add "Action", valid_606432
  var valid_606433 = query.getOrDefault("Version")
  valid_606433 = validateParameter(valid_606433, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606433 != nil:
    section.add "Version", valid_606433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606434 = header.getOrDefault("X-Amz-Signature")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Signature", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Content-Sha256", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Date")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Date", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Credential")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Credential", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Security-Token")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Security-Token", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Algorithm")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Algorithm", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-SignedHeaders", valid_606440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606441: Call_GetCreateDBClusterSnapshot_606426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_606441.validator(path, query, header, formData, body)
  let scheme = call_606441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606441.url(scheme.get, call_606441.host, call_606441.base,
                         call_606441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606441, url, valid)

proc call*(call_606442: Call_GetCreateDBClusterSnapshot_606426;
          DBClusterSnapshotIdentifier: string; DBClusterIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBClusterSnapshot";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterSnapshot
  ## Creates a snapshot of a DB cluster. 
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606443 = newJObject()
  add(query_606443, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_606443.add "Tags", Tags
  add(query_606443, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_606443, "Action", newJString(Action))
  add(query_606443, "Version", newJString(Version))
  result = call_606442.call(nil, query_606443, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_606426(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_606427, base: "/",
    url: url_GetCreateDBClusterSnapshot_606428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_606487 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBInstance_606489(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_606488(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new DB instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606490 = query.getOrDefault("Action")
  valid_606490 = validateParameter(valid_606490, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_606490 != nil:
    section.add "Action", valid_606490
  var valid_606491 = query.getOrDefault("Version")
  valid_606491 = validateParameter(valid_606491, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606491 != nil:
    section.add "Version", valid_606491
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606492 = header.getOrDefault("X-Amz-Signature")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Signature", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Content-Sha256", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Date")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Date", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Credential")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Credential", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Security-Token")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Security-Token", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Algorithm")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Algorithm", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-SignedHeaders", valid_606498
  result.add "header", section
  ## parameters in `formData` object:
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  section = newJObject()
  var valid_606499 = formData.getOrDefault("PromotionTier")
  valid_606499 = validateParameter(valid_606499, JInt, required = false, default = nil)
  if valid_606499 != nil:
    section.add "PromotionTier", valid_606499
  var valid_606500 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "PreferredMaintenanceWindow", valid_606500
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_606501 = formData.getOrDefault("DBInstanceClass")
  valid_606501 = validateParameter(valid_606501, JString, required = true,
                                 default = nil)
  if valid_606501 != nil:
    section.add "DBInstanceClass", valid_606501
  var valid_606502 = formData.getOrDefault("AvailabilityZone")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "AvailabilityZone", valid_606502
  var valid_606503 = formData.getOrDefault("Engine")
  valid_606503 = validateParameter(valid_606503, JString, required = true,
                                 default = nil)
  if valid_606503 != nil:
    section.add "Engine", valid_606503
  var valid_606504 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_606504 = validateParameter(valid_606504, JBool, required = false, default = nil)
  if valid_606504 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606504
  var valid_606505 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606505 = validateParameter(valid_606505, JString, required = true,
                                 default = nil)
  if valid_606505 != nil:
    section.add "DBInstanceIdentifier", valid_606505
  var valid_606506 = formData.getOrDefault("Tags")
  valid_606506 = validateParameter(valid_606506, JArray, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "Tags", valid_606506
  var valid_606507 = formData.getOrDefault("DBClusterIdentifier")
  valid_606507 = validateParameter(valid_606507, JString, required = true,
                                 default = nil)
  if valid_606507 != nil:
    section.add "DBClusterIdentifier", valid_606507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_PostCreateDBInstance_606487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_PostCreateDBInstance_606487; DBInstanceClass: string;
          Engine: string; DBInstanceIdentifier: string; DBClusterIdentifier: string;
          PromotionTier: int = 0; PreferredMaintenanceWindow: string = "";
          AvailabilityZone: string = ""; AutoMinorVersionUpgrade: bool = false;
          Action: string = "CreateDBInstance"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBInstance
  ## Creates a new DB instance.
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  var query_606510 = newJObject()
  var formData_606511 = newJObject()
  add(formData_606511, "PromotionTier", newJInt(PromotionTier))
  add(formData_606511, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_606511, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_606511, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_606511, "Engine", newJString(Engine))
  add(formData_606511, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_606511, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606510, "Action", newJString(Action))
  if Tags != nil:
    formData_606511.add "Tags", Tags
  add(query_606510, "Version", newJString(Version))
  add(formData_606511, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_606509.call(nil, query_606510, nil, formData_606511, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_606487(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_606488, base: "/",
    url: url_PostCreateDBInstance_606489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_606463 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBInstance_606465(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_606464(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a new DB instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   Action: JString (required)
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Version: JString (required)
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_606466 = query.getOrDefault("Engine")
  valid_606466 = validateParameter(valid_606466, JString, required = true,
                                 default = nil)
  if valid_606466 != nil:
    section.add "Engine", valid_606466
  var valid_606467 = query.getOrDefault("Tags")
  valid_606467 = validateParameter(valid_606467, JArray, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "Tags", valid_606467
  var valid_606468 = query.getOrDefault("DBClusterIdentifier")
  valid_606468 = validateParameter(valid_606468, JString, required = true,
                                 default = nil)
  if valid_606468 != nil:
    section.add "DBClusterIdentifier", valid_606468
  var valid_606469 = query.getOrDefault("DBInstanceIdentifier")
  valid_606469 = validateParameter(valid_606469, JString, required = true,
                                 default = nil)
  if valid_606469 != nil:
    section.add "DBInstanceIdentifier", valid_606469
  var valid_606470 = query.getOrDefault("PromotionTier")
  valid_606470 = validateParameter(valid_606470, JInt, required = false, default = nil)
  if valid_606470 != nil:
    section.add "PromotionTier", valid_606470
  var valid_606471 = query.getOrDefault("Action")
  valid_606471 = validateParameter(valid_606471, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_606471 != nil:
    section.add "Action", valid_606471
  var valid_606472 = query.getOrDefault("AvailabilityZone")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "AvailabilityZone", valid_606472
  var valid_606473 = query.getOrDefault("Version")
  valid_606473 = validateParameter(valid_606473, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606473 != nil:
    section.add "Version", valid_606473
  var valid_606474 = query.getOrDefault("DBInstanceClass")
  valid_606474 = validateParameter(valid_606474, JString, required = true,
                                 default = nil)
  if valid_606474 != nil:
    section.add "DBInstanceClass", valid_606474
  var valid_606475 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "PreferredMaintenanceWindow", valid_606475
  var valid_606476 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_606476 = validateParameter(valid_606476, JBool, required = false, default = nil)
  if valid_606476 != nil:
    section.add "AutoMinorVersionUpgrade", valid_606476
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606477 = header.getOrDefault("X-Amz-Signature")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Signature", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Content-Sha256", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Date")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Date", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Credential")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Credential", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Security-Token")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Security-Token", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Algorithm")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Algorithm", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-SignedHeaders", valid_606483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606484: Call_GetCreateDBInstance_606463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_606484.validator(path, query, header, formData, body)
  let scheme = call_606484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606484.url(scheme.get, call_606484.host, call_606484.base,
                         call_606484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606484, url, valid)

proc call*(call_606485: Call_GetCreateDBInstance_606463; Engine: string;
          DBClusterIdentifier: string; DBInstanceIdentifier: string;
          DBInstanceClass: string; Tags: JsonNode = nil; PromotionTier: int = 0;
          Action: string = "CreateDBInstance"; AvailabilityZone: string = "";
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false): Recallable =
  ## getCreateDBInstance
  ## Creates a new DB instance.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   Action: string (required)
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Version: string (required)
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  var query_606486 = newJObject()
  add(query_606486, "Engine", newJString(Engine))
  if Tags != nil:
    query_606486.add "Tags", Tags
  add(query_606486, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_606486, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606486, "PromotionTier", newJInt(PromotionTier))
  add(query_606486, "Action", newJString(Action))
  add(query_606486, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_606486, "Version", newJString(Version))
  add(query_606486, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_606486, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_606486, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_606485.call(nil, query_606486, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_606463(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_606464, base: "/",
    url: url_GetCreateDBInstance_606465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_606531 = ref object of OpenApiRestCall_605573
proc url_PostCreateDBSubnetGroup_606533(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_606532(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606534 = query.getOrDefault("Action")
  valid_606534 = validateParameter(valid_606534, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_606534 != nil:
    section.add "Action", valid_606534
  var valid_606535 = query.getOrDefault("Version")
  valid_606535 = validateParameter(valid_606535, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606535 != nil:
    section.add "Version", valid_606535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606536 = header.getOrDefault("X-Amz-Signature")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Signature", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Content-Sha256", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Date")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Date", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Credential")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Credential", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Security-Token")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Security-Token", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Algorithm")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Algorithm", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-SignedHeaders", valid_606542
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the DB subnet group.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_606543 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_606543 = validateParameter(valid_606543, JString, required = true,
                                 default = nil)
  if valid_606543 != nil:
    section.add "DBSubnetGroupDescription", valid_606543
  var valid_606544 = formData.getOrDefault("Tags")
  valid_606544 = validateParameter(valid_606544, JArray, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "Tags", valid_606544
  var valid_606545 = formData.getOrDefault("DBSubnetGroupName")
  valid_606545 = validateParameter(valid_606545, JString, required = true,
                                 default = nil)
  if valid_606545 != nil:
    section.add "DBSubnetGroupName", valid_606545
  var valid_606546 = formData.getOrDefault("SubnetIds")
  valid_606546 = validateParameter(valid_606546, JArray, required = true, default = nil)
  if valid_606546 != nil:
    section.add "SubnetIds", valid_606546
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606547: Call_PostCreateDBSubnetGroup_606531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_606547.validator(path, query, header, formData, body)
  let scheme = call_606547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606547.url(scheme.get, call_606547.host, call_606547.base,
                         call_606547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606547, url, valid)

proc call*(call_606548: Call_PostCreateDBSubnetGroup_606531;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Tags: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postCreateDBSubnetGroup
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the DB subnet group.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  var query_606549 = newJObject()
  var formData_606550 = newJObject()
  add(formData_606550, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_606549, "Action", newJString(Action))
  if Tags != nil:
    formData_606550.add "Tags", Tags
  add(formData_606550, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606549, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_606550.add "SubnetIds", SubnetIds
  result = call_606548.call(nil, query_606549, nil, formData_606550, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_606531(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_606532, base: "/",
    url: url_PostCreateDBSubnetGroup_606533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_606512 = ref object of OpenApiRestCall_605573
proc url_GetCreateDBSubnetGroup_606514(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_606513(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the DB subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_606515 = query.getOrDefault("Tags")
  valid_606515 = validateParameter(valid_606515, JArray, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "Tags", valid_606515
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_606516 = query.getOrDefault("SubnetIds")
  valid_606516 = validateParameter(valid_606516, JArray, required = true, default = nil)
  if valid_606516 != nil:
    section.add "SubnetIds", valid_606516
  var valid_606517 = query.getOrDefault("Action")
  valid_606517 = validateParameter(valid_606517, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_606517 != nil:
    section.add "Action", valid_606517
  var valid_606518 = query.getOrDefault("DBSubnetGroupDescription")
  valid_606518 = validateParameter(valid_606518, JString, required = true,
                                 default = nil)
  if valid_606518 != nil:
    section.add "DBSubnetGroupDescription", valid_606518
  var valid_606519 = query.getOrDefault("DBSubnetGroupName")
  valid_606519 = validateParameter(valid_606519, JString, required = true,
                                 default = nil)
  if valid_606519 != nil:
    section.add "DBSubnetGroupName", valid_606519
  var valid_606520 = query.getOrDefault("Version")
  valid_606520 = validateParameter(valid_606520, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606520 != nil:
    section.add "Version", valid_606520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606521 = header.getOrDefault("X-Amz-Signature")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Signature", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Content-Sha256", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Date")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Date", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Credential")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Credential", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Security-Token")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Security-Token", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Algorithm")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Algorithm", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-SignedHeaders", valid_606527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606528: Call_GetCreateDBSubnetGroup_606512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_606528.validator(path, query, header, formData, body)
  let scheme = call_606528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606528.url(scheme.get, call_606528.host, call_606528.base,
                         call_606528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606528, url, valid)

proc call*(call_606529: Call_GetCreateDBSubnetGroup_606512; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBSubnetGroup
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the DB subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_606530 = newJObject()
  if Tags != nil:
    query_606530.add "Tags", Tags
  if SubnetIds != nil:
    query_606530.add "SubnetIds", SubnetIds
  add(query_606530, "Action", newJString(Action))
  add(query_606530, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_606530, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606530, "Version", newJString(Version))
  result = call_606529.call(nil, query_606530, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_606512(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_606513, base: "/",
    url: url_GetCreateDBSubnetGroup_606514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_606569 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBCluster_606571(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBCluster_606570(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606572 = query.getOrDefault("Action")
  valid_606572 = validateParameter(valid_606572, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_606572 != nil:
    section.add "Action", valid_606572
  var valid_606573 = query.getOrDefault("Version")
  valid_606573 = validateParameter(valid_606573, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606573 != nil:
    section.add "Version", valid_606573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606574 = header.getOrDefault("X-Amz-Signature")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Signature", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Content-Sha256", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Date")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Date", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Credential")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Credential", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Security-Token")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Security-Token", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Algorithm")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Algorithm", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-SignedHeaders", valid_606580
  result.add "header", section
  ## parameters in `formData` object:
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_606581 = formData.getOrDefault("SkipFinalSnapshot")
  valid_606581 = validateParameter(valid_606581, JBool, required = false, default = nil)
  if valid_606581 != nil:
    section.add "SkipFinalSnapshot", valid_606581
  var valid_606582 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_606582
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_606583 = formData.getOrDefault("DBClusterIdentifier")
  valid_606583 = validateParameter(valid_606583, JString, required = true,
                                 default = nil)
  if valid_606583 != nil:
    section.add "DBClusterIdentifier", valid_606583
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606584: Call_PostDeleteDBCluster_606569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_606584.validator(path, query, header, formData, body)
  let scheme = call_606584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606584.url(scheme.get, call_606584.host, call_606584.base,
                         call_606584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606584, url, valid)

proc call*(call_606585: Call_PostDeleteDBCluster_606569;
          DBClusterIdentifier: string; Action: string = "DeleteDBCluster";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBCluster
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  var query_606586 = newJObject()
  var formData_606587 = newJObject()
  add(query_606586, "Action", newJString(Action))
  add(formData_606587, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_606587, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_606586, "Version", newJString(Version))
  add(formData_606587, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_606585.call(nil, query_606586, nil, formData_606587, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_606569(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_606570, base: "/",
    url: url_PostDeleteDBCluster_606571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_606551 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBCluster_606553(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBCluster_606552(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_606554 = query.getOrDefault("DBClusterIdentifier")
  valid_606554 = validateParameter(valid_606554, JString, required = true,
                                 default = nil)
  if valid_606554 != nil:
    section.add "DBClusterIdentifier", valid_606554
  var valid_606555 = query.getOrDefault("SkipFinalSnapshot")
  valid_606555 = validateParameter(valid_606555, JBool, required = false, default = nil)
  if valid_606555 != nil:
    section.add "SkipFinalSnapshot", valid_606555
  var valid_606556 = query.getOrDefault("Action")
  valid_606556 = validateParameter(valid_606556, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_606556 != nil:
    section.add "Action", valid_606556
  var valid_606557 = query.getOrDefault("Version")
  valid_606557 = validateParameter(valid_606557, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606557 != nil:
    section.add "Version", valid_606557
  var valid_606558 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_606558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606559 = header.getOrDefault("X-Amz-Signature")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Signature", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Content-Sha256", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Date")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Date", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Credential")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Credential", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Security-Token")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Security-Token", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Algorithm")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Algorithm", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-SignedHeaders", valid_606565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606566: Call_GetDeleteDBCluster_606551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_606566.validator(path, query, header, formData, body)
  let scheme = call_606566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606566.url(scheme.get, call_606566.host, call_606566.base,
                         call_606566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606566, url, valid)

proc call*(call_606567: Call_GetDeleteDBCluster_606551;
          DBClusterIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBCluster"; Version: string = "2014-10-31";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBCluster
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  var query_606568 = newJObject()
  add(query_606568, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_606568, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_606568, "Action", newJString(Action))
  add(query_606568, "Version", newJString(Version))
  add(query_606568, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_606567.call(nil, query_606568, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_606551(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_606552,
    base: "/", url: url_GetDeleteDBCluster_606553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_606604 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBClusterParameterGroup_606606(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBClusterParameterGroup_606605(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606607 = query.getOrDefault("Action")
  valid_606607 = validateParameter(valid_606607, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_606607 != nil:
    section.add "Action", valid_606607
  var valid_606608 = query.getOrDefault("Version")
  valid_606608 = validateParameter(valid_606608, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606608 != nil:
    section.add "Version", valid_606608
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606609 = header.getOrDefault("X-Amz-Signature")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Signature", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Content-Sha256", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Date")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Date", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Credential")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Credential", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Security-Token")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Security-Token", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Algorithm")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Algorithm", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-SignedHeaders", valid_606615
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_606616 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_606616 = validateParameter(valid_606616, JString, required = true,
                                 default = nil)
  if valid_606616 != nil:
    section.add "DBClusterParameterGroupName", valid_606616
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606617: Call_PostDeleteDBClusterParameterGroup_606604;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_606617.validator(path, query, header, formData, body)
  let scheme = call_606617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606617.url(scheme.get, call_606617.host, call_606617.base,
                         call_606617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606617, url, valid)

proc call*(call_606618: Call_PostDeleteDBClusterParameterGroup_606604;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_606619 = newJObject()
  var formData_606620 = newJObject()
  add(query_606619, "Action", newJString(Action))
  add(formData_606620, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_606619, "Version", newJString(Version))
  result = call_606618.call(nil, query_606619, nil, formData_606620, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_606604(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_606605, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_606606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_606588 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBClusterParameterGroup_606590(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBClusterParameterGroup_606589(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_606591 = query.getOrDefault("DBClusterParameterGroupName")
  valid_606591 = validateParameter(valid_606591, JString, required = true,
                                 default = nil)
  if valid_606591 != nil:
    section.add "DBClusterParameterGroupName", valid_606591
  var valid_606592 = query.getOrDefault("Action")
  valid_606592 = validateParameter(valid_606592, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_606592 != nil:
    section.add "Action", valid_606592
  var valid_606593 = query.getOrDefault("Version")
  valid_606593 = validateParameter(valid_606593, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606593 != nil:
    section.add "Version", valid_606593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606594 = header.getOrDefault("X-Amz-Signature")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Signature", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Content-Sha256", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Date")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Date", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Credential")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Credential", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Security-Token")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Security-Token", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Algorithm")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Algorithm", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-SignedHeaders", valid_606600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606601: Call_GetDeleteDBClusterParameterGroup_606588;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_606601.validator(path, query, header, formData, body)
  let scheme = call_606601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606601.url(scheme.get, call_606601.host, call_606601.base,
                         call_606601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606601, url, valid)

proc call*(call_606602: Call_GetDeleteDBClusterParameterGroup_606588;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606603 = newJObject()
  add(query_606603, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_606603, "Action", newJString(Action))
  add(query_606603, "Version", newJString(Version))
  result = call_606602.call(nil, query_606603, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_606588(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_606589, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_606590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_606637 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBClusterSnapshot_606639(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBClusterSnapshot_606638(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606640 = query.getOrDefault("Action")
  valid_606640 = validateParameter(valid_606640, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_606640 != nil:
    section.add "Action", valid_606640
  var valid_606641 = query.getOrDefault("Version")
  valid_606641 = validateParameter(valid_606641, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606641 != nil:
    section.add "Version", valid_606641
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606642 = header.getOrDefault("X-Amz-Signature")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Signature", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Content-Sha256", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Date")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Date", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Credential")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Credential", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Security-Token")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Security-Token", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Algorithm")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Algorithm", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-SignedHeaders", valid_606648
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_606649 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_606649 = validateParameter(valid_606649, JString, required = true,
                                 default = nil)
  if valid_606649 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_606649
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606650: Call_PostDeleteDBClusterSnapshot_606637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_606650.validator(path, query, header, formData, body)
  let scheme = call_606650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606650.url(scheme.get, call_606650.host, call_606650.base,
                         call_606650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606650, url, valid)

proc call*(call_606651: Call_PostDeleteDBClusterSnapshot_606637;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606652 = newJObject()
  var formData_606653 = newJObject()
  add(formData_606653, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_606652, "Action", newJString(Action))
  add(query_606652, "Version", newJString(Version))
  result = call_606651.call(nil, query_606652, nil, formData_606653, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_606637(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_606638, base: "/",
    url: url_PostDeleteDBClusterSnapshot_606639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_606621 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBClusterSnapshot_606623(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBClusterSnapshot_606622(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_606624 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_606624 = validateParameter(valid_606624, JString, required = true,
                                 default = nil)
  if valid_606624 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_606624
  var valid_606625 = query.getOrDefault("Action")
  valid_606625 = validateParameter(valid_606625, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_606625 != nil:
    section.add "Action", valid_606625
  var valid_606626 = query.getOrDefault("Version")
  valid_606626 = validateParameter(valid_606626, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606634: Call_GetDeleteDBClusterSnapshot_606621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_606634.validator(path, query, header, formData, body)
  let scheme = call_606634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606634.url(scheme.get, call_606634.host, call_606634.base,
                         call_606634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606634, url, valid)

proc call*(call_606635: Call_GetDeleteDBClusterSnapshot_606621;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606636 = newJObject()
  add(query_606636, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_606636, "Action", newJString(Action))
  add(query_606636, "Version", newJString(Version))
  result = call_606635.call(nil, query_606636, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_606621(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_606622, base: "/",
    url: url_GetDeleteDBClusterSnapshot_606623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_606670 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBInstance_606672(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_606671(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a previously provisioned DB instance. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606673 = query.getOrDefault("Action")
  valid_606673 = validateParameter(valid_606673, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_606673 != nil:
    section.add "Action", valid_606673
  var valid_606674 = query.getOrDefault("Version")
  valid_606674 = validateParameter(valid_606674, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606674 != nil:
    section.add "Version", valid_606674
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606675 = header.getOrDefault("X-Amz-Signature")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Signature", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Content-Sha256", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Date")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Date", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Credential")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Credential", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Security-Token")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Security-Token", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Algorithm")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Algorithm", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-SignedHeaders", valid_606681
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606682 = formData.getOrDefault("DBInstanceIdentifier")
  valid_606682 = validateParameter(valid_606682, JString, required = true,
                                 default = nil)
  if valid_606682 != nil:
    section.add "DBInstanceIdentifier", valid_606682
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606683: Call_PostDeleteDBInstance_606670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_606683.validator(path, query, header, formData, body)
  let scheme = call_606683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606683.url(scheme.get, call_606683.host, call_606683.base,
                         call_606683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606683, url, valid)

proc call*(call_606684: Call_PostDeleteDBInstance_606670;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606685 = newJObject()
  var formData_606686 = newJObject()
  add(formData_606686, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606685, "Action", newJString(Action))
  add(query_606685, "Version", newJString(Version))
  result = call_606684.call(nil, query_606685, nil, formData_606686, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_606670(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_606671, base: "/",
    url: url_PostDeleteDBInstance_606672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_606654 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBInstance_606656(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_606655(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a previously provisioned DB instance. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_606657 = query.getOrDefault("DBInstanceIdentifier")
  valid_606657 = validateParameter(valid_606657, JString, required = true,
                                 default = nil)
  if valid_606657 != nil:
    section.add "DBInstanceIdentifier", valid_606657
  var valid_606658 = query.getOrDefault("Action")
  valid_606658 = validateParameter(valid_606658, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_606658 != nil:
    section.add "Action", valid_606658
  var valid_606659 = query.getOrDefault("Version")
  valid_606659 = validateParameter(valid_606659, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606659 != nil:
    section.add "Version", valid_606659
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606660 = header.getOrDefault("X-Amz-Signature")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Signature", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Content-Sha256", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Date")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Date", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-Credential")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Credential", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Security-Token")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Security-Token", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Algorithm")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Algorithm", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-SignedHeaders", valid_606666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606667: Call_GetDeleteDBInstance_606654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_606667.validator(path, query, header, formData, body)
  let scheme = call_606667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606667.url(scheme.get, call_606667.host, call_606667.base,
                         call_606667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606667, url, valid)

proc call*(call_606668: Call_GetDeleteDBInstance_606654;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606669 = newJObject()
  add(query_606669, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_606669, "Action", newJString(Action))
  add(query_606669, "Version", newJString(Version))
  result = call_606668.call(nil, query_606669, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_606654(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_606655, base: "/",
    url: url_GetDeleteDBInstance_606656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_606703 = ref object of OpenApiRestCall_605573
proc url_PostDeleteDBSubnetGroup_606705(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_606704(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606706 = query.getOrDefault("Action")
  valid_606706 = validateParameter(valid_606706, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_606706 != nil:
    section.add "Action", valid_606706
  var valid_606707 = query.getOrDefault("Version")
  valid_606707 = validateParameter(valid_606707, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606707 != nil:
    section.add "Version", valid_606707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606708 = header.getOrDefault("X-Amz-Signature")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Signature", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Content-Sha256", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Date")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Date", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Credential")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Credential", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Security-Token")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Security-Token", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Algorithm")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Algorithm", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-SignedHeaders", valid_606714
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_606715 = formData.getOrDefault("DBSubnetGroupName")
  valid_606715 = validateParameter(valid_606715, JString, required = true,
                                 default = nil)
  if valid_606715 != nil:
    section.add "DBSubnetGroupName", valid_606715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606716: Call_PostDeleteDBSubnetGroup_606703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_606716.validator(path, query, header, formData, body)
  let scheme = call_606716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606716.url(scheme.get, call_606716.host, call_606716.base,
                         call_606716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606716, url, valid)

proc call*(call_606717: Call_PostDeleteDBSubnetGroup_606703;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_606718 = newJObject()
  var formData_606719 = newJObject()
  add(query_606718, "Action", newJString(Action))
  add(formData_606719, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606718, "Version", newJString(Version))
  result = call_606717.call(nil, query_606718, nil, formData_606719, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_606703(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_606704, base: "/",
    url: url_PostDeleteDBSubnetGroup_606705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_606687 = ref object of OpenApiRestCall_605573
proc url_GetDeleteDBSubnetGroup_606689(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_606688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606690 = query.getOrDefault("Action")
  valid_606690 = validateParameter(valid_606690, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_606690 != nil:
    section.add "Action", valid_606690
  var valid_606691 = query.getOrDefault("DBSubnetGroupName")
  valid_606691 = validateParameter(valid_606691, JString, required = true,
                                 default = nil)
  if valid_606691 != nil:
    section.add "DBSubnetGroupName", valid_606691
  var valid_606692 = query.getOrDefault("Version")
  valid_606692 = validateParameter(valid_606692, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606692 != nil:
    section.add "Version", valid_606692
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606693 = header.getOrDefault("X-Amz-Signature")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Signature", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Content-Sha256", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Date")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Date", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Credential")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Credential", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Security-Token")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Security-Token", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Algorithm")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Algorithm", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-SignedHeaders", valid_606699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606700: Call_GetDeleteDBSubnetGroup_606687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_606700.validator(path, query, header, formData, body)
  let scheme = call_606700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606700.url(scheme.get, call_606700.host, call_606700.base,
                         call_606700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606700, url, valid)

proc call*(call_606701: Call_GetDeleteDBSubnetGroup_606687;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_606702 = newJObject()
  add(query_606702, "Action", newJString(Action))
  add(query_606702, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_606702, "Version", newJString(Version))
  result = call_606701.call(nil, query_606702, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_606687(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_606688, base: "/",
    url: url_GetDeleteDBSubnetGroup_606689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeCertificates_606739 = ref object of OpenApiRestCall_605573
proc url_PostDescribeCertificates_606741(protocol: Scheme; host: string;
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

proc validate_PostDescribeCertificates_606740(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606742 = query.getOrDefault("Action")
  valid_606742 = validateParameter(valid_606742, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_606742 != nil:
    section.add "Action", valid_606742
  var valid_606743 = query.getOrDefault("Version")
  valid_606743 = validateParameter(valid_606743, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   MaxRecords: JInt
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   CertificateIdentifier: JString
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_606751 = formData.getOrDefault("MaxRecords")
  valid_606751 = validateParameter(valid_606751, JInt, required = false, default = nil)
  if valid_606751 != nil:
    section.add "MaxRecords", valid_606751
  var valid_606752 = formData.getOrDefault("Marker")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "Marker", valid_606752
  var valid_606753 = formData.getOrDefault("CertificateIdentifier")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "CertificateIdentifier", valid_606753
  var valid_606754 = formData.getOrDefault("Filters")
  valid_606754 = validateParameter(valid_606754, JArray, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "Filters", valid_606754
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606755: Call_PostDescribeCertificates_606739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_606755.validator(path, query, header, formData, body)
  let scheme = call_606755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606755.url(scheme.get, call_606755.host, call_606755.base,
                         call_606755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606755, url, valid)

proc call*(call_606756: Call_PostDescribeCertificates_606739; MaxRecords: int = 0;
          Marker: string = ""; CertificateIdentifier: string = "";
          Action: string = "DescribeCertificates"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ##   MaxRecords: int
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   CertificateIdentifier: string
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  var query_606757 = newJObject()
  var formData_606758 = newJObject()
  add(formData_606758, "MaxRecords", newJInt(MaxRecords))
  add(formData_606758, "Marker", newJString(Marker))
  add(formData_606758, "CertificateIdentifier", newJString(CertificateIdentifier))
  add(query_606757, "Action", newJString(Action))
  if Filters != nil:
    formData_606758.add "Filters", Filters
  add(query_606757, "Version", newJString(Version))
  result = call_606756.call(nil, query_606757, nil, formData_606758, nil)

var postDescribeCertificates* = Call_PostDescribeCertificates_606739(
    name: "postDescribeCertificates", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_PostDescribeCertificates_606740, base: "/",
    url: url_PostDescribeCertificates_606741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeCertificates_606720 = ref object of OpenApiRestCall_605573
proc url_GetDescribeCertificates_606722(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeCertificates_606721(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   CertificateIdentifier: JString
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  section = newJObject()
  var valid_606723 = query.getOrDefault("Marker")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "Marker", valid_606723
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606724 = query.getOrDefault("Action")
  valid_606724 = validateParameter(valid_606724, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_606724 != nil:
    section.add "Action", valid_606724
  var valid_606725 = query.getOrDefault("Version")
  valid_606725 = validateParameter(valid_606725, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606725 != nil:
    section.add "Version", valid_606725
  var valid_606726 = query.getOrDefault("CertificateIdentifier")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "CertificateIdentifier", valid_606726
  var valid_606727 = query.getOrDefault("Filters")
  valid_606727 = validateParameter(valid_606727, JArray, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "Filters", valid_606727
  var valid_606728 = query.getOrDefault("MaxRecords")
  valid_606728 = validateParameter(valid_606728, JInt, required = false, default = nil)
  if valid_606728 != nil:
    section.add "MaxRecords", valid_606728
  result.add "query", section
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

proc call*(call_606736: Call_GetDescribeCertificates_606720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_606736.validator(path, query, header, formData, body)
  let scheme = call_606736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606736.url(scheme.get, call_606736.host, call_606736.base,
                         call_606736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606736, url, valid)

proc call*(call_606737: Call_GetDescribeCertificates_606720; Marker: string = "";
          Action: string = "DescribeCertificates"; Version: string = "2014-10-31";
          CertificateIdentifier: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0): Recallable =
  ## getDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CertificateIdentifier: string
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  var query_606738 = newJObject()
  add(query_606738, "Marker", newJString(Marker))
  add(query_606738, "Action", newJString(Action))
  add(query_606738, "Version", newJString(Version))
  add(query_606738, "CertificateIdentifier", newJString(CertificateIdentifier))
  if Filters != nil:
    query_606738.add "Filters", Filters
  add(query_606738, "MaxRecords", newJInt(MaxRecords))
  result = call_606737.call(nil, query_606738, nil, nil, nil)

var getDescribeCertificates* = Call_GetDescribeCertificates_606720(
    name: "getDescribeCertificates", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_GetDescribeCertificates_606721, base: "/",
    url: url_GetDescribeCertificates_606722, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_606778 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBClusterParameterGroups_606780(protocol: Scheme;
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

proc validate_PostDescribeDBClusterParameterGroups_606779(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606781 = query.getOrDefault("Action")
  valid_606781 = validateParameter(valid_606781, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_606781 != nil:
    section.add "Action", valid_606781
  var valid_606782 = query.getOrDefault("Version")
  valid_606782 = validateParameter(valid_606782, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606782 != nil:
    section.add "Version", valid_606782
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606783 = header.getOrDefault("X-Amz-Signature")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Signature", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Content-Sha256", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Date")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Date", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Credential")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Credential", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Security-Token")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Security-Token", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Algorithm")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Algorithm", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-SignedHeaders", valid_606789
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  section = newJObject()
  var valid_606790 = formData.getOrDefault("MaxRecords")
  valid_606790 = validateParameter(valid_606790, JInt, required = false, default = nil)
  if valid_606790 != nil:
    section.add "MaxRecords", valid_606790
  var valid_606791 = formData.getOrDefault("Marker")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "Marker", valid_606791
  var valid_606792 = formData.getOrDefault("Filters")
  valid_606792 = validateParameter(valid_606792, JArray, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "Filters", valid_606792
  var valid_606793 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "DBClusterParameterGroupName", valid_606793
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606794: Call_PostDescribeDBClusterParameterGroups_606778;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_606794.validator(path, query, header, formData, body)
  let scheme = call_606794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606794.url(scheme.get, call_606794.host, call_606794.base,
                         call_606794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606794, url, valid)

proc call*(call_606795: Call_PostDescribeDBClusterParameterGroups_606778;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBClusterParameterGroups";
          Filters: JsonNode = nil; DBClusterParameterGroupName: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_606796 = newJObject()
  var formData_606797 = newJObject()
  add(formData_606797, "MaxRecords", newJInt(MaxRecords))
  add(formData_606797, "Marker", newJString(Marker))
  add(query_606796, "Action", newJString(Action))
  if Filters != nil:
    formData_606797.add "Filters", Filters
  add(formData_606797, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_606796, "Version", newJString(Version))
  result = call_606795.call(nil, query_606796, nil, formData_606797, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_606778(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_606779, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_606780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_606759 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBClusterParameterGroups_606761(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBClusterParameterGroups_606760(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_606762 = query.getOrDefault("Marker")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "Marker", valid_606762
  var valid_606763 = query.getOrDefault("DBClusterParameterGroupName")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "DBClusterParameterGroupName", valid_606763
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606764 = query.getOrDefault("Action")
  valid_606764 = validateParameter(valid_606764, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_606764 != nil:
    section.add "Action", valid_606764
  var valid_606765 = query.getOrDefault("Version")
  valid_606765 = validateParameter(valid_606765, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606765 != nil:
    section.add "Version", valid_606765
  var valid_606766 = query.getOrDefault("Filters")
  valid_606766 = validateParameter(valid_606766, JArray, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "Filters", valid_606766
  var valid_606767 = query.getOrDefault("MaxRecords")
  valid_606767 = validateParameter(valid_606767, JInt, required = false, default = nil)
  if valid_606767 != nil:
    section.add "MaxRecords", valid_606767
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606768 = header.getOrDefault("X-Amz-Signature")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Signature", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Content-Sha256", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Date")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Date", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-Credential")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Credential", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Security-Token")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Security-Token", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Algorithm")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Algorithm", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-SignedHeaders", valid_606774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606775: Call_GetDescribeDBClusterParameterGroups_606759;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_606775.validator(path, query, header, formData, body)
  let scheme = call_606775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606775.url(scheme.get, call_606775.host, call_606775.base,
                         call_606775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606775, url, valid)

proc call*(call_606776: Call_GetDescribeDBClusterParameterGroups_606759;
          Marker: string = ""; DBClusterParameterGroupName: string = "";
          Action: string = "DescribeDBClusterParameterGroups";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_606777 = newJObject()
  add(query_606777, "Marker", newJString(Marker))
  add(query_606777, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_606777, "Action", newJString(Action))
  add(query_606777, "Version", newJString(Version))
  if Filters != nil:
    query_606777.add "Filters", Filters
  add(query_606777, "MaxRecords", newJInt(MaxRecords))
  result = call_606776.call(nil, query_606777, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_606759(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_606760, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_606761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_606818 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBClusterParameters_606820(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBClusterParameters_606819(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606821 = query.getOrDefault("Action")
  valid_606821 = validateParameter(valid_606821, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_606821 != nil:
    section.add "Action", valid_606821
  var valid_606822 = query.getOrDefault("Version")
  valid_606822 = validateParameter(valid_606822, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606822 != nil:
    section.add "Version", valid_606822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606823 = header.getOrDefault("X-Amz-Signature")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Signature", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Content-Sha256", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Date")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Date", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Credential")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Credential", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Security-Token")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Security-Token", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Algorithm")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Algorithm", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-SignedHeaders", valid_606829
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  section = newJObject()
  var valid_606830 = formData.getOrDefault("Source")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "Source", valid_606830
  var valid_606831 = formData.getOrDefault("MaxRecords")
  valid_606831 = validateParameter(valid_606831, JInt, required = false, default = nil)
  if valid_606831 != nil:
    section.add "MaxRecords", valid_606831
  var valid_606832 = formData.getOrDefault("Marker")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "Marker", valid_606832
  var valid_606833 = formData.getOrDefault("Filters")
  valid_606833 = validateParameter(valid_606833, JArray, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "Filters", valid_606833
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_606834 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_606834 = validateParameter(valid_606834, JString, required = true,
                                 default = nil)
  if valid_606834 != nil:
    section.add "DBClusterParameterGroupName", valid_606834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606835: Call_PostDescribeDBClusterParameters_606818;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_606835.validator(path, query, header, formData, body)
  let scheme = call_606835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606835.url(scheme.get, call_606835.host, call_606835.base,
                         call_606835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606835, url, valid)

proc call*(call_606836: Call_PostDescribeDBClusterParameters_606818;
          DBClusterParameterGroupName: string; Source: string = "";
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBClusterParameters"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_606837 = newJObject()
  var formData_606838 = newJObject()
  add(formData_606838, "Source", newJString(Source))
  add(formData_606838, "MaxRecords", newJInt(MaxRecords))
  add(formData_606838, "Marker", newJString(Marker))
  add(query_606837, "Action", newJString(Action))
  if Filters != nil:
    formData_606838.add "Filters", Filters
  add(formData_606838, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_606837, "Version", newJString(Version))
  result = call_606836.call(nil, query_606837, nil, formData_606838, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_606818(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_606819, base: "/",
    url: url_PostDescribeDBClusterParameters_606820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_606798 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBClusterParameters_606800(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBClusterParameters_606799(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Source: JString
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_606801 = query.getOrDefault("Marker")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "Marker", valid_606801
  var valid_606802 = query.getOrDefault("Source")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "Source", valid_606802
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_606803 = query.getOrDefault("DBClusterParameterGroupName")
  valid_606803 = validateParameter(valid_606803, JString, required = true,
                                 default = nil)
  if valid_606803 != nil:
    section.add "DBClusterParameterGroupName", valid_606803
  var valid_606804 = query.getOrDefault("Action")
  valid_606804 = validateParameter(valid_606804, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_606804 != nil:
    section.add "Action", valid_606804
  var valid_606805 = query.getOrDefault("Version")
  valid_606805 = validateParameter(valid_606805, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606805 != nil:
    section.add "Version", valid_606805
  var valid_606806 = query.getOrDefault("Filters")
  valid_606806 = validateParameter(valid_606806, JArray, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "Filters", valid_606806
  var valid_606807 = query.getOrDefault("MaxRecords")
  valid_606807 = validateParameter(valid_606807, JInt, required = false, default = nil)
  if valid_606807 != nil:
    section.add "MaxRecords", valid_606807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606808 = header.getOrDefault("X-Amz-Signature")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Signature", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Content-Sha256", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Date")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Date", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Credential")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Credential", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Security-Token")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Security-Token", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Algorithm")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Algorithm", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-SignedHeaders", valid_606814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606815: Call_GetDescribeDBClusterParameters_606798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_606815.validator(path, query, header, formData, body)
  let scheme = call_606815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606815.url(scheme.get, call_606815.host, call_606815.base,
                         call_606815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606815, url, valid)

proc call*(call_606816: Call_GetDescribeDBClusterParameters_606798;
          DBClusterParameterGroupName: string; Marker: string = "";
          Source: string = ""; Action: string = "DescribeDBClusterParameters";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_606817 = newJObject()
  add(query_606817, "Marker", newJString(Marker))
  add(query_606817, "Source", newJString(Source))
  add(query_606817, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_606817, "Action", newJString(Action))
  add(query_606817, "Version", newJString(Version))
  if Filters != nil:
    query_606817.add "Filters", Filters
  add(query_606817, "MaxRecords", newJInt(MaxRecords))
  result = call_606816.call(nil, query_606817, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_606798(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_606799, base: "/",
    url: url_GetDescribeDBClusterParameters_606800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_606855 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBClusterSnapshotAttributes_606857(protocol: Scheme;
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

proc validate_PostDescribeDBClusterSnapshotAttributes_606856(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606858 = query.getOrDefault("Action")
  valid_606858 = validateParameter(valid_606858, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_606858 != nil:
    section.add "Action", valid_606858
  var valid_606859 = query.getOrDefault("Version")
  valid_606859 = validateParameter(valid_606859, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606859 != nil:
    section.add "Version", valid_606859
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606860 = header.getOrDefault("X-Amz-Signature")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Signature", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Content-Sha256", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Date")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Date", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Credential")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Credential", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Security-Token")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Security-Token", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Algorithm")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Algorithm", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-SignedHeaders", valid_606866
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_606867 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_606867 = validateParameter(valid_606867, JString, required = true,
                                 default = nil)
  if valid_606867 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_606867
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606868: Call_PostDescribeDBClusterSnapshotAttributes_606855;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_606868.validator(path, query, header, formData, body)
  let scheme = call_606868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606868.url(scheme.get, call_606868.host, call_606868.base,
                         call_606868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606868, url, valid)

proc call*(call_606869: Call_PostDescribeDBClusterSnapshotAttributes_606855;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606870 = newJObject()
  var formData_606871 = newJObject()
  add(formData_606871, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_606870, "Action", newJString(Action))
  add(query_606870, "Version", newJString(Version))
  result = call_606869.call(nil, query_606870, nil, formData_606871, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_606855(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_606856, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_606857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_606839 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBClusterSnapshotAttributes_606841(protocol: Scheme;
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

proc validate_GetDescribeDBClusterSnapshotAttributes_606840(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_606842 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_606842 = validateParameter(valid_606842, JString, required = true,
                                 default = nil)
  if valid_606842 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_606842
  var valid_606843 = query.getOrDefault("Action")
  valid_606843 = validateParameter(valid_606843, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_606843 != nil:
    section.add "Action", valid_606843
  var valid_606844 = query.getOrDefault("Version")
  valid_606844 = validateParameter(valid_606844, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606844 != nil:
    section.add "Version", valid_606844
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606845 = header.getOrDefault("X-Amz-Signature")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Signature", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Content-Sha256", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Date")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Date", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Credential")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Credential", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Security-Token")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Security-Token", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Algorithm")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Algorithm", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-SignedHeaders", valid_606851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606852: Call_GetDescribeDBClusterSnapshotAttributes_606839;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_606852.validator(path, query, header, formData, body)
  let scheme = call_606852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606852.url(scheme.get, call_606852.host, call_606852.base,
                         call_606852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606852, url, valid)

proc call*(call_606853: Call_GetDescribeDBClusterSnapshotAttributes_606839;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606854 = newJObject()
  add(query_606854, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_606854, "Action", newJString(Action))
  add(query_606854, "Version", newJString(Version))
  result = call_606853.call(nil, query_606854, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_606839(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_606840, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_606841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_606895 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBClusterSnapshots_606897(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBClusterSnapshots_606896(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606898 = query.getOrDefault("Action")
  valid_606898 = validateParameter(valid_606898, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_606898 != nil:
    section.add "Action", valid_606898
  var valid_606899 = query.getOrDefault("Version")
  valid_606899 = validateParameter(valid_606899, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606899 != nil:
    section.add "Version", valid_606899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606900 = header.getOrDefault("X-Amz-Signature")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Signature", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Content-Sha256", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Date")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Date", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-Credential")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Credential", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-Security-Token")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Security-Token", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Algorithm")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Algorithm", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-SignedHeaders", valid_606906
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_606907 = formData.getOrDefault("SnapshotType")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "SnapshotType", valid_606907
  var valid_606908 = formData.getOrDefault("MaxRecords")
  valid_606908 = validateParameter(valid_606908, JInt, required = false, default = nil)
  if valid_606908 != nil:
    section.add "MaxRecords", valid_606908
  var valid_606909 = formData.getOrDefault("IncludePublic")
  valid_606909 = validateParameter(valid_606909, JBool, required = false, default = nil)
  if valid_606909 != nil:
    section.add "IncludePublic", valid_606909
  var valid_606910 = formData.getOrDefault("Marker")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "Marker", valid_606910
  var valid_606911 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_606911
  var valid_606912 = formData.getOrDefault("IncludeShared")
  valid_606912 = validateParameter(valid_606912, JBool, required = false, default = nil)
  if valid_606912 != nil:
    section.add "IncludeShared", valid_606912
  var valid_606913 = formData.getOrDefault("Filters")
  valid_606913 = validateParameter(valid_606913, JArray, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "Filters", valid_606913
  var valid_606914 = formData.getOrDefault("DBClusterIdentifier")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "DBClusterIdentifier", valid_606914
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606915: Call_PostDescribeDBClusterSnapshots_606895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_606915.validator(path, query, header, formData, body)
  let scheme = call_606915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606915.url(scheme.get, call_606915.host, call_606915.base,
                         call_606915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606915, url, valid)

proc call*(call_606916: Call_PostDescribeDBClusterSnapshots_606895;
          SnapshotType: string = ""; MaxRecords: int = 0; IncludePublic: bool = false;
          Marker: string = ""; DBClusterSnapshotIdentifier: string = "";
          IncludeShared: bool = false;
          Action: string = "DescribeDBClusterSnapshots"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"; DBClusterIdentifier: string = ""): Recallable =
  ## postDescribeDBClusterSnapshots
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ##   SnapshotType: string
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  var query_606917 = newJObject()
  var formData_606918 = newJObject()
  add(formData_606918, "SnapshotType", newJString(SnapshotType))
  add(formData_606918, "MaxRecords", newJInt(MaxRecords))
  add(formData_606918, "IncludePublic", newJBool(IncludePublic))
  add(formData_606918, "Marker", newJString(Marker))
  add(formData_606918, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_606918, "IncludeShared", newJBool(IncludeShared))
  add(query_606917, "Action", newJString(Action))
  if Filters != nil:
    formData_606918.add "Filters", Filters
  add(query_606917, "Version", newJString(Version))
  add(formData_606918, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_606916.call(nil, query_606917, nil, formData_606918, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_606895(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_606896, base: "/",
    url: url_PostDescribeDBClusterSnapshots_606897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_606872 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBClusterSnapshots_606874(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBClusterSnapshots_606873(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   SnapshotType: JString
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: JString (required)
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_606875 = query.getOrDefault("Marker")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "Marker", valid_606875
  var valid_606876 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_606876
  var valid_606877 = query.getOrDefault("DBClusterIdentifier")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "DBClusterIdentifier", valid_606877
  var valid_606878 = query.getOrDefault("SnapshotType")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "SnapshotType", valid_606878
  var valid_606879 = query.getOrDefault("IncludePublic")
  valid_606879 = validateParameter(valid_606879, JBool, required = false, default = nil)
  if valid_606879 != nil:
    section.add "IncludePublic", valid_606879
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606880 = query.getOrDefault("Action")
  valid_606880 = validateParameter(valid_606880, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_606880 != nil:
    section.add "Action", valid_606880
  var valid_606881 = query.getOrDefault("IncludeShared")
  valid_606881 = validateParameter(valid_606881, JBool, required = false, default = nil)
  if valid_606881 != nil:
    section.add "IncludeShared", valid_606881
  var valid_606882 = query.getOrDefault("Version")
  valid_606882 = validateParameter(valid_606882, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606882 != nil:
    section.add "Version", valid_606882
  var valid_606883 = query.getOrDefault("Filters")
  valid_606883 = validateParameter(valid_606883, JArray, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "Filters", valid_606883
  var valid_606884 = query.getOrDefault("MaxRecords")
  valid_606884 = validateParameter(valid_606884, JInt, required = false, default = nil)
  if valid_606884 != nil:
    section.add "MaxRecords", valid_606884
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606885 = header.getOrDefault("X-Amz-Signature")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Signature", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Content-Sha256", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-Date")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Date", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-Credential")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Credential", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-Security-Token")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Security-Token", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Algorithm")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Algorithm", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-SignedHeaders", valid_606891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606892: Call_GetDescribeDBClusterSnapshots_606872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_606892.validator(path, query, header, formData, body)
  let scheme = call_606892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606892.url(scheme.get, call_606892.host, call_606892.base,
                         call_606892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606892, url, valid)

proc call*(call_606893: Call_GetDescribeDBClusterSnapshots_606872;
          Marker: string = ""; DBClusterSnapshotIdentifier: string = "";
          DBClusterIdentifier: string = ""; SnapshotType: string = "";
          IncludePublic: bool = false;
          Action: string = "DescribeDBClusterSnapshots";
          IncludeShared: bool = false; Version: string = "2014-10-31";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBClusterSnapshots
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   SnapshotType: string
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: string (required)
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_606894 = newJObject()
  add(query_606894, "Marker", newJString(Marker))
  add(query_606894, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_606894, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_606894, "SnapshotType", newJString(SnapshotType))
  add(query_606894, "IncludePublic", newJBool(IncludePublic))
  add(query_606894, "Action", newJString(Action))
  add(query_606894, "IncludeShared", newJBool(IncludeShared))
  add(query_606894, "Version", newJString(Version))
  if Filters != nil:
    query_606894.add "Filters", Filters
  add(query_606894, "MaxRecords", newJInt(MaxRecords))
  result = call_606893.call(nil, query_606894, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_606872(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_606873, base: "/",
    url: url_GetDescribeDBClusterSnapshots_606874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_606938 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBClusters_606940(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBClusters_606939(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606941 = query.getOrDefault("Action")
  valid_606941 = validateParameter(valid_606941, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_606941 != nil:
    section.add "Action", valid_606941
  var valid_606942 = query.getOrDefault("Version")
  valid_606942 = validateParameter(valid_606942, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606942 != nil:
    section.add "Version", valid_606942
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606943 = header.getOrDefault("X-Amz-Signature")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-Signature", valid_606943
  var valid_606944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Content-Sha256", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Date")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Date", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Credential")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Credential", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Security-Token")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Security-Token", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Algorithm")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Algorithm", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-SignedHeaders", valid_606949
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_606950 = formData.getOrDefault("MaxRecords")
  valid_606950 = validateParameter(valid_606950, JInt, required = false, default = nil)
  if valid_606950 != nil:
    section.add "MaxRecords", valid_606950
  var valid_606951 = formData.getOrDefault("Marker")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "Marker", valid_606951
  var valid_606952 = formData.getOrDefault("Filters")
  valid_606952 = validateParameter(valid_606952, JArray, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "Filters", valid_606952
  var valid_606953 = formData.getOrDefault("DBClusterIdentifier")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "DBClusterIdentifier", valid_606953
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606954: Call_PostDescribeDBClusters_606938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_606954.validator(path, query, header, formData, body)
  let scheme = call_606954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606954.url(scheme.get, call_606954.host, call_606954.base,
                         call_606954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606954, url, valid)

proc call*(call_606955: Call_PostDescribeDBClusters_606938; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBClusters";
          Filters: JsonNode = nil; Version: string = "2014-10-31";
          DBClusterIdentifier: string = ""): Recallable =
  ## postDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  var query_606956 = newJObject()
  var formData_606957 = newJObject()
  add(formData_606957, "MaxRecords", newJInt(MaxRecords))
  add(formData_606957, "Marker", newJString(Marker))
  add(query_606956, "Action", newJString(Action))
  if Filters != nil:
    formData_606957.add "Filters", Filters
  add(query_606956, "Version", newJString(Version))
  add(formData_606957, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_606955.call(nil, query_606956, nil, formData_606957, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_606938(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_606939, base: "/",
    url: url_PostDescribeDBClusters_606940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_606919 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBClusters_606921(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBClusters_606920(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_606922 = query.getOrDefault("Marker")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "Marker", valid_606922
  var valid_606923 = query.getOrDefault("DBClusterIdentifier")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "DBClusterIdentifier", valid_606923
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606924 = query.getOrDefault("Action")
  valid_606924 = validateParameter(valid_606924, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_606924 != nil:
    section.add "Action", valid_606924
  var valid_606925 = query.getOrDefault("Version")
  valid_606925 = validateParameter(valid_606925, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606925 != nil:
    section.add "Version", valid_606925
  var valid_606926 = query.getOrDefault("Filters")
  valid_606926 = validateParameter(valid_606926, JArray, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "Filters", valid_606926
  var valid_606927 = query.getOrDefault("MaxRecords")
  valid_606927 = validateParameter(valid_606927, JInt, required = false, default = nil)
  if valid_606927 != nil:
    section.add "MaxRecords", valid_606927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606928 = header.getOrDefault("X-Amz-Signature")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Signature", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-Content-Sha256", valid_606929
  var valid_606930 = header.getOrDefault("X-Amz-Date")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "X-Amz-Date", valid_606930
  var valid_606931 = header.getOrDefault("X-Amz-Credential")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Credential", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Security-Token")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Security-Token", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-Algorithm")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Algorithm", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-SignedHeaders", valid_606934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606935: Call_GetDescribeDBClusters_606919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_606935.validator(path, query, header, formData, body)
  let scheme = call_606935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606935.url(scheme.get, call_606935.host, call_606935.base,
                         call_606935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606935, url, valid)

proc call*(call_606936: Call_GetDescribeDBClusters_606919; Marker: string = "";
          DBClusterIdentifier: string = ""; Action: string = "DescribeDBClusters";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_606937 = newJObject()
  add(query_606937, "Marker", newJString(Marker))
  add(query_606937, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_606937, "Action", newJString(Action))
  add(query_606937, "Version", newJString(Version))
  if Filters != nil:
    query_606937.add "Filters", Filters
  add(query_606937, "MaxRecords", newJInt(MaxRecords))
  result = call_606936.call(nil, query_606937, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_606919(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_606920, base: "/",
    url: url_GetDescribeDBClusters_606921, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_606982 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBEngineVersions_606984(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_606983(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the available DB engines.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606985 = query.getOrDefault("Action")
  valid_606985 = validateParameter(valid_606985, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_606985 != nil:
    section.add "Action", valid_606985
  var valid_606986 = query.getOrDefault("Version")
  valid_606986 = validateParameter(valid_606986, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606986 != nil:
    section.add "Version", valid_606986
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606987 = header.getOrDefault("X-Amz-Signature")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Signature", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-Content-Sha256", valid_606988
  var valid_606989 = header.getOrDefault("X-Amz-Date")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-Date", valid_606989
  var valid_606990 = header.getOrDefault("X-Amz-Credential")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "X-Amz-Credential", valid_606990
  var valid_606991 = header.getOrDefault("X-Amz-Security-Token")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-Security-Token", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-Algorithm")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-Algorithm", valid_606992
  var valid_606993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-SignedHeaders", valid_606993
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultOnly: JBool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: JString
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: JString
  ##         : The database engine to return.
  ##   ListSupportedCharacterSets: JBool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   ListSupportedTimezones: JBool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBParameterGroupFamily: JString
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  section = newJObject()
  var valid_606994 = formData.getOrDefault("DefaultOnly")
  valid_606994 = validateParameter(valid_606994, JBool, required = false, default = nil)
  if valid_606994 != nil:
    section.add "DefaultOnly", valid_606994
  var valid_606995 = formData.getOrDefault("MaxRecords")
  valid_606995 = validateParameter(valid_606995, JInt, required = false, default = nil)
  if valid_606995 != nil:
    section.add "MaxRecords", valid_606995
  var valid_606996 = formData.getOrDefault("EngineVersion")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "EngineVersion", valid_606996
  var valid_606997 = formData.getOrDefault("Marker")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "Marker", valid_606997
  var valid_606998 = formData.getOrDefault("Engine")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "Engine", valid_606998
  var valid_606999 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_606999 = validateParameter(valid_606999, JBool, required = false, default = nil)
  if valid_606999 != nil:
    section.add "ListSupportedCharacterSets", valid_606999
  var valid_607000 = formData.getOrDefault("ListSupportedTimezones")
  valid_607000 = validateParameter(valid_607000, JBool, required = false, default = nil)
  if valid_607000 != nil:
    section.add "ListSupportedTimezones", valid_607000
  var valid_607001 = formData.getOrDefault("Filters")
  valid_607001 = validateParameter(valid_607001, JArray, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "Filters", valid_607001
  var valid_607002 = formData.getOrDefault("DBParameterGroupFamily")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "DBParameterGroupFamily", valid_607002
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607003: Call_PostDescribeDBEngineVersions_606982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_607003.validator(path, query, header, formData, body)
  let scheme = call_607003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607003.url(scheme.get, call_607003.host, call_607003.base,
                         call_607003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607003, url, valid)

proc call*(call_607004: Call_PostDescribeDBEngineVersions_606982;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions";
          ListSupportedTimezones: bool = false; Filters: JsonNode = nil;
          Version: string = "2014-10-31"; DBParameterGroupFamily: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ## Returns a list of the available DB engines.
  ##   DefaultOnly: bool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: string
  ##         : The database engine to return.
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Action: string (required)
  ##   ListSupportedTimezones: bool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  var query_607005 = newJObject()
  var formData_607006 = newJObject()
  add(formData_607006, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_607006, "MaxRecords", newJInt(MaxRecords))
  add(formData_607006, "EngineVersion", newJString(EngineVersion))
  add(formData_607006, "Marker", newJString(Marker))
  add(formData_607006, "Engine", newJString(Engine))
  add(formData_607006, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_607005, "Action", newJString(Action))
  add(formData_607006, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  if Filters != nil:
    formData_607006.add "Filters", Filters
  add(query_607005, "Version", newJString(Version))
  add(formData_607006, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_607004.call(nil, query_607005, nil, formData_607006, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_606982(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_606983, base: "/",
    url: url_PostDescribeDBEngineVersions_606984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_606958 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBEngineVersions_606960(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_606959(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the available DB engines.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ListSupportedTimezones: JBool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   DBParameterGroupFamily: JString
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Engine: JString
  ##         : The database engine to return.
  ##   EngineVersion: JString
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   Action: JString (required)
  ##   ListSupportedCharacterSets: JBool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DefaultOnly: JBool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  section = newJObject()
  var valid_606961 = query.getOrDefault("Marker")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "Marker", valid_606961
  var valid_606962 = query.getOrDefault("ListSupportedTimezones")
  valid_606962 = validateParameter(valid_606962, JBool, required = false, default = nil)
  if valid_606962 != nil:
    section.add "ListSupportedTimezones", valid_606962
  var valid_606963 = query.getOrDefault("DBParameterGroupFamily")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "DBParameterGroupFamily", valid_606963
  var valid_606964 = query.getOrDefault("Engine")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "Engine", valid_606964
  var valid_606965 = query.getOrDefault("EngineVersion")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "EngineVersion", valid_606965
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606966 = query.getOrDefault("Action")
  valid_606966 = validateParameter(valid_606966, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_606966 != nil:
    section.add "Action", valid_606966
  var valid_606967 = query.getOrDefault("ListSupportedCharacterSets")
  valid_606967 = validateParameter(valid_606967, JBool, required = false, default = nil)
  if valid_606967 != nil:
    section.add "ListSupportedCharacterSets", valid_606967
  var valid_606968 = query.getOrDefault("Version")
  valid_606968 = validateParameter(valid_606968, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_606968 != nil:
    section.add "Version", valid_606968
  var valid_606969 = query.getOrDefault("Filters")
  valid_606969 = validateParameter(valid_606969, JArray, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "Filters", valid_606969
  var valid_606970 = query.getOrDefault("MaxRecords")
  valid_606970 = validateParameter(valid_606970, JInt, required = false, default = nil)
  if valid_606970 != nil:
    section.add "MaxRecords", valid_606970
  var valid_606971 = query.getOrDefault("DefaultOnly")
  valid_606971 = validateParameter(valid_606971, JBool, required = false, default = nil)
  if valid_606971 != nil:
    section.add "DefaultOnly", valid_606971
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606972 = header.getOrDefault("X-Amz-Signature")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Signature", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Content-Sha256", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Date")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Date", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-Credential")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Credential", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-Security-Token")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-Security-Token", valid_606976
  var valid_606977 = header.getOrDefault("X-Amz-Algorithm")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "X-Amz-Algorithm", valid_606977
  var valid_606978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "X-Amz-SignedHeaders", valid_606978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606979: Call_GetDescribeDBEngineVersions_606958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_606979.validator(path, query, header, formData, body)
  let scheme = call_606979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606979.url(scheme.get, call_606979.host, call_606979.base,
                         call_606979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606979, url, valid)

proc call*(call_606980: Call_GetDescribeDBEngineVersions_606958;
          Marker: string = ""; ListSupportedTimezones: bool = false;
          DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2014-10-31";
          Filters: JsonNode = nil; MaxRecords: int = 0; DefaultOnly: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ## Returns a list of the available DB engines.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ListSupportedTimezones: bool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Engine: string
  ##         : The database engine to return.
  ##   EngineVersion: string
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   Action: string (required)
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DefaultOnly: bool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  var query_606981 = newJObject()
  add(query_606981, "Marker", newJString(Marker))
  add(query_606981, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_606981, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_606981, "Engine", newJString(Engine))
  add(query_606981, "EngineVersion", newJString(EngineVersion))
  add(query_606981, "Action", newJString(Action))
  add(query_606981, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_606981, "Version", newJString(Version))
  if Filters != nil:
    query_606981.add "Filters", Filters
  add(query_606981, "MaxRecords", newJInt(MaxRecords))
  add(query_606981, "DefaultOnly", newJBool(DefaultOnly))
  result = call_606980.call(nil, query_606981, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_606958(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_606959, base: "/",
    url: url_GetDescribeDBEngineVersions_606960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_607026 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBInstances_607028(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_607027(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607029 = query.getOrDefault("Action")
  valid_607029 = validateParameter(valid_607029, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_607029 != nil:
    section.add "Action", valid_607029
  var valid_607030 = query.getOrDefault("Version")
  valid_607030 = validateParameter(valid_607030, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607030 != nil:
    section.add "Version", valid_607030
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607031 = header.getOrDefault("X-Amz-Signature")
  valid_607031 = validateParameter(valid_607031, JString, required = false,
                                 default = nil)
  if valid_607031 != nil:
    section.add "X-Amz-Signature", valid_607031
  var valid_607032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607032 = validateParameter(valid_607032, JString, required = false,
                                 default = nil)
  if valid_607032 != nil:
    section.add "X-Amz-Content-Sha256", valid_607032
  var valid_607033 = header.getOrDefault("X-Amz-Date")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Date", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-Credential")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Credential", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Security-Token")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Security-Token", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Algorithm")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Algorithm", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-SignedHeaders", valid_607037
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBInstanceIdentifier: JString
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  section = newJObject()
  var valid_607038 = formData.getOrDefault("MaxRecords")
  valid_607038 = validateParameter(valid_607038, JInt, required = false, default = nil)
  if valid_607038 != nil:
    section.add "MaxRecords", valid_607038
  var valid_607039 = formData.getOrDefault("Marker")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "Marker", valid_607039
  var valid_607040 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "DBInstanceIdentifier", valid_607040
  var valid_607041 = formData.getOrDefault("Filters")
  valid_607041 = validateParameter(valid_607041, JArray, required = false,
                                 default = nil)
  if valid_607041 != nil:
    section.add "Filters", valid_607041
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607042: Call_PostDescribeDBInstances_607026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_607042.validator(path, query, header, formData, body)
  let scheme = call_607042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607042.url(scheme.get, call_607042.host, call_607042.base,
                         call_607042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607042, url, valid)

proc call*(call_607043: Call_PostDescribeDBInstances_607026; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   Version: string (required)
  var query_607044 = newJObject()
  var formData_607045 = newJObject()
  add(formData_607045, "MaxRecords", newJInt(MaxRecords))
  add(formData_607045, "Marker", newJString(Marker))
  add(formData_607045, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607044, "Action", newJString(Action))
  if Filters != nil:
    formData_607045.add "Filters", Filters
  add(query_607044, "Version", newJString(Version))
  result = call_607043.call(nil, query_607044, nil, formData_607045, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_607026(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_607027, base: "/",
    url: url_PostDescribeDBInstances_607028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_607007 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBInstances_607009(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_607008(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBInstanceIdentifier: JString
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_607010 = query.getOrDefault("Marker")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "Marker", valid_607010
  var valid_607011 = query.getOrDefault("DBInstanceIdentifier")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "DBInstanceIdentifier", valid_607011
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607012 = query.getOrDefault("Action")
  valid_607012 = validateParameter(valid_607012, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_607012 != nil:
    section.add "Action", valid_607012
  var valid_607013 = query.getOrDefault("Version")
  valid_607013 = validateParameter(valid_607013, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607013 != nil:
    section.add "Version", valid_607013
  var valid_607014 = query.getOrDefault("Filters")
  valid_607014 = validateParameter(valid_607014, JArray, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "Filters", valid_607014
  var valid_607015 = query.getOrDefault("MaxRecords")
  valid_607015 = validateParameter(valid_607015, JInt, required = false, default = nil)
  if valid_607015 != nil:
    section.add "MaxRecords", valid_607015
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607016 = header.getOrDefault("X-Amz-Signature")
  valid_607016 = validateParameter(valid_607016, JString, required = false,
                                 default = nil)
  if valid_607016 != nil:
    section.add "X-Amz-Signature", valid_607016
  var valid_607017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607017 = validateParameter(valid_607017, JString, required = false,
                                 default = nil)
  if valid_607017 != nil:
    section.add "X-Amz-Content-Sha256", valid_607017
  var valid_607018 = header.getOrDefault("X-Amz-Date")
  valid_607018 = validateParameter(valid_607018, JString, required = false,
                                 default = nil)
  if valid_607018 != nil:
    section.add "X-Amz-Date", valid_607018
  var valid_607019 = header.getOrDefault("X-Amz-Credential")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Credential", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Security-Token")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Security-Token", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Algorithm")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Algorithm", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-SignedHeaders", valid_607022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607023: Call_GetDescribeDBInstances_607007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_607023.validator(path, query, header, formData, body)
  let scheme = call_607023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607023.url(scheme.get, call_607023.host, call_607023.base,
                         call_607023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607023, url, valid)

proc call*(call_607024: Call_GetDescribeDBInstances_607007; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_607025 = newJObject()
  add(query_607025, "Marker", newJString(Marker))
  add(query_607025, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607025, "Action", newJString(Action))
  add(query_607025, "Version", newJString(Version))
  if Filters != nil:
    query_607025.add "Filters", Filters
  add(query_607025, "MaxRecords", newJInt(MaxRecords))
  result = call_607024.call(nil, query_607025, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_607007(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_607008, base: "/",
    url: url_GetDescribeDBInstances_607009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_607065 = ref object of OpenApiRestCall_605573
proc url_PostDescribeDBSubnetGroups_607067(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_607066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607068 = query.getOrDefault("Action")
  valid_607068 = validateParameter(valid_607068, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607068 != nil:
    section.add "Action", valid_607068
  var valid_607069 = query.getOrDefault("Version")
  valid_607069 = validateParameter(valid_607069, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607069 != nil:
    section.add "Version", valid_607069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607070 = header.getOrDefault("X-Amz-Signature")
  valid_607070 = validateParameter(valid_607070, JString, required = false,
                                 default = nil)
  if valid_607070 != nil:
    section.add "X-Amz-Signature", valid_607070
  var valid_607071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607071 = validateParameter(valid_607071, JString, required = false,
                                 default = nil)
  if valid_607071 != nil:
    section.add "X-Amz-Content-Sha256", valid_607071
  var valid_607072 = header.getOrDefault("X-Amz-Date")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Date", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Credential")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Credential", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Security-Token")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Security-Token", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Algorithm")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Algorithm", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-SignedHeaders", valid_607076
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBSubnetGroupName: JString
  ##                    : The name of the DB subnet group to return details for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_607077 = formData.getOrDefault("MaxRecords")
  valid_607077 = validateParameter(valid_607077, JInt, required = false, default = nil)
  if valid_607077 != nil:
    section.add "MaxRecords", valid_607077
  var valid_607078 = formData.getOrDefault("Marker")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "Marker", valid_607078
  var valid_607079 = formData.getOrDefault("DBSubnetGroupName")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "DBSubnetGroupName", valid_607079
  var valid_607080 = formData.getOrDefault("Filters")
  valid_607080 = validateParameter(valid_607080, JArray, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "Filters", valid_607080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607081: Call_PostDescribeDBSubnetGroups_607065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_607081.validator(path, query, header, formData, body)
  let scheme = call_607081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607081.url(scheme.get, call_607081.host, call_607081.base,
                         call_607081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607081, url, valid)

proc call*(call_607082: Call_PostDescribeDBSubnetGroups_607065;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBSubnetGroups
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : The name of the DB subnet group to return details for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  var query_607083 = newJObject()
  var formData_607084 = newJObject()
  add(formData_607084, "MaxRecords", newJInt(MaxRecords))
  add(formData_607084, "Marker", newJString(Marker))
  add(query_607083, "Action", newJString(Action))
  add(formData_607084, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_607084.add "Filters", Filters
  add(query_607083, "Version", newJString(Version))
  result = call_607082.call(nil, query_607083, nil, formData_607084, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_607065(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_607066, base: "/",
    url: url_PostDescribeDBSubnetGroups_607067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_607046 = ref object of OpenApiRestCall_605573
proc url_GetDescribeDBSubnetGroups_607048(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_607047(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : The name of the DB subnet group to return details for.
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_607049 = query.getOrDefault("Marker")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "Marker", valid_607049
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607050 = query.getOrDefault("Action")
  valid_607050 = validateParameter(valid_607050, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_607050 != nil:
    section.add "Action", valid_607050
  var valid_607051 = query.getOrDefault("DBSubnetGroupName")
  valid_607051 = validateParameter(valid_607051, JString, required = false,
                                 default = nil)
  if valid_607051 != nil:
    section.add "DBSubnetGroupName", valid_607051
  var valid_607052 = query.getOrDefault("Version")
  valid_607052 = validateParameter(valid_607052, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607052 != nil:
    section.add "Version", valid_607052
  var valid_607053 = query.getOrDefault("Filters")
  valid_607053 = validateParameter(valid_607053, JArray, required = false,
                                 default = nil)
  if valid_607053 != nil:
    section.add "Filters", valid_607053
  var valid_607054 = query.getOrDefault("MaxRecords")
  valid_607054 = validateParameter(valid_607054, JInt, required = false, default = nil)
  if valid_607054 != nil:
    section.add "MaxRecords", valid_607054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607055 = header.getOrDefault("X-Amz-Signature")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-Signature", valid_607055
  var valid_607056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-Content-Sha256", valid_607056
  var valid_607057 = header.getOrDefault("X-Amz-Date")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Date", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Credential")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Credential", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Security-Token")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Security-Token", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Algorithm")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Algorithm", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-SignedHeaders", valid_607061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607062: Call_GetDescribeDBSubnetGroups_607046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_607062.validator(path, query, header, formData, body)
  let scheme = call_607062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607062.url(scheme.get, call_607062.host, call_607062.base,
                         call_607062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607062, url, valid)

proc call*(call_607063: Call_GetDescribeDBSubnetGroups_607046; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : The name of the DB subnet group to return details for.
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_607064 = newJObject()
  add(query_607064, "Marker", newJString(Marker))
  add(query_607064, "Action", newJString(Action))
  add(query_607064, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607064, "Version", newJString(Version))
  if Filters != nil:
    query_607064.add "Filters", Filters
  add(query_607064, "MaxRecords", newJInt(MaxRecords))
  result = call_607063.call(nil, query_607064, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_607046(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_607047, base: "/",
    url: url_GetDescribeDBSubnetGroups_607048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_607104 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEngineDefaultClusterParameters_607106(protocol: Scheme;
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

proc validate_PostDescribeEngineDefaultClusterParameters_607105(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607107 = query.getOrDefault("Action")
  valid_607107 = validateParameter(valid_607107, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_607107 != nil:
    section.add "Action", valid_607107
  var valid_607108 = query.getOrDefault("Version")
  valid_607108 = validateParameter(valid_607108, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607108 != nil:
    section.add "Version", valid_607108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607109 = header.getOrDefault("X-Amz-Signature")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Signature", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Content-Sha256", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Date")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Date", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Credential")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Credential", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-Security-Token")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Security-Token", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Algorithm")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Algorithm", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-SignedHeaders", valid_607115
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  section = newJObject()
  var valid_607116 = formData.getOrDefault("MaxRecords")
  valid_607116 = validateParameter(valid_607116, JInt, required = false, default = nil)
  if valid_607116 != nil:
    section.add "MaxRecords", valid_607116
  var valid_607117 = formData.getOrDefault("Marker")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "Marker", valid_607117
  var valid_607118 = formData.getOrDefault("Filters")
  valid_607118 = validateParameter(valid_607118, JArray, required = false,
                                 default = nil)
  if valid_607118 != nil:
    section.add "Filters", valid_607118
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607119 = formData.getOrDefault("DBParameterGroupFamily")
  valid_607119 = validateParameter(valid_607119, JString, required = true,
                                 default = nil)
  if valid_607119 != nil:
    section.add "DBParameterGroupFamily", valid_607119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607120: Call_PostDescribeEngineDefaultClusterParameters_607104;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_607120.validator(path, query, header, formData, body)
  let scheme = call_607120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607120.url(scheme.get, call_607120.host, call_607120.base,
                         call_607120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607120, url, valid)

proc call*(call_607121: Call_PostDescribeEngineDefaultClusterParameters_607104;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultClusterParameters";
          Filters: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  var query_607122 = newJObject()
  var formData_607123 = newJObject()
  add(formData_607123, "MaxRecords", newJInt(MaxRecords))
  add(formData_607123, "Marker", newJString(Marker))
  add(query_607122, "Action", newJString(Action))
  if Filters != nil:
    formData_607123.add "Filters", Filters
  add(query_607122, "Version", newJString(Version))
  add(formData_607123, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_607121.call(nil, query_607122, nil, formData_607123, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_607104(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_607105,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_607106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_607085 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEngineDefaultClusterParameters_607087(protocol: Scheme;
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

proc validate_GetDescribeEngineDefaultClusterParameters_607086(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_607088 = query.getOrDefault("Marker")
  valid_607088 = validateParameter(valid_607088, JString, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "Marker", valid_607088
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_607089 = query.getOrDefault("DBParameterGroupFamily")
  valid_607089 = validateParameter(valid_607089, JString, required = true,
                                 default = nil)
  if valid_607089 != nil:
    section.add "DBParameterGroupFamily", valid_607089
  var valid_607090 = query.getOrDefault("Action")
  valid_607090 = validateParameter(valid_607090, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_607090 != nil:
    section.add "Action", valid_607090
  var valid_607091 = query.getOrDefault("Version")
  valid_607091 = validateParameter(valid_607091, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607091 != nil:
    section.add "Version", valid_607091
  var valid_607092 = query.getOrDefault("Filters")
  valid_607092 = validateParameter(valid_607092, JArray, required = false,
                                 default = nil)
  if valid_607092 != nil:
    section.add "Filters", valid_607092
  var valid_607093 = query.getOrDefault("MaxRecords")
  valid_607093 = validateParameter(valid_607093, JInt, required = false, default = nil)
  if valid_607093 != nil:
    section.add "MaxRecords", valid_607093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607094 = header.getOrDefault("X-Amz-Signature")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Signature", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Content-Sha256", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Date")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Date", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Credential")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Credential", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-Security-Token")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-Security-Token", valid_607098
  var valid_607099 = header.getOrDefault("X-Amz-Algorithm")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-Algorithm", valid_607099
  var valid_607100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "X-Amz-SignedHeaders", valid_607100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607101: Call_GetDescribeEngineDefaultClusterParameters_607085;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_607101.validator(path, query, header, formData, body)
  let scheme = call_607101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607101.url(scheme.get, call_607101.host, call_607101.base,
                         call_607101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607101, url, valid)

proc call*(call_607102: Call_GetDescribeEngineDefaultClusterParameters_607085;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultClusterParameters";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_607103 = newJObject()
  add(query_607103, "Marker", newJString(Marker))
  add(query_607103, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_607103, "Action", newJString(Action))
  add(query_607103, "Version", newJString(Version))
  if Filters != nil:
    query_607103.add "Filters", Filters
  add(query_607103, "MaxRecords", newJInt(MaxRecords))
  result = call_607102.call(nil, query_607103, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_607085(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_607086,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_607087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_607141 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEventCategories_607143(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_607142(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607144 = query.getOrDefault("Action")
  valid_607144 = validateParameter(valid_607144, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607144 != nil:
    section.add "Action", valid_607144
  var valid_607145 = query.getOrDefault("Version")
  valid_607145 = validateParameter(valid_607145, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607145 != nil:
    section.add "Version", valid_607145
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607146 = header.getOrDefault("X-Amz-Signature")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Signature", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Content-Sha256", valid_607147
  var valid_607148 = header.getOrDefault("X-Amz-Date")
  valid_607148 = validateParameter(valid_607148, JString, required = false,
                                 default = nil)
  if valid_607148 != nil:
    section.add "X-Amz-Date", valid_607148
  var valid_607149 = header.getOrDefault("X-Amz-Credential")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-Credential", valid_607149
  var valid_607150 = header.getOrDefault("X-Amz-Security-Token")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-Security-Token", valid_607150
  var valid_607151 = header.getOrDefault("X-Amz-Algorithm")
  valid_607151 = validateParameter(valid_607151, JString, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "X-Amz-Algorithm", valid_607151
  var valid_607152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "X-Amz-SignedHeaders", valid_607152
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_607153 = formData.getOrDefault("SourceType")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "SourceType", valid_607153
  var valid_607154 = formData.getOrDefault("Filters")
  valid_607154 = validateParameter(valid_607154, JArray, required = false,
                                 default = nil)
  if valid_607154 != nil:
    section.add "Filters", valid_607154
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607155: Call_PostDescribeEventCategories_607141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_607155.validator(path, query, header, formData, body)
  let scheme = call_607155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607155.url(scheme.get, call_607155.host, call_607155.base,
                         call_607155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607155, url, valid)

proc call*(call_607156: Call_PostDescribeEventCategories_607141;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postDescribeEventCategories
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ##   SourceType: string
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  var query_607157 = newJObject()
  var formData_607158 = newJObject()
  add(formData_607158, "SourceType", newJString(SourceType))
  add(query_607157, "Action", newJString(Action))
  if Filters != nil:
    formData_607158.add "Filters", Filters
  add(query_607157, "Version", newJString(Version))
  result = call_607156.call(nil, query_607157, nil, formData_607158, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_607141(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_607142, base: "/",
    url: url_PostDescribeEventCategories_607143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_607124 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEventCategories_607126(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_607125(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_607127 = query.getOrDefault("SourceType")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "SourceType", valid_607127
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607128 = query.getOrDefault("Action")
  valid_607128 = validateParameter(valid_607128, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_607128 != nil:
    section.add "Action", valid_607128
  var valid_607129 = query.getOrDefault("Version")
  valid_607129 = validateParameter(valid_607129, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607129 != nil:
    section.add "Version", valid_607129
  var valid_607130 = query.getOrDefault("Filters")
  valid_607130 = validateParameter(valid_607130, JArray, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "Filters", valid_607130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607131 = header.getOrDefault("X-Amz-Signature")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-Signature", valid_607131
  var valid_607132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "X-Amz-Content-Sha256", valid_607132
  var valid_607133 = header.getOrDefault("X-Amz-Date")
  valid_607133 = validateParameter(valid_607133, JString, required = false,
                                 default = nil)
  if valid_607133 != nil:
    section.add "X-Amz-Date", valid_607133
  var valid_607134 = header.getOrDefault("X-Amz-Credential")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "X-Amz-Credential", valid_607134
  var valid_607135 = header.getOrDefault("X-Amz-Security-Token")
  valid_607135 = validateParameter(valid_607135, JString, required = false,
                                 default = nil)
  if valid_607135 != nil:
    section.add "X-Amz-Security-Token", valid_607135
  var valid_607136 = header.getOrDefault("X-Amz-Algorithm")
  valid_607136 = validateParameter(valid_607136, JString, required = false,
                                 default = nil)
  if valid_607136 != nil:
    section.add "X-Amz-Algorithm", valid_607136
  var valid_607137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607137 = validateParameter(valid_607137, JString, required = false,
                                 default = nil)
  if valid_607137 != nil:
    section.add "X-Amz-SignedHeaders", valid_607137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607138: Call_GetDescribeEventCategories_607124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_607138.validator(path, query, header, formData, body)
  let scheme = call_607138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607138.url(scheme.get, call_607138.host, call_607138.base,
                         call_607138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607138, url, valid)

proc call*(call_607139: Call_GetDescribeEventCategories_607124;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2014-10-31"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ##   SourceType: string
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  var query_607140 = newJObject()
  add(query_607140, "SourceType", newJString(SourceType))
  add(query_607140, "Action", newJString(Action))
  add(query_607140, "Version", newJString(Version))
  if Filters != nil:
    query_607140.add "Filters", Filters
  result = call_607139.call(nil, query_607140, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_607124(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_607125, base: "/",
    url: url_GetDescribeEventCategories_607126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_607183 = ref object of OpenApiRestCall_605573
proc url_PostDescribeEvents_607185(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_607184(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607186 = query.getOrDefault("Action")
  valid_607186 = validateParameter(valid_607186, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607186 != nil:
    section.add "Action", valid_607186
  var valid_607187 = query.getOrDefault("Version")
  valid_607187 = validateParameter(valid_607187, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607187 != nil:
    section.add "Version", valid_607187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607188 = header.getOrDefault("X-Amz-Signature")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Signature", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-Content-Sha256", valid_607189
  var valid_607190 = header.getOrDefault("X-Amz-Date")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "X-Amz-Date", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-Credential")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Credential", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Security-Token")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Security-Token", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-Algorithm")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-Algorithm", valid_607193
  var valid_607194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607194 = validateParameter(valid_607194, JString, required = false,
                                 default = nil)
  if valid_607194 != nil:
    section.add "X-Amz-SignedHeaders", valid_607194
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SourceIdentifier: JString
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   SourceType: JString
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  ##   Duration: JInt
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   EndTime: JString
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   StartTime: JString
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_607195 = formData.getOrDefault("MaxRecords")
  valid_607195 = validateParameter(valid_607195, JInt, required = false, default = nil)
  if valid_607195 != nil:
    section.add "MaxRecords", valid_607195
  var valid_607196 = formData.getOrDefault("Marker")
  valid_607196 = validateParameter(valid_607196, JString, required = false,
                                 default = nil)
  if valid_607196 != nil:
    section.add "Marker", valid_607196
  var valid_607197 = formData.getOrDefault("SourceIdentifier")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "SourceIdentifier", valid_607197
  var valid_607198 = formData.getOrDefault("SourceType")
  valid_607198 = validateParameter(valid_607198, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607198 != nil:
    section.add "SourceType", valid_607198
  var valid_607199 = formData.getOrDefault("Duration")
  valid_607199 = validateParameter(valid_607199, JInt, required = false, default = nil)
  if valid_607199 != nil:
    section.add "Duration", valid_607199
  var valid_607200 = formData.getOrDefault("EndTime")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "EndTime", valid_607200
  var valid_607201 = formData.getOrDefault("StartTime")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "StartTime", valid_607201
  var valid_607202 = formData.getOrDefault("EventCategories")
  valid_607202 = validateParameter(valid_607202, JArray, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "EventCategories", valid_607202
  var valid_607203 = formData.getOrDefault("Filters")
  valid_607203 = validateParameter(valid_607203, JArray, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "Filters", valid_607203
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607204: Call_PostDescribeEvents_607183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_607204.validator(path, query, header, formData, body)
  let scheme = call_607204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607204.url(scheme.get, call_607204.host, call_607204.base,
                         call_607204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607204, url, valid)

proc call*(call_607205: Call_PostDescribeEvents_607183; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeEvents
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SourceIdentifier: string
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   SourceType: string
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  ##   Duration: int
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   EndTime: string
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   StartTime: string
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  var query_607206 = newJObject()
  var formData_607207 = newJObject()
  add(formData_607207, "MaxRecords", newJInt(MaxRecords))
  add(formData_607207, "Marker", newJString(Marker))
  add(formData_607207, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_607207, "SourceType", newJString(SourceType))
  add(formData_607207, "Duration", newJInt(Duration))
  add(formData_607207, "EndTime", newJString(EndTime))
  add(formData_607207, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_607207.add "EventCategories", EventCategories
  add(query_607206, "Action", newJString(Action))
  if Filters != nil:
    formData_607207.add "Filters", Filters
  add(query_607206, "Version", newJString(Version))
  result = call_607205.call(nil, query_607206, nil, formData_607207, nil)

var postDescribeEvents* = Call_PostDescribeEvents_607183(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_607184, base: "/",
    url: url_PostDescribeEvents_607185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_607159 = ref object of OpenApiRestCall_605573
proc url_GetDescribeEvents_607161(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_607160(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SourceType: JString
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  ##   SourceIdentifier: JString
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Action: JString (required)
  ##   StartTime: JString
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Duration: JInt
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   EndTime: JString
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_607162 = query.getOrDefault("Marker")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "Marker", valid_607162
  var valid_607163 = query.getOrDefault("SourceType")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_607163 != nil:
    section.add "SourceType", valid_607163
  var valid_607164 = query.getOrDefault("SourceIdentifier")
  valid_607164 = validateParameter(valid_607164, JString, required = false,
                                 default = nil)
  if valid_607164 != nil:
    section.add "SourceIdentifier", valid_607164
  var valid_607165 = query.getOrDefault("EventCategories")
  valid_607165 = validateParameter(valid_607165, JArray, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "EventCategories", valid_607165
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607166 = query.getOrDefault("Action")
  valid_607166 = validateParameter(valid_607166, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607166 != nil:
    section.add "Action", valid_607166
  var valid_607167 = query.getOrDefault("StartTime")
  valid_607167 = validateParameter(valid_607167, JString, required = false,
                                 default = nil)
  if valid_607167 != nil:
    section.add "StartTime", valid_607167
  var valid_607168 = query.getOrDefault("Duration")
  valid_607168 = validateParameter(valid_607168, JInt, required = false, default = nil)
  if valid_607168 != nil:
    section.add "Duration", valid_607168
  var valid_607169 = query.getOrDefault("EndTime")
  valid_607169 = validateParameter(valid_607169, JString, required = false,
                                 default = nil)
  if valid_607169 != nil:
    section.add "EndTime", valid_607169
  var valid_607170 = query.getOrDefault("Version")
  valid_607170 = validateParameter(valid_607170, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607170 != nil:
    section.add "Version", valid_607170
  var valid_607171 = query.getOrDefault("Filters")
  valid_607171 = validateParameter(valid_607171, JArray, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "Filters", valid_607171
  var valid_607172 = query.getOrDefault("MaxRecords")
  valid_607172 = validateParameter(valid_607172, JInt, required = false, default = nil)
  if valid_607172 != nil:
    section.add "MaxRecords", valid_607172
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607173 = header.getOrDefault("X-Amz-Signature")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "X-Amz-Signature", valid_607173
  var valid_607174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "X-Amz-Content-Sha256", valid_607174
  var valid_607175 = header.getOrDefault("X-Amz-Date")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-Date", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Credential")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Credential", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-Security-Token")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-Security-Token", valid_607177
  var valid_607178 = header.getOrDefault("X-Amz-Algorithm")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "X-Amz-Algorithm", valid_607178
  var valid_607179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607179 = validateParameter(valid_607179, JString, required = false,
                                 default = nil)
  if valid_607179 != nil:
    section.add "X-Amz-SignedHeaders", valid_607179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607180: Call_GetDescribeEvents_607159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_607180.validator(path, query, header, formData, body)
  let scheme = call_607180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607180.url(scheme.get, call_607180.host, call_607180.base,
                         call_607180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607180, url, valid)

proc call*(call_607181: Call_GetDescribeEvents_607159; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEvents
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SourceType: string
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  ##   SourceIdentifier: string
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Action: string (required)
  ##   StartTime: string
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Duration: int
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   EndTime: string
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_607182 = newJObject()
  add(query_607182, "Marker", newJString(Marker))
  add(query_607182, "SourceType", newJString(SourceType))
  add(query_607182, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_607182.add "EventCategories", EventCategories
  add(query_607182, "Action", newJString(Action))
  add(query_607182, "StartTime", newJString(StartTime))
  add(query_607182, "Duration", newJInt(Duration))
  add(query_607182, "EndTime", newJString(EndTime))
  add(query_607182, "Version", newJString(Version))
  if Filters != nil:
    query_607182.add "Filters", Filters
  add(query_607182, "MaxRecords", newJInt(MaxRecords))
  result = call_607181.call(nil, query_607182, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_607159(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_607160,
    base: "/", url: url_GetDescribeEvents_607161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_607231 = ref object of OpenApiRestCall_605573
proc url_PostDescribeOrderableDBInstanceOptions_607233(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_607232(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607234 = query.getOrDefault("Action")
  valid_607234 = validateParameter(valid_607234, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607234 != nil:
    section.add "Action", valid_607234
  var valid_607235 = query.getOrDefault("Version")
  valid_607235 = validateParameter(valid_607235, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607235 != nil:
    section.add "Version", valid_607235
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607236 = header.getOrDefault("X-Amz-Signature")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-Signature", valid_607236
  var valid_607237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607237 = validateParameter(valid_607237, JString, required = false,
                                 default = nil)
  if valid_607237 != nil:
    section.add "X-Amz-Content-Sha256", valid_607237
  var valid_607238 = header.getOrDefault("X-Amz-Date")
  valid_607238 = validateParameter(valid_607238, JString, required = false,
                                 default = nil)
  if valid_607238 != nil:
    section.add "X-Amz-Date", valid_607238
  var valid_607239 = header.getOrDefault("X-Amz-Credential")
  valid_607239 = validateParameter(valid_607239, JString, required = false,
                                 default = nil)
  if valid_607239 != nil:
    section.add "X-Amz-Credential", valid_607239
  var valid_607240 = header.getOrDefault("X-Amz-Security-Token")
  valid_607240 = validateParameter(valid_607240, JString, required = false,
                                 default = nil)
  if valid_607240 != nil:
    section.add "X-Amz-Security-Token", valid_607240
  var valid_607241 = header.getOrDefault("X-Amz-Algorithm")
  valid_607241 = validateParameter(valid_607241, JString, required = false,
                                 default = nil)
  if valid_607241 != nil:
    section.add "X-Amz-Algorithm", valid_607241
  var valid_607242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607242 = validateParameter(valid_607242, JString, required = false,
                                 default = nil)
  if valid_607242 != nil:
    section.add "X-Amz-SignedHeaders", valid_607242
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_607243 = formData.getOrDefault("DBInstanceClass")
  valid_607243 = validateParameter(valid_607243, JString, required = false,
                                 default = nil)
  if valid_607243 != nil:
    section.add "DBInstanceClass", valid_607243
  var valid_607244 = formData.getOrDefault("MaxRecords")
  valid_607244 = validateParameter(valid_607244, JInt, required = false, default = nil)
  if valid_607244 != nil:
    section.add "MaxRecords", valid_607244
  var valid_607245 = formData.getOrDefault("EngineVersion")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "EngineVersion", valid_607245
  var valid_607246 = formData.getOrDefault("Marker")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "Marker", valid_607246
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_607247 = formData.getOrDefault("Engine")
  valid_607247 = validateParameter(valid_607247, JString, required = true,
                                 default = nil)
  if valid_607247 != nil:
    section.add "Engine", valid_607247
  var valid_607248 = formData.getOrDefault("Vpc")
  valid_607248 = validateParameter(valid_607248, JBool, required = false, default = nil)
  if valid_607248 != nil:
    section.add "Vpc", valid_607248
  var valid_607249 = formData.getOrDefault("LicenseModel")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "LicenseModel", valid_607249
  var valid_607250 = formData.getOrDefault("Filters")
  valid_607250 = validateParameter(valid_607250, JArray, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "Filters", valid_607250
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607251: Call_PostDescribeOrderableDBInstanceOptions_607231;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_607251.validator(path, query, header, formData, body)
  let scheme = call_607251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607251.url(scheme.get, call_607251.host, call_607251.base,
                         call_607251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607251, url, valid)

proc call*(call_607252: Call_PostDescribeOrderableDBInstanceOptions_607231;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable DB instance options for the specified engine.
  ##   DBInstanceClass: string
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   Action: string (required)
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  var query_607253 = newJObject()
  var formData_607254 = newJObject()
  add(formData_607254, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607254, "MaxRecords", newJInt(MaxRecords))
  add(formData_607254, "EngineVersion", newJString(EngineVersion))
  add(formData_607254, "Marker", newJString(Marker))
  add(formData_607254, "Engine", newJString(Engine))
  add(formData_607254, "Vpc", newJBool(Vpc))
  add(query_607253, "Action", newJString(Action))
  add(formData_607254, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_607254.add "Filters", Filters
  add(query_607253, "Version", newJString(Version))
  result = call_607252.call(nil, query_607253, nil, formData_607254, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_607231(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_607232, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_607233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_607208 = ref object of OpenApiRestCall_605573
proc url_GetDescribeOrderableDBInstanceOptions_607210(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_607209(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_607211 = query.getOrDefault("Marker")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "Marker", valid_607211
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_607212 = query.getOrDefault("Engine")
  valid_607212 = validateParameter(valid_607212, JString, required = true,
                                 default = nil)
  if valid_607212 != nil:
    section.add "Engine", valid_607212
  var valid_607213 = query.getOrDefault("LicenseModel")
  valid_607213 = validateParameter(valid_607213, JString, required = false,
                                 default = nil)
  if valid_607213 != nil:
    section.add "LicenseModel", valid_607213
  var valid_607214 = query.getOrDefault("Vpc")
  valid_607214 = validateParameter(valid_607214, JBool, required = false, default = nil)
  if valid_607214 != nil:
    section.add "Vpc", valid_607214
  var valid_607215 = query.getOrDefault("EngineVersion")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "EngineVersion", valid_607215
  var valid_607216 = query.getOrDefault("Action")
  valid_607216 = validateParameter(valid_607216, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_607216 != nil:
    section.add "Action", valid_607216
  var valid_607217 = query.getOrDefault("Version")
  valid_607217 = validateParameter(valid_607217, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607217 != nil:
    section.add "Version", valid_607217
  var valid_607218 = query.getOrDefault("DBInstanceClass")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "DBInstanceClass", valid_607218
  var valid_607219 = query.getOrDefault("Filters")
  valid_607219 = validateParameter(valid_607219, JArray, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "Filters", valid_607219
  var valid_607220 = query.getOrDefault("MaxRecords")
  valid_607220 = validateParameter(valid_607220, JInt, required = false, default = nil)
  if valid_607220 != nil:
    section.add "MaxRecords", valid_607220
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607221 = header.getOrDefault("X-Amz-Signature")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-Signature", valid_607221
  var valid_607222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "X-Amz-Content-Sha256", valid_607222
  var valid_607223 = header.getOrDefault("X-Amz-Date")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-Date", valid_607223
  var valid_607224 = header.getOrDefault("X-Amz-Credential")
  valid_607224 = validateParameter(valid_607224, JString, required = false,
                                 default = nil)
  if valid_607224 != nil:
    section.add "X-Amz-Credential", valid_607224
  var valid_607225 = header.getOrDefault("X-Amz-Security-Token")
  valid_607225 = validateParameter(valid_607225, JString, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "X-Amz-Security-Token", valid_607225
  var valid_607226 = header.getOrDefault("X-Amz-Algorithm")
  valid_607226 = validateParameter(valid_607226, JString, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "X-Amz-Algorithm", valid_607226
  var valid_607227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607227 = validateParameter(valid_607227, JString, required = false,
                                 default = nil)
  if valid_607227 != nil:
    section.add "X-Amz-SignedHeaders", valid_607227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607228: Call_GetDescribeOrderableDBInstanceOptions_607208;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_607228.validator(path, query, header, formData, body)
  let scheme = call_607228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607228.url(scheme.get, call_607228.host, call_607228.base,
                         call_607228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607228, url, valid)

proc call*(call_607229: Call_GetDescribeOrderableDBInstanceOptions_607208;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2014-10-31"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable DB instance options for the specified engine.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_607230 = newJObject()
  add(query_607230, "Marker", newJString(Marker))
  add(query_607230, "Engine", newJString(Engine))
  add(query_607230, "LicenseModel", newJString(LicenseModel))
  add(query_607230, "Vpc", newJBool(Vpc))
  add(query_607230, "EngineVersion", newJString(EngineVersion))
  add(query_607230, "Action", newJString(Action))
  add(query_607230, "Version", newJString(Version))
  add(query_607230, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_607230.add "Filters", Filters
  add(query_607230, "MaxRecords", newJInt(MaxRecords))
  result = call_607229.call(nil, query_607230, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_607208(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_607209, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_607210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_607274 = ref object of OpenApiRestCall_605573
proc url_PostDescribePendingMaintenanceActions_607276(protocol: Scheme;
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

proc validate_PostDescribePendingMaintenanceActions_607275(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607277 = query.getOrDefault("Action")
  valid_607277 = validateParameter(valid_607277, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_607277 != nil:
    section.add "Action", valid_607277
  var valid_607278 = query.getOrDefault("Version")
  valid_607278 = validateParameter(valid_607278, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607278 != nil:
    section.add "Version", valid_607278
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607279 = header.getOrDefault("X-Amz-Signature")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Signature", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Content-Sha256", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Date")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Date", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Credential")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Credential", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-Security-Token")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-Security-Token", valid_607283
  var valid_607284 = header.getOrDefault("X-Amz-Algorithm")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "X-Amz-Algorithm", valid_607284
  var valid_607285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = nil)
  if valid_607285 != nil:
    section.add "X-Amz-SignedHeaders", valid_607285
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  section = newJObject()
  var valid_607286 = formData.getOrDefault("MaxRecords")
  valid_607286 = validateParameter(valid_607286, JInt, required = false, default = nil)
  if valid_607286 != nil:
    section.add "MaxRecords", valid_607286
  var valid_607287 = formData.getOrDefault("Marker")
  valid_607287 = validateParameter(valid_607287, JString, required = false,
                                 default = nil)
  if valid_607287 != nil:
    section.add "Marker", valid_607287
  var valid_607288 = formData.getOrDefault("ResourceIdentifier")
  valid_607288 = validateParameter(valid_607288, JString, required = false,
                                 default = nil)
  if valid_607288 != nil:
    section.add "ResourceIdentifier", valid_607288
  var valid_607289 = formData.getOrDefault("Filters")
  valid_607289 = validateParameter(valid_607289, JArray, required = false,
                                 default = nil)
  if valid_607289 != nil:
    section.add "Filters", valid_607289
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607290: Call_PostDescribePendingMaintenanceActions_607274;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_607290.validator(path, query, header, formData, body)
  let scheme = call_607290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607290.url(scheme.get, call_607290.host, call_607290.base,
                         call_607290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607290, url, valid)

proc call*(call_607291: Call_PostDescribePendingMaintenanceActions_607274;
          MaxRecords: int = 0; Marker: string = ""; ResourceIdentifier: string = "";
          Action: string = "DescribePendingMaintenanceActions";
          Filters: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   Version: string (required)
  var query_607292 = newJObject()
  var formData_607293 = newJObject()
  add(formData_607293, "MaxRecords", newJInt(MaxRecords))
  add(formData_607293, "Marker", newJString(Marker))
  add(formData_607293, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_607292, "Action", newJString(Action))
  if Filters != nil:
    formData_607293.add "Filters", Filters
  add(query_607292, "Version", newJString(Version))
  result = call_607291.call(nil, query_607292, nil, formData_607293, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_607274(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_607275, base: "/",
    url: url_PostDescribePendingMaintenanceActions_607276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_607255 = ref object of OpenApiRestCall_605573
proc url_GetDescribePendingMaintenanceActions_607257(protocol: Scheme;
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

proc validate_GetDescribePendingMaintenanceActions_607256(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_607258 = query.getOrDefault("ResourceIdentifier")
  valid_607258 = validateParameter(valid_607258, JString, required = false,
                                 default = nil)
  if valid_607258 != nil:
    section.add "ResourceIdentifier", valid_607258
  var valid_607259 = query.getOrDefault("Marker")
  valid_607259 = validateParameter(valid_607259, JString, required = false,
                                 default = nil)
  if valid_607259 != nil:
    section.add "Marker", valid_607259
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607260 = query.getOrDefault("Action")
  valid_607260 = validateParameter(valid_607260, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_607260 != nil:
    section.add "Action", valid_607260
  var valid_607261 = query.getOrDefault("Version")
  valid_607261 = validateParameter(valid_607261, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607261 != nil:
    section.add "Version", valid_607261
  var valid_607262 = query.getOrDefault("Filters")
  valid_607262 = validateParameter(valid_607262, JArray, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "Filters", valid_607262
  var valid_607263 = query.getOrDefault("MaxRecords")
  valid_607263 = validateParameter(valid_607263, JInt, required = false, default = nil)
  if valid_607263 != nil:
    section.add "MaxRecords", valid_607263
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607264 = header.getOrDefault("X-Amz-Signature")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Signature", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Content-Sha256", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-Date")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Date", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-Credential")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Credential", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-Security-Token")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Security-Token", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-Algorithm")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-Algorithm", valid_607269
  var valid_607270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "X-Amz-SignedHeaders", valid_607270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607271: Call_GetDescribePendingMaintenanceActions_607255;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_607271.validator(path, query, header, formData, body)
  let scheme = call_607271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607271.url(scheme.get, call_607271.host, call_607271.base,
                         call_607271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607271, url, valid)

proc call*(call_607272: Call_GetDescribePendingMaintenanceActions_607255;
          ResourceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribePendingMaintenanceActions";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_607273 = newJObject()
  add(query_607273, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_607273, "Marker", newJString(Marker))
  add(query_607273, "Action", newJString(Action))
  add(query_607273, "Version", newJString(Version))
  if Filters != nil:
    query_607273.add "Filters", Filters
  add(query_607273, "MaxRecords", newJInt(MaxRecords))
  result = call_607272.call(nil, query_607273, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_607255(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_607256, base: "/",
    url: url_GetDescribePendingMaintenanceActions_607257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_607311 = ref object of OpenApiRestCall_605573
proc url_PostFailoverDBCluster_607313(protocol: Scheme; host: string; base: string;
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

proc validate_PostFailoverDBCluster_607312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607314 = query.getOrDefault("Action")
  valid_607314 = validateParameter(valid_607314, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_607314 != nil:
    section.add "Action", valid_607314
  var valid_607315 = query.getOrDefault("Version")
  valid_607315 = validateParameter(valid_607315, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607315 != nil:
    section.add "Version", valid_607315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607316 = header.getOrDefault("X-Amz-Signature")
  valid_607316 = validateParameter(valid_607316, JString, required = false,
                                 default = nil)
  if valid_607316 != nil:
    section.add "X-Amz-Signature", valid_607316
  var valid_607317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607317 = validateParameter(valid_607317, JString, required = false,
                                 default = nil)
  if valid_607317 != nil:
    section.add "X-Amz-Content-Sha256", valid_607317
  var valid_607318 = header.getOrDefault("X-Amz-Date")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "X-Amz-Date", valid_607318
  var valid_607319 = header.getOrDefault("X-Amz-Credential")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = nil)
  if valid_607319 != nil:
    section.add "X-Amz-Credential", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Security-Token")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Security-Token", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Algorithm")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Algorithm", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-SignedHeaders", valid_607322
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_607323 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "TargetDBInstanceIdentifier", valid_607323
  var valid_607324 = formData.getOrDefault("DBClusterIdentifier")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "DBClusterIdentifier", valid_607324
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607325: Call_PostFailoverDBCluster_607311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_607325.validator(path, query, header, formData, body)
  let scheme = call_607325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607325.url(scheme.get, call_607325.host, call_607325.base,
                         call_607325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607325, url, valid)

proc call*(call_607326: Call_PostFailoverDBCluster_607311;
          Action: string = "FailoverDBCluster";
          TargetDBInstanceIdentifier: string = ""; Version: string = "2014-10-31";
          DBClusterIdentifier: string = ""): Recallable =
  ## postFailoverDBCluster
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ##   Action: string (required)
  ##   TargetDBInstanceIdentifier: string
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  var query_607327 = newJObject()
  var formData_607328 = newJObject()
  add(query_607327, "Action", newJString(Action))
  add(formData_607328, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_607327, "Version", newJString(Version))
  add(formData_607328, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_607326.call(nil, query_607327, nil, formData_607328, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_607311(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_607312, base: "/",
    url: url_PostFailoverDBCluster_607313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_607294 = ref object of OpenApiRestCall_605573
proc url_GetFailoverDBCluster_607296(protocol: Scheme; host: string; base: string;
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

proc validate_GetFailoverDBCluster_607295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607297 = query.getOrDefault("DBClusterIdentifier")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "DBClusterIdentifier", valid_607297
  var valid_607298 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "TargetDBInstanceIdentifier", valid_607298
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607299 = query.getOrDefault("Action")
  valid_607299 = validateParameter(valid_607299, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_607299 != nil:
    section.add "Action", valid_607299
  var valid_607300 = query.getOrDefault("Version")
  valid_607300 = validateParameter(valid_607300, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607300 != nil:
    section.add "Version", valid_607300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607301 = header.getOrDefault("X-Amz-Signature")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-Signature", valid_607301
  var valid_607302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "X-Amz-Content-Sha256", valid_607302
  var valid_607303 = header.getOrDefault("X-Amz-Date")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "X-Amz-Date", valid_607303
  var valid_607304 = header.getOrDefault("X-Amz-Credential")
  valid_607304 = validateParameter(valid_607304, JString, required = false,
                                 default = nil)
  if valid_607304 != nil:
    section.add "X-Amz-Credential", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-Security-Token")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Security-Token", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Algorithm")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Algorithm", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-SignedHeaders", valid_607307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607308: Call_GetFailoverDBCluster_607294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_607308.validator(path, query, header, formData, body)
  let scheme = call_607308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607308.url(scheme.get, call_607308.host, call_607308.base,
                         call_607308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607308, url, valid)

proc call*(call_607309: Call_GetFailoverDBCluster_607294;
          DBClusterIdentifier: string = ""; TargetDBInstanceIdentifier: string = "";
          Action: string = "FailoverDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getFailoverDBCluster
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   TargetDBInstanceIdentifier: string
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607310 = newJObject()
  add(query_607310, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_607310, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_607310, "Action", newJString(Action))
  add(query_607310, "Version", newJString(Version))
  result = call_607309.call(nil, query_607310, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_607294(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_607295, base: "/",
    url: url_GetFailoverDBCluster_607296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_607346 = ref object of OpenApiRestCall_605573
proc url_PostListTagsForResource_607348(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_607347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607349 = query.getOrDefault("Action")
  valid_607349 = validateParameter(valid_607349, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607349 != nil:
    section.add "Action", valid_607349
  var valid_607350 = query.getOrDefault("Version")
  valid_607350 = validateParameter(valid_607350, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_607358 = formData.getOrDefault("Filters")
  valid_607358 = validateParameter(valid_607358, JArray, required = false,
                                 default = nil)
  if valid_607358 != nil:
    section.add "Filters", valid_607358
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_607359 = formData.getOrDefault("ResourceName")
  valid_607359 = validateParameter(valid_607359, JString, required = true,
                                 default = nil)
  if valid_607359 != nil:
    section.add "ResourceName", valid_607359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607360: Call_PostListTagsForResource_607346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_607360.validator(path, query, header, formData, body)
  let scheme = call_607360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607360.url(scheme.get, call_607360.host, call_607360.base,
                         call_607360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607360, url, valid)

proc call*(call_607361: Call_PostListTagsForResource_607346; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postListTagsForResource
  ## Lists all tags on an Amazon DocumentDB resource.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  var query_607362 = newJObject()
  var formData_607363 = newJObject()
  add(query_607362, "Action", newJString(Action))
  if Filters != nil:
    formData_607363.add "Filters", Filters
  add(query_607362, "Version", newJString(Version))
  add(formData_607363, "ResourceName", newJString(ResourceName))
  result = call_607361.call(nil, query_607362, nil, formData_607363, nil)

var postListTagsForResource* = Call_PostListTagsForResource_607346(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_607347, base: "/",
    url: url_PostListTagsForResource_607348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_607329 = ref object of OpenApiRestCall_605573
proc url_GetListTagsForResource_607331(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_607330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_607332 = query.getOrDefault("ResourceName")
  valid_607332 = validateParameter(valid_607332, JString, required = true,
                                 default = nil)
  if valid_607332 != nil:
    section.add "ResourceName", valid_607332
  var valid_607333 = query.getOrDefault("Action")
  valid_607333 = validateParameter(valid_607333, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607333 != nil:
    section.add "Action", valid_607333
  var valid_607334 = query.getOrDefault("Version")
  valid_607334 = validateParameter(valid_607334, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607334 != nil:
    section.add "Version", valid_607334
  var valid_607335 = query.getOrDefault("Filters")
  valid_607335 = validateParameter(valid_607335, JArray, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "Filters", valid_607335
  result.add "query", section
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

proc call*(call_607343: Call_GetListTagsForResource_607329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_607343.validator(path, query, header, formData, body)
  let scheme = call_607343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607343.url(scheme.get, call_607343.host, call_607343.base,
                         call_607343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607343, url, valid)

proc call*(call_607344: Call_GetListTagsForResource_607329; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2014-10-31";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ## Lists all tags on an Amazon DocumentDB resource.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  var query_607345 = newJObject()
  add(query_607345, "ResourceName", newJString(ResourceName))
  add(query_607345, "Action", newJString(Action))
  add(query_607345, "Version", newJString(Version))
  if Filters != nil:
    query_607345.add "Filters", Filters
  result = call_607344.call(nil, query_607345, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_607329(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_607330, base: "/",
    url: url_GetListTagsForResource_607331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_607393 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBCluster_607395(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBCluster_607394(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607396 = query.getOrDefault("Action")
  valid_607396 = validateParameter(valid_607396, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_607396 != nil:
    section.add "Action", valid_607396
  var valid_607397 = query.getOrDefault("Version")
  valid_607397 = validateParameter(valid_607397, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607397 != nil:
    section.add "Version", valid_607397
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607398 = header.getOrDefault("X-Amz-Signature")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Signature", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Content-Sha256", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Date")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Date", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-Credential")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-Credential", valid_607401
  var valid_607402 = header.getOrDefault("X-Amz-Security-Token")
  valid_607402 = validateParameter(valid_607402, JString, required = false,
                                 default = nil)
  if valid_607402 != nil:
    section.add "X-Amz-Security-Token", valid_607402
  var valid_607403 = header.getOrDefault("X-Amz-Algorithm")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "X-Amz-Algorithm", valid_607403
  var valid_607404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-SignedHeaders", valid_607404
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  section = newJObject()
  var valid_607405 = formData.getOrDefault("Port")
  valid_607405 = validateParameter(valid_607405, JInt, required = false, default = nil)
  if valid_607405 != nil:
    section.add "Port", valid_607405
  var valid_607406 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_607406 = validateParameter(valid_607406, JString, required = false,
                                 default = nil)
  if valid_607406 != nil:
    section.add "PreferredMaintenanceWindow", valid_607406
  var valid_607407 = formData.getOrDefault("PreferredBackupWindow")
  valid_607407 = validateParameter(valid_607407, JString, required = false,
                                 default = nil)
  if valid_607407 != nil:
    section.add "PreferredBackupWindow", valid_607407
  var valid_607408 = formData.getOrDefault("MasterUserPassword")
  valid_607408 = validateParameter(valid_607408, JString, required = false,
                                 default = nil)
  if valid_607408 != nil:
    section.add "MasterUserPassword", valid_607408
  var valid_607409 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_607409 = validateParameter(valid_607409, JArray, required = false,
                                 default = nil)
  if valid_607409 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_607409
  var valid_607410 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_607410 = validateParameter(valid_607410, JArray, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_607410
  var valid_607411 = formData.getOrDefault("EngineVersion")
  valid_607411 = validateParameter(valid_607411, JString, required = false,
                                 default = nil)
  if valid_607411 != nil:
    section.add "EngineVersion", valid_607411
  var valid_607412 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_607412 = validateParameter(valid_607412, JArray, required = false,
                                 default = nil)
  if valid_607412 != nil:
    section.add "VpcSecurityGroupIds", valid_607412
  var valid_607413 = formData.getOrDefault("BackupRetentionPeriod")
  valid_607413 = validateParameter(valid_607413, JInt, required = false, default = nil)
  if valid_607413 != nil:
    section.add "BackupRetentionPeriod", valid_607413
  var valid_607414 = formData.getOrDefault("ApplyImmediately")
  valid_607414 = validateParameter(valid_607414, JBool, required = false, default = nil)
  if valid_607414 != nil:
    section.add "ApplyImmediately", valid_607414
  var valid_607415 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_607415 = validateParameter(valid_607415, JString, required = false,
                                 default = nil)
  if valid_607415 != nil:
    section.add "DBClusterParameterGroupName", valid_607415
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_607416 = formData.getOrDefault("DBClusterIdentifier")
  valid_607416 = validateParameter(valid_607416, JString, required = true,
                                 default = nil)
  if valid_607416 != nil:
    section.add "DBClusterIdentifier", valid_607416
  var valid_607417 = formData.getOrDefault("DeletionProtection")
  valid_607417 = validateParameter(valid_607417, JBool, required = false, default = nil)
  if valid_607417 != nil:
    section.add "DeletionProtection", valid_607417
  var valid_607418 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "NewDBClusterIdentifier", valid_607418
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607419: Call_PostModifyDBCluster_607393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_607419.validator(path, query, header, formData, body)
  let scheme = call_607419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607419.url(scheme.get, call_607419.host, call_607419.base,
                         call_607419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607419, url, valid)

proc call*(call_607420: Call_PostModifyDBCluster_607393;
          DBClusterIdentifier: string; Port: int = 0;
          PreferredMaintenanceWindow: string = "";
          PreferredBackupWindow: string = ""; MasterUserPassword: string = "";
          CloudwatchLogsExportConfigurationDisableLogTypes: JsonNode = nil;
          CloudwatchLogsExportConfigurationEnableLogTypes: JsonNode = nil;
          EngineVersion: string = ""; VpcSecurityGroupIds: JsonNode = nil;
          BackupRetentionPeriod: int = 0; ApplyImmediately: bool = false;
          Action: string = "ModifyDBCluster";
          DBClusterParameterGroupName: string = ""; Version: string = "2014-10-31";
          DeletionProtection: bool = false; NewDBClusterIdentifier: string = ""): Recallable =
  ## postModifyDBCluster
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   Port: int
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  var query_607421 = newJObject()
  var formData_607422 = newJObject()
  add(formData_607422, "Port", newJInt(Port))
  add(formData_607422, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_607422, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_607422, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_607422.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_607422.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_607422, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_607422.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_607422, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_607422, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_607421, "Action", newJString(Action))
  add(formData_607422, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_607421, "Version", newJString(Version))
  add(formData_607422, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_607422, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_607422, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  result = call_607420.call(nil, query_607421, nil, formData_607422, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_607393(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_607394, base: "/",
    url: url_PostModifyDBCluster_607395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_607364 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBCluster_607366(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBCluster_607365(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Action: JString (required)
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   Port: JInt
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   Version: JString (required)
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  var valid_607367 = query.getOrDefault("DeletionProtection")
  valid_607367 = validateParameter(valid_607367, JBool, required = false, default = nil)
  if valid_607367 != nil:
    section.add "DeletionProtection", valid_607367
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_607368 = query.getOrDefault("DBClusterIdentifier")
  valid_607368 = validateParameter(valid_607368, JString, required = true,
                                 default = nil)
  if valid_607368 != nil:
    section.add "DBClusterIdentifier", valid_607368
  var valid_607369 = query.getOrDefault("DBClusterParameterGroupName")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "DBClusterParameterGroupName", valid_607369
  var valid_607370 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_607370 = validateParameter(valid_607370, JArray, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_607370
  var valid_607371 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_607371 = validateParameter(valid_607371, JArray, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_607371
  var valid_607372 = query.getOrDefault("BackupRetentionPeriod")
  valid_607372 = validateParameter(valid_607372, JInt, required = false, default = nil)
  if valid_607372 != nil:
    section.add "BackupRetentionPeriod", valid_607372
  var valid_607373 = query.getOrDefault("EngineVersion")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "EngineVersion", valid_607373
  var valid_607374 = query.getOrDefault("Action")
  valid_607374 = validateParameter(valid_607374, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_607374 != nil:
    section.add "Action", valid_607374
  var valid_607375 = query.getOrDefault("ApplyImmediately")
  valid_607375 = validateParameter(valid_607375, JBool, required = false, default = nil)
  if valid_607375 != nil:
    section.add "ApplyImmediately", valid_607375
  var valid_607376 = query.getOrDefault("NewDBClusterIdentifier")
  valid_607376 = validateParameter(valid_607376, JString, required = false,
                                 default = nil)
  if valid_607376 != nil:
    section.add "NewDBClusterIdentifier", valid_607376
  var valid_607377 = query.getOrDefault("Port")
  valid_607377 = validateParameter(valid_607377, JInt, required = false, default = nil)
  if valid_607377 != nil:
    section.add "Port", valid_607377
  var valid_607378 = query.getOrDefault("VpcSecurityGroupIds")
  valid_607378 = validateParameter(valid_607378, JArray, required = false,
                                 default = nil)
  if valid_607378 != nil:
    section.add "VpcSecurityGroupIds", valid_607378
  var valid_607379 = query.getOrDefault("MasterUserPassword")
  valid_607379 = validateParameter(valid_607379, JString, required = false,
                                 default = nil)
  if valid_607379 != nil:
    section.add "MasterUserPassword", valid_607379
  var valid_607380 = query.getOrDefault("Version")
  valid_607380 = validateParameter(valid_607380, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607380 != nil:
    section.add "Version", valid_607380
  var valid_607381 = query.getOrDefault("PreferredBackupWindow")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "PreferredBackupWindow", valid_607381
  var valid_607382 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "PreferredMaintenanceWindow", valid_607382
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607383 = header.getOrDefault("X-Amz-Signature")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Signature", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Content-Sha256", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Date")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Date", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-Credential")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-Credential", valid_607386
  var valid_607387 = header.getOrDefault("X-Amz-Security-Token")
  valid_607387 = validateParameter(valid_607387, JString, required = false,
                                 default = nil)
  if valid_607387 != nil:
    section.add "X-Amz-Security-Token", valid_607387
  var valid_607388 = header.getOrDefault("X-Amz-Algorithm")
  valid_607388 = validateParameter(valid_607388, JString, required = false,
                                 default = nil)
  if valid_607388 != nil:
    section.add "X-Amz-Algorithm", valid_607388
  var valid_607389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-SignedHeaders", valid_607389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607390: Call_GetModifyDBCluster_607364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_607390.validator(path, query, header, formData, body)
  let scheme = call_607390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607390.url(scheme.get, call_607390.host, call_607390.base,
                         call_607390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607390, url, valid)

proc call*(call_607391: Call_GetModifyDBCluster_607364;
          DBClusterIdentifier: string; DeletionProtection: bool = false;
          DBClusterParameterGroupName: string = "";
          CloudwatchLogsExportConfigurationEnableLogTypes: JsonNode = nil;
          CloudwatchLogsExportConfigurationDisableLogTypes: JsonNode = nil;
          BackupRetentionPeriod: int = 0; EngineVersion: string = "";
          Action: string = "ModifyDBCluster"; ApplyImmediately: bool = false;
          NewDBClusterIdentifier: string = ""; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; MasterUserPassword: string = "";
          Version: string = "2014-10-31"; PreferredBackupWindow: string = "";
          PreferredMaintenanceWindow: string = ""): Recallable =
  ## getModifyDBCluster
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   Port: int
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_607392 = newJObject()
  add(query_607392, "DeletionProtection", newJBool(DeletionProtection))
  add(query_607392, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_607392, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_607392.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_607392.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_607392, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_607392, "EngineVersion", newJString(EngineVersion))
  add(query_607392, "Action", newJString(Action))
  add(query_607392, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_607392, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_607392, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_607392.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_607392, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_607392, "Version", newJString(Version))
  add(query_607392, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_607392, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_607391.call(nil, query_607392, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_607364(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_607365,
    base: "/", url: url_GetModifyDBCluster_607366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_607440 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBClusterParameterGroup_607442(protocol: Scheme; host: string;
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

proc validate_PostModifyDBClusterParameterGroup_607441(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607443 = query.getOrDefault("Action")
  valid_607443 = validateParameter(valid_607443, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_607443 != nil:
    section.add "Action", valid_607443
  var valid_607444 = query.getOrDefault("Version")
  valid_607444 = validateParameter(valid_607444, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607444 != nil:
    section.add "Version", valid_607444
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607445 = header.getOrDefault("X-Amz-Signature")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "X-Amz-Signature", valid_607445
  var valid_607446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607446 = validateParameter(valid_607446, JString, required = false,
                                 default = nil)
  if valid_607446 != nil:
    section.add "X-Amz-Content-Sha256", valid_607446
  var valid_607447 = header.getOrDefault("X-Amz-Date")
  valid_607447 = validateParameter(valid_607447, JString, required = false,
                                 default = nil)
  if valid_607447 != nil:
    section.add "X-Amz-Date", valid_607447
  var valid_607448 = header.getOrDefault("X-Amz-Credential")
  valid_607448 = validateParameter(valid_607448, JString, required = false,
                                 default = nil)
  if valid_607448 != nil:
    section.add "X-Amz-Credential", valid_607448
  var valid_607449 = header.getOrDefault("X-Amz-Security-Token")
  valid_607449 = validateParameter(valid_607449, JString, required = false,
                                 default = nil)
  if valid_607449 != nil:
    section.add "X-Amz-Security-Token", valid_607449
  var valid_607450 = header.getOrDefault("X-Amz-Algorithm")
  valid_607450 = validateParameter(valid_607450, JString, required = false,
                                 default = nil)
  if valid_607450 != nil:
    section.add "X-Amz-Algorithm", valid_607450
  var valid_607451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607451 = validateParameter(valid_607451, JString, required = false,
                                 default = nil)
  if valid_607451 != nil:
    section.add "X-Amz-SignedHeaders", valid_607451
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_607452 = formData.getOrDefault("Parameters")
  valid_607452 = validateParameter(valid_607452, JArray, required = true, default = nil)
  if valid_607452 != nil:
    section.add "Parameters", valid_607452
  var valid_607453 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_607453 = validateParameter(valid_607453, JString, required = true,
                                 default = nil)
  if valid_607453 != nil:
    section.add "DBClusterParameterGroupName", valid_607453
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607454: Call_PostModifyDBClusterParameterGroup_607440;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_607454.validator(path, query, header, formData, body)
  let scheme = call_607454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607454.url(scheme.get, call_607454.host, call_607454.base,
                         call_607454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607454, url, valid)

proc call*(call_607455: Call_PostModifyDBClusterParameterGroup_607440;
          Parameters: JsonNode; DBClusterParameterGroupName: string;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to modify.
  ##   Version: string (required)
  var query_607456 = newJObject()
  var formData_607457 = newJObject()
  add(query_607456, "Action", newJString(Action))
  if Parameters != nil:
    formData_607457.add "Parameters", Parameters
  add(formData_607457, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_607456, "Version", newJString(Version))
  result = call_607455.call(nil, query_607456, nil, formData_607457, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_607440(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_607441, base: "/",
    url: url_PostModifyDBClusterParameterGroup_607442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_607423 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBClusterParameterGroup_607425(protocol: Scheme; host: string;
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

proc validate_GetModifyDBClusterParameterGroup_607424(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Parameters` field"
  var valid_607426 = query.getOrDefault("Parameters")
  valid_607426 = validateParameter(valid_607426, JArray, required = true, default = nil)
  if valid_607426 != nil:
    section.add "Parameters", valid_607426
  var valid_607427 = query.getOrDefault("DBClusterParameterGroupName")
  valid_607427 = validateParameter(valid_607427, JString, required = true,
                                 default = nil)
  if valid_607427 != nil:
    section.add "DBClusterParameterGroupName", valid_607427
  var valid_607428 = query.getOrDefault("Action")
  valid_607428 = validateParameter(valid_607428, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_607428 != nil:
    section.add "Action", valid_607428
  var valid_607429 = query.getOrDefault("Version")
  valid_607429 = validateParameter(valid_607429, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607429 != nil:
    section.add "Version", valid_607429
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607430 = header.getOrDefault("X-Amz-Signature")
  valid_607430 = validateParameter(valid_607430, JString, required = false,
                                 default = nil)
  if valid_607430 != nil:
    section.add "X-Amz-Signature", valid_607430
  var valid_607431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "X-Amz-Content-Sha256", valid_607431
  var valid_607432 = header.getOrDefault("X-Amz-Date")
  valid_607432 = validateParameter(valid_607432, JString, required = false,
                                 default = nil)
  if valid_607432 != nil:
    section.add "X-Amz-Date", valid_607432
  var valid_607433 = header.getOrDefault("X-Amz-Credential")
  valid_607433 = validateParameter(valid_607433, JString, required = false,
                                 default = nil)
  if valid_607433 != nil:
    section.add "X-Amz-Credential", valid_607433
  var valid_607434 = header.getOrDefault("X-Amz-Security-Token")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "X-Amz-Security-Token", valid_607434
  var valid_607435 = header.getOrDefault("X-Amz-Algorithm")
  valid_607435 = validateParameter(valid_607435, JString, required = false,
                                 default = nil)
  if valid_607435 != nil:
    section.add "X-Amz-Algorithm", valid_607435
  var valid_607436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607436 = validateParameter(valid_607436, JString, required = false,
                                 default = nil)
  if valid_607436 != nil:
    section.add "X-Amz-SignedHeaders", valid_607436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607437: Call_GetModifyDBClusterParameterGroup_607423;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_607437.validator(path, query, header, formData, body)
  let scheme = call_607437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607437.url(scheme.get, call_607437.host, call_607437.base,
                         call_607437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607437, url, valid)

proc call*(call_607438: Call_GetModifyDBClusterParameterGroup_607423;
          Parameters: JsonNode; DBClusterParameterGroupName: string;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to modify.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607439 = newJObject()
  if Parameters != nil:
    query_607439.add "Parameters", Parameters
  add(query_607439, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_607439, "Action", newJString(Action))
  add(query_607439, "Version", newJString(Version))
  result = call_607438.call(nil, query_607439, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_607423(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_607424, base: "/",
    url: url_GetModifyDBClusterParameterGroup_607425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_607477 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBClusterSnapshotAttribute_607479(protocol: Scheme;
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

proc validate_PostModifyDBClusterSnapshotAttribute_607478(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607480 = query.getOrDefault("Action")
  valid_607480 = validateParameter(valid_607480, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_607480 != nil:
    section.add "Action", valid_607480
  var valid_607481 = query.getOrDefault("Version")
  valid_607481 = validateParameter(valid_607481, JString, required = true,
                                 default = newJString("2014-10-31"))
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
  ##   AttributeName: JString (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_607489 = formData.getOrDefault("AttributeName")
  valid_607489 = validateParameter(valid_607489, JString, required = true,
                                 default = nil)
  if valid_607489 != nil:
    section.add "AttributeName", valid_607489
  var valid_607490 = formData.getOrDefault("ValuesToAdd")
  valid_607490 = validateParameter(valid_607490, JArray, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "ValuesToAdd", valid_607490
  var valid_607491 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_607491 = validateParameter(valid_607491, JString, required = true,
                                 default = nil)
  if valid_607491 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_607491
  var valid_607492 = formData.getOrDefault("ValuesToRemove")
  valid_607492 = validateParameter(valid_607492, JArray, required = false,
                                 default = nil)
  if valid_607492 != nil:
    section.add "ValuesToRemove", valid_607492
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607493: Call_PostModifyDBClusterSnapshotAttribute_607477;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_607493.validator(path, query, header, formData, body)
  let scheme = call_607493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607493.url(scheme.get, call_607493.host, call_607493.base,
                         call_607493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607493, url, valid)

proc call*(call_607494: Call_PostModifyDBClusterSnapshotAttribute_607477;
          AttributeName: string; DBClusterSnapshotIdentifier: string;
          ValuesToAdd: JsonNode = nil;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToRemove: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   AttributeName: string (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   Action: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   Version: string (required)
  var query_607495 = newJObject()
  var formData_607496 = newJObject()
  add(formData_607496, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    formData_607496.add "ValuesToAdd", ValuesToAdd
  add(formData_607496, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_607495, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_607496.add "ValuesToRemove", ValuesToRemove
  add(query_607495, "Version", newJString(Version))
  result = call_607494.call(nil, query_607495, nil, formData_607496, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_607477(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_607478, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_607479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_607458 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBClusterSnapshotAttribute_607460(protocol: Scheme; host: string;
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

proc validate_GetModifyDBClusterSnapshotAttribute_607459(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   Action: JString (required)
  ##   AttributeName: JString (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_607461 = query.getOrDefault("ValuesToRemove")
  valid_607461 = validateParameter(valid_607461, JArray, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "ValuesToRemove", valid_607461
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_607462 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_607462 = validateParameter(valid_607462, JString, required = true,
                                 default = nil)
  if valid_607462 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_607462
  var valid_607463 = query.getOrDefault("Action")
  valid_607463 = validateParameter(valid_607463, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_607463 != nil:
    section.add "Action", valid_607463
  var valid_607464 = query.getOrDefault("AttributeName")
  valid_607464 = validateParameter(valid_607464, JString, required = true,
                                 default = nil)
  if valid_607464 != nil:
    section.add "AttributeName", valid_607464
  var valid_607465 = query.getOrDefault("ValuesToAdd")
  valid_607465 = validateParameter(valid_607465, JArray, required = false,
                                 default = nil)
  if valid_607465 != nil:
    section.add "ValuesToAdd", valid_607465
  var valid_607466 = query.getOrDefault("Version")
  valid_607466 = validateParameter(valid_607466, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607466 != nil:
    section.add "Version", valid_607466
  result.add "query", section
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

proc call*(call_607474: Call_GetModifyDBClusterSnapshotAttribute_607458;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_607474.validator(path, query, header, formData, body)
  let scheme = call_607474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607474.url(scheme.get, call_607474.host, call_607474.base,
                         call_607474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607474, url, valid)

proc call*(call_607475: Call_GetModifyDBClusterSnapshotAttribute_607458;
          DBClusterSnapshotIdentifier: string; AttributeName: string;
          ValuesToRemove: JsonNode = nil;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToAdd: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   Action: string (required)
  ##   AttributeName: string (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Version: string (required)
  var query_607476 = newJObject()
  if ValuesToRemove != nil:
    query_607476.add "ValuesToRemove", ValuesToRemove
  add(query_607476, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_607476, "Action", newJString(Action))
  add(query_607476, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    query_607476.add "ValuesToAdd", ValuesToAdd
  add(query_607476, "Version", newJString(Version))
  result = call_607475.call(nil, query_607476, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_607458(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_607459, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_607460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_607520 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBInstance_607522(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_607521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607523 = query.getOrDefault("Action")
  valid_607523 = validateParameter(valid_607523, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607523 != nil:
    section.add "Action", valid_607523
  var valid_607524 = query.getOrDefault("Version")
  valid_607524 = validateParameter(valid_607524, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607524 != nil:
    section.add "Version", valid_607524
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607525 = header.getOrDefault("X-Amz-Signature")
  valid_607525 = validateParameter(valid_607525, JString, required = false,
                                 default = nil)
  if valid_607525 != nil:
    section.add "X-Amz-Signature", valid_607525
  var valid_607526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607526 = validateParameter(valid_607526, JString, required = false,
                                 default = nil)
  if valid_607526 != nil:
    section.add "X-Amz-Content-Sha256", valid_607526
  var valid_607527 = header.getOrDefault("X-Amz-Date")
  valid_607527 = validateParameter(valid_607527, JString, required = false,
                                 default = nil)
  if valid_607527 != nil:
    section.add "X-Amz-Date", valid_607527
  var valid_607528 = header.getOrDefault("X-Amz-Credential")
  valid_607528 = validateParameter(valid_607528, JString, required = false,
                                 default = nil)
  if valid_607528 != nil:
    section.add "X-Amz-Credential", valid_607528
  var valid_607529 = header.getOrDefault("X-Amz-Security-Token")
  valid_607529 = validateParameter(valid_607529, JString, required = false,
                                 default = nil)
  if valid_607529 != nil:
    section.add "X-Amz-Security-Token", valid_607529
  var valid_607530 = header.getOrDefault("X-Amz-Algorithm")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Algorithm", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-SignedHeaders", valid_607531
  result.add "header", section
  ## parameters in `formData` object:
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  section = newJObject()
  var valid_607532 = formData.getOrDefault("PromotionTier")
  valid_607532 = validateParameter(valid_607532, JInt, required = false, default = nil)
  if valid_607532 != nil:
    section.add "PromotionTier", valid_607532
  var valid_607533 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "PreferredMaintenanceWindow", valid_607533
  var valid_607534 = formData.getOrDefault("DBInstanceClass")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "DBInstanceClass", valid_607534
  var valid_607535 = formData.getOrDefault("CACertificateIdentifier")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "CACertificateIdentifier", valid_607535
  var valid_607536 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_607536 = validateParameter(valid_607536, JBool, required = false, default = nil)
  if valid_607536 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607536
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607537 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607537 = validateParameter(valid_607537, JString, required = true,
                                 default = nil)
  if valid_607537 != nil:
    section.add "DBInstanceIdentifier", valid_607537
  var valid_607538 = formData.getOrDefault("ApplyImmediately")
  valid_607538 = validateParameter(valid_607538, JBool, required = false, default = nil)
  if valid_607538 != nil:
    section.add "ApplyImmediately", valid_607538
  var valid_607539 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_607539 = validateParameter(valid_607539, JString, required = false,
                                 default = nil)
  if valid_607539 != nil:
    section.add "NewDBInstanceIdentifier", valid_607539
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607540: Call_PostModifyDBInstance_607520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_607540.validator(path, query, header, formData, body)
  let scheme = call_607540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607540.url(scheme.get, call_607540.host, call_607540.base,
                         call_607540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607540, url, valid)

proc call*(call_607541: Call_PostModifyDBInstance_607520;
          DBInstanceIdentifier: string; PromotionTier: int = 0;
          PreferredMaintenanceWindow: string = ""; DBInstanceClass: string = "";
          CACertificateIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Action: string = "ModifyDBInstance"; NewDBInstanceIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBInstance
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   Action: string (required)
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Version: string (required)
  var query_607542 = newJObject()
  var formData_607543 = newJObject()
  add(formData_607543, "PromotionTier", newJInt(PromotionTier))
  add(formData_607543, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_607543, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_607543, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(formData_607543, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_607543, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_607543, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_607542, "Action", newJString(Action))
  add(formData_607543, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_607542, "Version", newJString(Version))
  result = call_607541.call(nil, query_607542, nil, formData_607543, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_607520(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_607521, base: "/",
    url: url_PostModifyDBInstance_607522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_607497 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBInstance_607499(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_607498(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   Action: JString (required)
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  section = newJObject()
  var valid_607500 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_607500 = validateParameter(valid_607500, JString, required = false,
                                 default = nil)
  if valid_607500 != nil:
    section.add "NewDBInstanceIdentifier", valid_607500
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607501 = query.getOrDefault("DBInstanceIdentifier")
  valid_607501 = validateParameter(valid_607501, JString, required = true,
                                 default = nil)
  if valid_607501 != nil:
    section.add "DBInstanceIdentifier", valid_607501
  var valid_607502 = query.getOrDefault("PromotionTier")
  valid_607502 = validateParameter(valid_607502, JInt, required = false, default = nil)
  if valid_607502 != nil:
    section.add "PromotionTier", valid_607502
  var valid_607503 = query.getOrDefault("CACertificateIdentifier")
  valid_607503 = validateParameter(valid_607503, JString, required = false,
                                 default = nil)
  if valid_607503 != nil:
    section.add "CACertificateIdentifier", valid_607503
  var valid_607504 = query.getOrDefault("Action")
  valid_607504 = validateParameter(valid_607504, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_607504 != nil:
    section.add "Action", valid_607504
  var valid_607505 = query.getOrDefault("ApplyImmediately")
  valid_607505 = validateParameter(valid_607505, JBool, required = false, default = nil)
  if valid_607505 != nil:
    section.add "ApplyImmediately", valid_607505
  var valid_607506 = query.getOrDefault("Version")
  valid_607506 = validateParameter(valid_607506, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607506 != nil:
    section.add "Version", valid_607506
  var valid_607507 = query.getOrDefault("DBInstanceClass")
  valid_607507 = validateParameter(valid_607507, JString, required = false,
                                 default = nil)
  if valid_607507 != nil:
    section.add "DBInstanceClass", valid_607507
  var valid_607508 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_607508 = validateParameter(valid_607508, JString, required = false,
                                 default = nil)
  if valid_607508 != nil:
    section.add "PreferredMaintenanceWindow", valid_607508
  var valid_607509 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_607509 = validateParameter(valid_607509, JBool, required = false, default = nil)
  if valid_607509 != nil:
    section.add "AutoMinorVersionUpgrade", valid_607509
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607510 = header.getOrDefault("X-Amz-Signature")
  valid_607510 = validateParameter(valid_607510, JString, required = false,
                                 default = nil)
  if valid_607510 != nil:
    section.add "X-Amz-Signature", valid_607510
  var valid_607511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607511 = validateParameter(valid_607511, JString, required = false,
                                 default = nil)
  if valid_607511 != nil:
    section.add "X-Amz-Content-Sha256", valid_607511
  var valid_607512 = header.getOrDefault("X-Amz-Date")
  valid_607512 = validateParameter(valid_607512, JString, required = false,
                                 default = nil)
  if valid_607512 != nil:
    section.add "X-Amz-Date", valid_607512
  var valid_607513 = header.getOrDefault("X-Amz-Credential")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "X-Amz-Credential", valid_607513
  var valid_607514 = header.getOrDefault("X-Amz-Security-Token")
  valid_607514 = validateParameter(valid_607514, JString, required = false,
                                 default = nil)
  if valid_607514 != nil:
    section.add "X-Amz-Security-Token", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Algorithm")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Algorithm", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-SignedHeaders", valid_607516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607517: Call_GetModifyDBInstance_607497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_607517.validator(path, query, header, formData, body)
  let scheme = call_607517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607517.url(scheme.get, call_607517.host, call_607517.base,
                         call_607517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607517, url, valid)

proc call*(call_607518: Call_GetModifyDBInstance_607497;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          PromotionTier: int = 0; CACertificateIdentifier: string = "";
          Action: string = "ModifyDBInstance"; ApplyImmediately: bool = false;
          Version: string = "2014-10-31"; DBInstanceClass: string = "";
          PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false): Recallable =
  ## getModifyDBInstance
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  var query_607519 = newJObject()
  add(query_607519, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_607519, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607519, "PromotionTier", newJInt(PromotionTier))
  add(query_607519, "CACertificateIdentifier", newJString(CACertificateIdentifier))
  add(query_607519, "Action", newJString(Action))
  add(query_607519, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_607519, "Version", newJString(Version))
  add(query_607519, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_607519, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_607519, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_607518.call(nil, query_607519, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_607497(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_607498, base: "/",
    url: url_GetModifyDBInstance_607499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_607562 = ref object of OpenApiRestCall_605573
proc url_PostModifyDBSubnetGroup_607564(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_607563(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607565 = query.getOrDefault("Action")
  valid_607565 = validateParameter(valid_607565, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607565 != nil:
    section.add "Action", valid_607565
  var valid_607566 = query.getOrDefault("Version")
  valid_607566 = validateParameter(valid_607566, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607566 != nil:
    section.add "Version", valid_607566
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607567 = header.getOrDefault("X-Amz-Signature")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-Signature", valid_607567
  var valid_607568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-Content-Sha256", valid_607568
  var valid_607569 = header.getOrDefault("X-Amz-Date")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "X-Amz-Date", valid_607569
  var valid_607570 = header.getOrDefault("X-Amz-Credential")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "X-Amz-Credential", valid_607570
  var valid_607571 = header.getOrDefault("X-Amz-Security-Token")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = nil)
  if valid_607571 != nil:
    section.add "X-Amz-Security-Token", valid_607571
  var valid_607572 = header.getOrDefault("X-Amz-Algorithm")
  valid_607572 = validateParameter(valid_607572, JString, required = false,
                                 default = nil)
  if valid_607572 != nil:
    section.add "X-Amz-Algorithm", valid_607572
  var valid_607573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607573 = validateParameter(valid_607573, JString, required = false,
                                 default = nil)
  if valid_607573 != nil:
    section.add "X-Amz-SignedHeaders", valid_607573
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the DB subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  section = newJObject()
  var valid_607574 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_607574 = validateParameter(valid_607574, JString, required = false,
                                 default = nil)
  if valid_607574 != nil:
    section.add "DBSubnetGroupDescription", valid_607574
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_607575 = formData.getOrDefault("DBSubnetGroupName")
  valid_607575 = validateParameter(valid_607575, JString, required = true,
                                 default = nil)
  if valid_607575 != nil:
    section.add "DBSubnetGroupName", valid_607575
  var valid_607576 = formData.getOrDefault("SubnetIds")
  valid_607576 = validateParameter(valid_607576, JArray, required = true, default = nil)
  if valid_607576 != nil:
    section.add "SubnetIds", valid_607576
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607577: Call_PostModifyDBSubnetGroup_607562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_607577.validator(path, query, header, formData, body)
  let scheme = call_607577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607577.url(scheme.get, call_607577.host, call_607577.base,
                         call_607577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607577, url, valid)

proc call*(call_607578: Call_PostModifyDBSubnetGroup_607562;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2014-10-31"): Recallable =
  ## postModifyDBSubnetGroup
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the DB subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  var query_607579 = newJObject()
  var formData_607580 = newJObject()
  add(formData_607580, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607579, "Action", newJString(Action))
  add(formData_607580, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607579, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_607580.add "SubnetIds", SubnetIds
  result = call_607578.call(nil, query_607579, nil, formData_607580, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_607562(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_607563, base: "/",
    url: url_PostModifyDBSubnetGroup_607564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_607544 = ref object of OpenApiRestCall_605573
proc url_GetModifyDBSubnetGroup_607546(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_607545(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the DB subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_607547 = query.getOrDefault("SubnetIds")
  valid_607547 = validateParameter(valid_607547, JArray, required = true, default = nil)
  if valid_607547 != nil:
    section.add "SubnetIds", valid_607547
  var valid_607548 = query.getOrDefault("Action")
  valid_607548 = validateParameter(valid_607548, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_607548 != nil:
    section.add "Action", valid_607548
  var valid_607549 = query.getOrDefault("DBSubnetGroupDescription")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "DBSubnetGroupDescription", valid_607549
  var valid_607550 = query.getOrDefault("DBSubnetGroupName")
  valid_607550 = validateParameter(valid_607550, JString, required = true,
                                 default = nil)
  if valid_607550 != nil:
    section.add "DBSubnetGroupName", valid_607550
  var valid_607551 = query.getOrDefault("Version")
  valid_607551 = validateParameter(valid_607551, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607551 != nil:
    section.add "Version", valid_607551
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607552 = header.getOrDefault("X-Amz-Signature")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "X-Amz-Signature", valid_607552
  var valid_607553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-Content-Sha256", valid_607553
  var valid_607554 = header.getOrDefault("X-Amz-Date")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "X-Amz-Date", valid_607554
  var valid_607555 = header.getOrDefault("X-Amz-Credential")
  valid_607555 = validateParameter(valid_607555, JString, required = false,
                                 default = nil)
  if valid_607555 != nil:
    section.add "X-Amz-Credential", valid_607555
  var valid_607556 = header.getOrDefault("X-Amz-Security-Token")
  valid_607556 = validateParameter(valid_607556, JString, required = false,
                                 default = nil)
  if valid_607556 != nil:
    section.add "X-Amz-Security-Token", valid_607556
  var valid_607557 = header.getOrDefault("X-Amz-Algorithm")
  valid_607557 = validateParameter(valid_607557, JString, required = false,
                                 default = nil)
  if valid_607557 != nil:
    section.add "X-Amz-Algorithm", valid_607557
  var valid_607558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607558 = validateParameter(valid_607558, JString, required = false,
                                 default = nil)
  if valid_607558 != nil:
    section.add "X-Amz-SignedHeaders", valid_607558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607559: Call_GetModifyDBSubnetGroup_607544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_607559.validator(path, query, header, formData, body)
  let scheme = call_607559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607559.url(scheme.get, call_607559.host, call_607559.base,
                         call_607559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607559, url, valid)

proc call*(call_607560: Call_GetModifyDBSubnetGroup_607544; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBSubnetGroup
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the DB subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_607561 = newJObject()
  if SubnetIds != nil:
    query_607561.add "SubnetIds", SubnetIds
  add(query_607561, "Action", newJString(Action))
  add(query_607561, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_607561, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607561, "Version", newJString(Version))
  result = call_607560.call(nil, query_607561, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_607544(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_607545, base: "/",
    url: url_GetModifyDBSubnetGroup_607546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_607598 = ref object of OpenApiRestCall_605573
proc url_PostRebootDBInstance_607600(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_607599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607601 = query.getOrDefault("Action")
  valid_607601 = validateParameter(valid_607601, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_607601 != nil:
    section.add "Action", valid_607601
  var valid_607602 = query.getOrDefault("Version")
  valid_607602 = validateParameter(valid_607602, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607602 != nil:
    section.add "Version", valid_607602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607603 = header.getOrDefault("X-Amz-Signature")
  valid_607603 = validateParameter(valid_607603, JString, required = false,
                                 default = nil)
  if valid_607603 != nil:
    section.add "X-Amz-Signature", valid_607603
  var valid_607604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607604 = validateParameter(valid_607604, JString, required = false,
                                 default = nil)
  if valid_607604 != nil:
    section.add "X-Amz-Content-Sha256", valid_607604
  var valid_607605 = header.getOrDefault("X-Amz-Date")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "X-Amz-Date", valid_607605
  var valid_607606 = header.getOrDefault("X-Amz-Credential")
  valid_607606 = validateParameter(valid_607606, JString, required = false,
                                 default = nil)
  if valid_607606 != nil:
    section.add "X-Amz-Credential", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-Security-Token")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-Security-Token", valid_607607
  var valid_607608 = header.getOrDefault("X-Amz-Algorithm")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "X-Amz-Algorithm", valid_607608
  var valid_607609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "X-Amz-SignedHeaders", valid_607609
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  var valid_607610 = formData.getOrDefault("ForceFailover")
  valid_607610 = validateParameter(valid_607610, JBool, required = false, default = nil)
  if valid_607610 != nil:
    section.add "ForceFailover", valid_607610
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607611 = formData.getOrDefault("DBInstanceIdentifier")
  valid_607611 = validateParameter(valid_607611, JString, required = true,
                                 default = nil)
  if valid_607611 != nil:
    section.add "DBInstanceIdentifier", valid_607611
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607612: Call_PostRebootDBInstance_607598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_607612.validator(path, query, header, formData, body)
  let scheme = call_607612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607612.url(scheme.get, call_607612.host, call_607612.base,
                         call_607612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607612, url, valid)

proc call*(call_607613: Call_PostRebootDBInstance_607598;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-10-31"): Recallable =
  ## postRebootDBInstance
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607614 = newJObject()
  var formData_607615 = newJObject()
  add(formData_607615, "ForceFailover", newJBool(ForceFailover))
  add(formData_607615, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607614, "Action", newJString(Action))
  add(query_607614, "Version", newJString(Version))
  result = call_607613.call(nil, query_607614, nil, formData_607615, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_607598(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_607599, base: "/",
    url: url_PostRebootDBInstance_607600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_607581 = ref object of OpenApiRestCall_605573
proc url_GetRebootDBInstance_607583(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_607582(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607584 = query.getOrDefault("ForceFailover")
  valid_607584 = validateParameter(valid_607584, JBool, required = false, default = nil)
  if valid_607584 != nil:
    section.add "ForceFailover", valid_607584
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_607585 = query.getOrDefault("DBInstanceIdentifier")
  valid_607585 = validateParameter(valid_607585, JString, required = true,
                                 default = nil)
  if valid_607585 != nil:
    section.add "DBInstanceIdentifier", valid_607585
  var valid_607586 = query.getOrDefault("Action")
  valid_607586 = validateParameter(valid_607586, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_607586 != nil:
    section.add "Action", valid_607586
  var valid_607587 = query.getOrDefault("Version")
  valid_607587 = validateParameter(valid_607587, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607587 != nil:
    section.add "Version", valid_607587
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607588 = header.getOrDefault("X-Amz-Signature")
  valid_607588 = validateParameter(valid_607588, JString, required = false,
                                 default = nil)
  if valid_607588 != nil:
    section.add "X-Amz-Signature", valid_607588
  var valid_607589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607589 = validateParameter(valid_607589, JString, required = false,
                                 default = nil)
  if valid_607589 != nil:
    section.add "X-Amz-Content-Sha256", valid_607589
  var valid_607590 = header.getOrDefault("X-Amz-Date")
  valid_607590 = validateParameter(valid_607590, JString, required = false,
                                 default = nil)
  if valid_607590 != nil:
    section.add "X-Amz-Date", valid_607590
  var valid_607591 = header.getOrDefault("X-Amz-Credential")
  valid_607591 = validateParameter(valid_607591, JString, required = false,
                                 default = nil)
  if valid_607591 != nil:
    section.add "X-Amz-Credential", valid_607591
  var valid_607592 = header.getOrDefault("X-Amz-Security-Token")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "X-Amz-Security-Token", valid_607592
  var valid_607593 = header.getOrDefault("X-Amz-Algorithm")
  valid_607593 = validateParameter(valid_607593, JString, required = false,
                                 default = nil)
  if valid_607593 != nil:
    section.add "X-Amz-Algorithm", valid_607593
  var valid_607594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607594 = validateParameter(valid_607594, JString, required = false,
                                 default = nil)
  if valid_607594 != nil:
    section.add "X-Amz-SignedHeaders", valid_607594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607595: Call_GetRebootDBInstance_607581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_607595.validator(path, query, header, formData, body)
  let scheme = call_607595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607595.url(scheme.get, call_607595.host, call_607595.base,
                         call_607595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607595, url, valid)

proc call*(call_607596: Call_GetRebootDBInstance_607581;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-10-31"): Recallable =
  ## getRebootDBInstance
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607597 = newJObject()
  add(query_607597, "ForceFailover", newJBool(ForceFailover))
  add(query_607597, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_607597, "Action", newJString(Action))
  add(query_607597, "Version", newJString(Version))
  result = call_607596.call(nil, query_607597, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_607581(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_607582, base: "/",
    url: url_GetRebootDBInstance_607583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_607633 = ref object of OpenApiRestCall_605573
proc url_PostRemoveTagsFromResource_607635(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_607634(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607636 = query.getOrDefault("Action")
  valid_607636 = validateParameter(valid_607636, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_607636 != nil:
    section.add "Action", valid_607636
  var valid_607637 = query.getOrDefault("Version")
  valid_607637 = validateParameter(valid_607637, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607637 != nil:
    section.add "Version", valid_607637
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607638 = header.getOrDefault("X-Amz-Signature")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "X-Amz-Signature", valid_607638
  var valid_607639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607639 = validateParameter(valid_607639, JString, required = false,
                                 default = nil)
  if valid_607639 != nil:
    section.add "X-Amz-Content-Sha256", valid_607639
  var valid_607640 = header.getOrDefault("X-Amz-Date")
  valid_607640 = validateParameter(valid_607640, JString, required = false,
                                 default = nil)
  if valid_607640 != nil:
    section.add "X-Amz-Date", valid_607640
  var valid_607641 = header.getOrDefault("X-Amz-Credential")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "X-Amz-Credential", valid_607641
  var valid_607642 = header.getOrDefault("X-Amz-Security-Token")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "X-Amz-Security-Token", valid_607642
  var valid_607643 = header.getOrDefault("X-Amz-Algorithm")
  valid_607643 = validateParameter(valid_607643, JString, required = false,
                                 default = nil)
  if valid_607643 != nil:
    section.add "X-Amz-Algorithm", valid_607643
  var valid_607644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607644 = validateParameter(valid_607644, JString, required = false,
                                 default = nil)
  if valid_607644 != nil:
    section.add "X-Amz-SignedHeaders", valid_607644
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_607645 = formData.getOrDefault("TagKeys")
  valid_607645 = validateParameter(valid_607645, JArray, required = true, default = nil)
  if valid_607645 != nil:
    section.add "TagKeys", valid_607645
  var valid_607646 = formData.getOrDefault("ResourceName")
  valid_607646 = validateParameter(valid_607646, JString, required = true,
                                 default = nil)
  if valid_607646 != nil:
    section.add "ResourceName", valid_607646
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607647: Call_PostRemoveTagsFromResource_607633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_607647.validator(path, query, header, formData, body)
  let scheme = call_607647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607647.url(scheme.get, call_607647.host, call_607647.base,
                         call_607647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607647, url, valid)

proc call*(call_607648: Call_PostRemoveTagsFromResource_607633; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-10-31"): Recallable =
  ## postRemoveTagsFromResource
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  var query_607649 = newJObject()
  var formData_607650 = newJObject()
  if TagKeys != nil:
    formData_607650.add "TagKeys", TagKeys
  add(query_607649, "Action", newJString(Action))
  add(query_607649, "Version", newJString(Version))
  add(formData_607650, "ResourceName", newJString(ResourceName))
  result = call_607648.call(nil, query_607649, nil, formData_607650, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_607633(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_607634, base: "/",
    url: url_PostRemoveTagsFromResource_607635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_607616 = ref object of OpenApiRestCall_605573
proc url_GetRemoveTagsFromResource_607618(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_607617(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_607619 = query.getOrDefault("ResourceName")
  valid_607619 = validateParameter(valid_607619, JString, required = true,
                                 default = nil)
  if valid_607619 != nil:
    section.add "ResourceName", valid_607619
  var valid_607620 = query.getOrDefault("TagKeys")
  valid_607620 = validateParameter(valid_607620, JArray, required = true, default = nil)
  if valid_607620 != nil:
    section.add "TagKeys", valid_607620
  var valid_607621 = query.getOrDefault("Action")
  valid_607621 = validateParameter(valid_607621, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_607621 != nil:
    section.add "Action", valid_607621
  var valid_607622 = query.getOrDefault("Version")
  valid_607622 = validateParameter(valid_607622, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607622 != nil:
    section.add "Version", valid_607622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607623 = header.getOrDefault("X-Amz-Signature")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "X-Amz-Signature", valid_607623
  var valid_607624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "X-Amz-Content-Sha256", valid_607624
  var valid_607625 = header.getOrDefault("X-Amz-Date")
  valid_607625 = validateParameter(valid_607625, JString, required = false,
                                 default = nil)
  if valid_607625 != nil:
    section.add "X-Amz-Date", valid_607625
  var valid_607626 = header.getOrDefault("X-Amz-Credential")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-Credential", valid_607626
  var valid_607627 = header.getOrDefault("X-Amz-Security-Token")
  valid_607627 = validateParameter(valid_607627, JString, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "X-Amz-Security-Token", valid_607627
  var valid_607628 = header.getOrDefault("X-Amz-Algorithm")
  valid_607628 = validateParameter(valid_607628, JString, required = false,
                                 default = nil)
  if valid_607628 != nil:
    section.add "X-Amz-Algorithm", valid_607628
  var valid_607629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607629 = validateParameter(valid_607629, JString, required = false,
                                 default = nil)
  if valid_607629 != nil:
    section.add "X-Amz-SignedHeaders", valid_607629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607630: Call_GetRemoveTagsFromResource_607616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_607630.validator(path, query, header, formData, body)
  let scheme = call_607630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607630.url(scheme.get, call_607630.host, call_607630.base,
                         call_607630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607630, url, valid)

proc call*(call_607631: Call_GetRemoveTagsFromResource_607616;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-10-31"): Recallable =
  ## getRemoveTagsFromResource
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607632 = newJObject()
  add(query_607632, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_607632.add "TagKeys", TagKeys
  add(query_607632, "Action", newJString(Action))
  add(query_607632, "Version", newJString(Version))
  result = call_607631.call(nil, query_607632, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_607616(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_607617, base: "/",
    url: url_GetRemoveTagsFromResource_607618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_607669 = ref object of OpenApiRestCall_605573
proc url_PostResetDBClusterParameterGroup_607671(protocol: Scheme; host: string;
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

proc validate_PostResetDBClusterParameterGroup_607670(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607672 = query.getOrDefault("Action")
  valid_607672 = validateParameter(valid_607672, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_607672 != nil:
    section.add "Action", valid_607672
  var valid_607673 = query.getOrDefault("Version")
  valid_607673 = validateParameter(valid_607673, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607673 != nil:
    section.add "Version", valid_607673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607674 = header.getOrDefault("X-Amz-Signature")
  valid_607674 = validateParameter(valid_607674, JString, required = false,
                                 default = nil)
  if valid_607674 != nil:
    section.add "X-Amz-Signature", valid_607674
  var valid_607675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607675 = validateParameter(valid_607675, JString, required = false,
                                 default = nil)
  if valid_607675 != nil:
    section.add "X-Amz-Content-Sha256", valid_607675
  var valid_607676 = header.getOrDefault("X-Amz-Date")
  valid_607676 = validateParameter(valid_607676, JString, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "X-Amz-Date", valid_607676
  var valid_607677 = header.getOrDefault("X-Amz-Credential")
  valid_607677 = validateParameter(valid_607677, JString, required = false,
                                 default = nil)
  if valid_607677 != nil:
    section.add "X-Amz-Credential", valid_607677
  var valid_607678 = header.getOrDefault("X-Amz-Security-Token")
  valid_607678 = validateParameter(valid_607678, JString, required = false,
                                 default = nil)
  if valid_607678 != nil:
    section.add "X-Amz-Security-Token", valid_607678
  var valid_607679 = header.getOrDefault("X-Amz-Algorithm")
  valid_607679 = validateParameter(valid_607679, JString, required = false,
                                 default = nil)
  if valid_607679 != nil:
    section.add "X-Amz-Algorithm", valid_607679
  var valid_607680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607680 = validateParameter(valid_607680, JString, required = false,
                                 default = nil)
  if valid_607680 != nil:
    section.add "X-Amz-SignedHeaders", valid_607680
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  section = newJObject()
  var valid_607681 = formData.getOrDefault("ResetAllParameters")
  valid_607681 = validateParameter(valid_607681, JBool, required = false, default = nil)
  if valid_607681 != nil:
    section.add "ResetAllParameters", valid_607681
  var valid_607682 = formData.getOrDefault("Parameters")
  valid_607682 = validateParameter(valid_607682, JArray, required = false,
                                 default = nil)
  if valid_607682 != nil:
    section.add "Parameters", valid_607682
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_607683 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_607683 = validateParameter(valid_607683, JString, required = true,
                                 default = nil)
  if valid_607683 != nil:
    section.add "DBClusterParameterGroupName", valid_607683
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607684: Call_PostResetDBClusterParameterGroup_607669;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_607684.validator(path, query, header, formData, body)
  let scheme = call_607684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607684.url(scheme.get, call_607684.host, call_607684.base,
                         call_607684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607684, url, valid)

proc call*(call_607685: Call_PostResetDBClusterParameterGroup_607669;
          DBClusterParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBClusterParameterGroup";
          Parameters: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Action: string (required)
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   Version: string (required)
  var query_607686 = newJObject()
  var formData_607687 = newJObject()
  add(formData_607687, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_607686, "Action", newJString(Action))
  if Parameters != nil:
    formData_607687.add "Parameters", Parameters
  add(formData_607687, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_607686, "Version", newJString(Version))
  result = call_607685.call(nil, query_607686, nil, formData_607687, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_607669(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_607670, base: "/",
    url: url_PostResetDBClusterParameterGroup_607671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_607651 = ref object of OpenApiRestCall_605573
proc url_GetResetDBClusterParameterGroup_607653(protocol: Scheme; host: string;
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

proc validate_GetResetDBClusterParameterGroup_607652(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_607654 = query.getOrDefault("Parameters")
  valid_607654 = validateParameter(valid_607654, JArray, required = false,
                                 default = nil)
  if valid_607654 != nil:
    section.add "Parameters", valid_607654
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_607655 = query.getOrDefault("DBClusterParameterGroupName")
  valid_607655 = validateParameter(valid_607655, JString, required = true,
                                 default = nil)
  if valid_607655 != nil:
    section.add "DBClusterParameterGroupName", valid_607655
  var valid_607656 = query.getOrDefault("ResetAllParameters")
  valid_607656 = validateParameter(valid_607656, JBool, required = false, default = nil)
  if valid_607656 != nil:
    section.add "ResetAllParameters", valid_607656
  var valid_607657 = query.getOrDefault("Action")
  valid_607657 = validateParameter(valid_607657, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_607657 != nil:
    section.add "Action", valid_607657
  var valid_607658 = query.getOrDefault("Version")
  valid_607658 = validateParameter(valid_607658, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607658 != nil:
    section.add "Version", valid_607658
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607659 = header.getOrDefault("X-Amz-Signature")
  valid_607659 = validateParameter(valid_607659, JString, required = false,
                                 default = nil)
  if valid_607659 != nil:
    section.add "X-Amz-Signature", valid_607659
  var valid_607660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607660 = validateParameter(valid_607660, JString, required = false,
                                 default = nil)
  if valid_607660 != nil:
    section.add "X-Amz-Content-Sha256", valid_607660
  var valid_607661 = header.getOrDefault("X-Amz-Date")
  valid_607661 = validateParameter(valid_607661, JString, required = false,
                                 default = nil)
  if valid_607661 != nil:
    section.add "X-Amz-Date", valid_607661
  var valid_607662 = header.getOrDefault("X-Amz-Credential")
  valid_607662 = validateParameter(valid_607662, JString, required = false,
                                 default = nil)
  if valid_607662 != nil:
    section.add "X-Amz-Credential", valid_607662
  var valid_607663 = header.getOrDefault("X-Amz-Security-Token")
  valid_607663 = validateParameter(valid_607663, JString, required = false,
                                 default = nil)
  if valid_607663 != nil:
    section.add "X-Amz-Security-Token", valid_607663
  var valid_607664 = header.getOrDefault("X-Amz-Algorithm")
  valid_607664 = validateParameter(valid_607664, JString, required = false,
                                 default = nil)
  if valid_607664 != nil:
    section.add "X-Amz-Algorithm", valid_607664
  var valid_607665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607665 = validateParameter(valid_607665, JString, required = false,
                                 default = nil)
  if valid_607665 != nil:
    section.add "X-Amz-SignedHeaders", valid_607665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607666: Call_GetResetDBClusterParameterGroup_607651;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_607666.validator(path, query, header, formData, body)
  let scheme = call_607666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607666.url(scheme.get, call_607666.host, call_607666.base,
                         call_607666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607666, url, valid)

proc call*(call_607667: Call_GetResetDBClusterParameterGroup_607651;
          DBClusterParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607668 = newJObject()
  if Parameters != nil:
    query_607668.add "Parameters", Parameters
  add(query_607668, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_607668, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_607668, "Action", newJString(Action))
  add(query_607668, "Version", newJString(Version))
  result = call_607667.call(nil, query_607668, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_607651(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_607652, base: "/",
    url: url_GetResetDBClusterParameterGroup_607653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_607715 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBClusterFromSnapshot_607717(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBClusterFromSnapshot_607716(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607718 = query.getOrDefault("Action")
  valid_607718 = validateParameter(valid_607718, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_607718 != nil:
    section.add "Action", valid_607718
  var valid_607719 = query.getOrDefault("Version")
  valid_607719 = validateParameter(valid_607719, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607719 != nil:
    section.add "Version", valid_607719
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607720 = header.getOrDefault("X-Amz-Signature")
  valid_607720 = validateParameter(valid_607720, JString, required = false,
                                 default = nil)
  if valid_607720 != nil:
    section.add "X-Amz-Signature", valid_607720
  var valid_607721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607721 = validateParameter(valid_607721, JString, required = false,
                                 default = nil)
  if valid_607721 != nil:
    section.add "X-Amz-Content-Sha256", valid_607721
  var valid_607722 = header.getOrDefault("X-Amz-Date")
  valid_607722 = validateParameter(valid_607722, JString, required = false,
                                 default = nil)
  if valid_607722 != nil:
    section.add "X-Amz-Date", valid_607722
  var valid_607723 = header.getOrDefault("X-Amz-Credential")
  valid_607723 = validateParameter(valid_607723, JString, required = false,
                                 default = nil)
  if valid_607723 != nil:
    section.add "X-Amz-Credential", valid_607723
  var valid_607724 = header.getOrDefault("X-Amz-Security-Token")
  valid_607724 = validateParameter(valid_607724, JString, required = false,
                                 default = nil)
  if valid_607724 != nil:
    section.add "X-Amz-Security-Token", valid_607724
  var valid_607725 = header.getOrDefault("X-Amz-Algorithm")
  valid_607725 = validateParameter(valid_607725, JString, required = false,
                                 default = nil)
  if valid_607725 != nil:
    section.add "X-Amz-Algorithm", valid_607725
  var valid_607726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607726 = validateParameter(valid_607726, JString, required = false,
                                 default = nil)
  if valid_607726 != nil:
    section.add "X-Amz-SignedHeaders", valid_607726
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new DB cluster.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  section = newJObject()
  var valid_607727 = formData.getOrDefault("Port")
  valid_607727 = validateParameter(valid_607727, JInt, required = false, default = nil)
  if valid_607727 != nil:
    section.add "Port", valid_607727
  var valid_607728 = formData.getOrDefault("EngineVersion")
  valid_607728 = validateParameter(valid_607728, JString, required = false,
                                 default = nil)
  if valid_607728 != nil:
    section.add "EngineVersion", valid_607728
  var valid_607729 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_607729 = validateParameter(valid_607729, JArray, required = false,
                                 default = nil)
  if valid_607729 != nil:
    section.add "VpcSecurityGroupIds", valid_607729
  var valid_607730 = formData.getOrDefault("AvailabilityZones")
  valid_607730 = validateParameter(valid_607730, JArray, required = false,
                                 default = nil)
  if valid_607730 != nil:
    section.add "AvailabilityZones", valid_607730
  var valid_607731 = formData.getOrDefault("KmsKeyId")
  valid_607731 = validateParameter(valid_607731, JString, required = false,
                                 default = nil)
  if valid_607731 != nil:
    section.add "KmsKeyId", valid_607731
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_607732 = formData.getOrDefault("Engine")
  valid_607732 = validateParameter(valid_607732, JString, required = true,
                                 default = nil)
  if valid_607732 != nil:
    section.add "Engine", valid_607732
  var valid_607733 = formData.getOrDefault("SnapshotIdentifier")
  valid_607733 = validateParameter(valid_607733, JString, required = true,
                                 default = nil)
  if valid_607733 != nil:
    section.add "SnapshotIdentifier", valid_607733
  var valid_607734 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_607734 = validateParameter(valid_607734, JArray, required = false,
                                 default = nil)
  if valid_607734 != nil:
    section.add "EnableCloudwatchLogsExports", valid_607734
  var valid_607735 = formData.getOrDefault("Tags")
  valid_607735 = validateParameter(valid_607735, JArray, required = false,
                                 default = nil)
  if valid_607735 != nil:
    section.add "Tags", valid_607735
  var valid_607736 = formData.getOrDefault("DBSubnetGroupName")
  valid_607736 = validateParameter(valid_607736, JString, required = false,
                                 default = nil)
  if valid_607736 != nil:
    section.add "DBSubnetGroupName", valid_607736
  var valid_607737 = formData.getOrDefault("DBClusterIdentifier")
  valid_607737 = validateParameter(valid_607737, JString, required = true,
                                 default = nil)
  if valid_607737 != nil:
    section.add "DBClusterIdentifier", valid_607737
  var valid_607738 = formData.getOrDefault("DeletionProtection")
  valid_607738 = validateParameter(valid_607738, JBool, required = false, default = nil)
  if valid_607738 != nil:
    section.add "DeletionProtection", valid_607738
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607739: Call_PostRestoreDBClusterFromSnapshot_607715;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_607739.validator(path, query, header, formData, body)
  let scheme = call_607739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607739.url(scheme.get, call_607739.host, call_607739.base,
                         call_607739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607739, url, valid)

proc call*(call_607740: Call_PostRestoreDBClusterFromSnapshot_607715;
          Engine: string; SnapshotIdentifier: string; DBClusterIdentifier: string;
          Port: int = 0; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZones: JsonNode = nil;
          KmsKeyId: string = ""; EnableCloudwatchLogsExports: JsonNode = nil;
          Action: string = "RestoreDBClusterFromSnapshot"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; Version: string = "2014-10-31";
          DeletionProtection: bool = false): Recallable =
  ## postRestoreDBClusterFromSnapshot
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new DB cluster.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  var query_607741 = newJObject()
  var formData_607742 = newJObject()
  add(formData_607742, "Port", newJInt(Port))
  add(formData_607742, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_607742.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_607742.add "AvailabilityZones", AvailabilityZones
  add(formData_607742, "KmsKeyId", newJString(KmsKeyId))
  add(formData_607742, "Engine", newJString(Engine))
  add(formData_607742, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if EnableCloudwatchLogsExports != nil:
    formData_607742.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_607741, "Action", newJString(Action))
  if Tags != nil:
    formData_607742.add "Tags", Tags
  add(formData_607742, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607741, "Version", newJString(Version))
  add(formData_607742, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_607742, "DeletionProtection", newJBool(DeletionProtection))
  result = call_607740.call(nil, query_607741, nil, formData_607742, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_607715(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_607716, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_607717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_607688 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBClusterFromSnapshot_607690(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBClusterFromSnapshot_607689(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new DB cluster.
  ##   Action: JString (required)
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_607691 = query.getOrDefault("DeletionProtection")
  valid_607691 = validateParameter(valid_607691, JBool, required = false, default = nil)
  if valid_607691 != nil:
    section.add "DeletionProtection", valid_607691
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_607692 = query.getOrDefault("Engine")
  valid_607692 = validateParameter(valid_607692, JString, required = true,
                                 default = nil)
  if valid_607692 != nil:
    section.add "Engine", valid_607692
  var valid_607693 = query.getOrDefault("SnapshotIdentifier")
  valid_607693 = validateParameter(valid_607693, JString, required = true,
                                 default = nil)
  if valid_607693 != nil:
    section.add "SnapshotIdentifier", valid_607693
  var valid_607694 = query.getOrDefault("Tags")
  valid_607694 = validateParameter(valid_607694, JArray, required = false,
                                 default = nil)
  if valid_607694 != nil:
    section.add "Tags", valid_607694
  var valid_607695 = query.getOrDefault("KmsKeyId")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "KmsKeyId", valid_607695
  var valid_607696 = query.getOrDefault("DBClusterIdentifier")
  valid_607696 = validateParameter(valid_607696, JString, required = true,
                                 default = nil)
  if valid_607696 != nil:
    section.add "DBClusterIdentifier", valid_607696
  var valid_607697 = query.getOrDefault("AvailabilityZones")
  valid_607697 = validateParameter(valid_607697, JArray, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "AvailabilityZones", valid_607697
  var valid_607698 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_607698 = validateParameter(valid_607698, JArray, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "EnableCloudwatchLogsExports", valid_607698
  var valid_607699 = query.getOrDefault("EngineVersion")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "EngineVersion", valid_607699
  var valid_607700 = query.getOrDefault("Action")
  valid_607700 = validateParameter(valid_607700, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_607700 != nil:
    section.add "Action", valid_607700
  var valid_607701 = query.getOrDefault("Port")
  valid_607701 = validateParameter(valid_607701, JInt, required = false, default = nil)
  if valid_607701 != nil:
    section.add "Port", valid_607701
  var valid_607702 = query.getOrDefault("VpcSecurityGroupIds")
  valid_607702 = validateParameter(valid_607702, JArray, required = false,
                                 default = nil)
  if valid_607702 != nil:
    section.add "VpcSecurityGroupIds", valid_607702
  var valid_607703 = query.getOrDefault("DBSubnetGroupName")
  valid_607703 = validateParameter(valid_607703, JString, required = false,
                                 default = nil)
  if valid_607703 != nil:
    section.add "DBSubnetGroupName", valid_607703
  var valid_607704 = query.getOrDefault("Version")
  valid_607704 = validateParameter(valid_607704, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607704 != nil:
    section.add "Version", valid_607704
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607705 = header.getOrDefault("X-Amz-Signature")
  valid_607705 = validateParameter(valid_607705, JString, required = false,
                                 default = nil)
  if valid_607705 != nil:
    section.add "X-Amz-Signature", valid_607705
  var valid_607706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607706 = validateParameter(valid_607706, JString, required = false,
                                 default = nil)
  if valid_607706 != nil:
    section.add "X-Amz-Content-Sha256", valid_607706
  var valid_607707 = header.getOrDefault("X-Amz-Date")
  valid_607707 = validateParameter(valid_607707, JString, required = false,
                                 default = nil)
  if valid_607707 != nil:
    section.add "X-Amz-Date", valid_607707
  var valid_607708 = header.getOrDefault("X-Amz-Credential")
  valid_607708 = validateParameter(valid_607708, JString, required = false,
                                 default = nil)
  if valid_607708 != nil:
    section.add "X-Amz-Credential", valid_607708
  var valid_607709 = header.getOrDefault("X-Amz-Security-Token")
  valid_607709 = validateParameter(valid_607709, JString, required = false,
                                 default = nil)
  if valid_607709 != nil:
    section.add "X-Amz-Security-Token", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-Algorithm")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-Algorithm", valid_607710
  var valid_607711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "X-Amz-SignedHeaders", valid_607711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607712: Call_GetRestoreDBClusterFromSnapshot_607688;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_607712.validator(path, query, header, formData, body)
  let scheme = call_607712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607712.url(scheme.get, call_607712.host, call_607712.base,
                         call_607712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607712, url, valid)

proc call*(call_607713: Call_GetRestoreDBClusterFromSnapshot_607688;
          Engine: string; SnapshotIdentifier: string; DBClusterIdentifier: string;
          DeletionProtection: bool = false; Tags: JsonNode = nil; KmsKeyId: string = "";
          AvailabilityZones: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; EngineVersion: string = "";
          Action: string = "RestoreDBClusterFromSnapshot"; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; DBSubnetGroupName: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterFromSnapshot
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new DB cluster.
  ##   Action: string (required)
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_607714 = newJObject()
  add(query_607714, "DeletionProtection", newJBool(DeletionProtection))
  add(query_607714, "Engine", newJString(Engine))
  add(query_607714, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if Tags != nil:
    query_607714.add "Tags", Tags
  add(query_607714, "KmsKeyId", newJString(KmsKeyId))
  add(query_607714, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if AvailabilityZones != nil:
    query_607714.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    query_607714.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_607714, "EngineVersion", newJString(EngineVersion))
  add(query_607714, "Action", newJString(Action))
  add(query_607714, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_607714.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_607714, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607714, "Version", newJString(Version))
  result = call_607713.call(nil, query_607714, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_607688(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_607689, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_607690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_607769 = ref object of OpenApiRestCall_605573
proc url_PostRestoreDBClusterToPointInTime_607771(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBClusterToPointInTime_607770(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607772 = query.getOrDefault("Action")
  valid_607772 = validateParameter(valid_607772, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_607772 != nil:
    section.add "Action", valid_607772
  var valid_607773 = query.getOrDefault("Version")
  valid_607773 = validateParameter(valid_607773, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607773 != nil:
    section.add "Version", valid_607773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607774 = header.getOrDefault("X-Amz-Signature")
  valid_607774 = validateParameter(valid_607774, JString, required = false,
                                 default = nil)
  if valid_607774 != nil:
    section.add "X-Amz-Signature", valid_607774
  var valid_607775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607775 = validateParameter(valid_607775, JString, required = false,
                                 default = nil)
  if valid_607775 != nil:
    section.add "X-Amz-Content-Sha256", valid_607775
  var valid_607776 = header.getOrDefault("X-Amz-Date")
  valid_607776 = validateParameter(valid_607776, JString, required = false,
                                 default = nil)
  if valid_607776 != nil:
    section.add "X-Amz-Date", valid_607776
  var valid_607777 = header.getOrDefault("X-Amz-Credential")
  valid_607777 = validateParameter(valid_607777, JString, required = false,
                                 default = nil)
  if valid_607777 != nil:
    section.add "X-Amz-Credential", valid_607777
  var valid_607778 = header.getOrDefault("X-Amz-Security-Token")
  valid_607778 = validateParameter(valid_607778, JString, required = false,
                                 default = nil)
  if valid_607778 != nil:
    section.add "X-Amz-Security-Token", valid_607778
  var valid_607779 = header.getOrDefault("X-Amz-Algorithm")
  valid_607779 = validateParameter(valid_607779, JString, required = false,
                                 default = nil)
  if valid_607779 != nil:
    section.add "X-Amz-Algorithm", valid_607779
  var valid_607780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607780 = validateParameter(valid_607780, JString, required = false,
                                 default = nil)
  if valid_607780 != nil:
    section.add "X-Amz-SignedHeaders", valid_607780
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  section = newJObject()
  var valid_607781 = formData.getOrDefault("Port")
  valid_607781 = validateParameter(valid_607781, JInt, required = false, default = nil)
  if valid_607781 != nil:
    section.add "Port", valid_607781
  var valid_607782 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_607782 = validateParameter(valid_607782, JArray, required = false,
                                 default = nil)
  if valid_607782 != nil:
    section.add "VpcSecurityGroupIds", valid_607782
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterIdentifier` field"
  var valid_607783 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_607783 = validateParameter(valid_607783, JString, required = true,
                                 default = nil)
  if valid_607783 != nil:
    section.add "SourceDBClusterIdentifier", valid_607783
  var valid_607784 = formData.getOrDefault("KmsKeyId")
  valid_607784 = validateParameter(valid_607784, JString, required = false,
                                 default = nil)
  if valid_607784 != nil:
    section.add "KmsKeyId", valid_607784
  var valid_607785 = formData.getOrDefault("UseLatestRestorableTime")
  valid_607785 = validateParameter(valid_607785, JBool, required = false, default = nil)
  if valid_607785 != nil:
    section.add "UseLatestRestorableTime", valid_607785
  var valid_607786 = formData.getOrDefault("RestoreToTime")
  valid_607786 = validateParameter(valid_607786, JString, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "RestoreToTime", valid_607786
  var valid_607787 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_607787 = validateParameter(valid_607787, JArray, required = false,
                                 default = nil)
  if valid_607787 != nil:
    section.add "EnableCloudwatchLogsExports", valid_607787
  var valid_607788 = formData.getOrDefault("Tags")
  valid_607788 = validateParameter(valid_607788, JArray, required = false,
                                 default = nil)
  if valid_607788 != nil:
    section.add "Tags", valid_607788
  var valid_607789 = formData.getOrDefault("DBSubnetGroupName")
  valid_607789 = validateParameter(valid_607789, JString, required = false,
                                 default = nil)
  if valid_607789 != nil:
    section.add "DBSubnetGroupName", valid_607789
  var valid_607790 = formData.getOrDefault("DBClusterIdentifier")
  valid_607790 = validateParameter(valid_607790, JString, required = true,
                                 default = nil)
  if valid_607790 != nil:
    section.add "DBClusterIdentifier", valid_607790
  var valid_607791 = formData.getOrDefault("DeletionProtection")
  valid_607791 = validateParameter(valid_607791, JBool, required = false, default = nil)
  if valid_607791 != nil:
    section.add "DeletionProtection", valid_607791
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607792: Call_PostRestoreDBClusterToPointInTime_607769;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_607792.validator(path, query, header, formData, body)
  let scheme = call_607792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607792.url(scheme.get, call_607792.host, call_607792.base,
                         call_607792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607792, url, valid)

proc call*(call_607793: Call_PostRestoreDBClusterToPointInTime_607769;
          SourceDBClusterIdentifier: string; DBClusterIdentifier: string;
          Port: int = 0; VpcSecurityGroupIds: JsonNode = nil; KmsKeyId: string = "";
          UseLatestRestorableTime: bool = false; RestoreToTime: string = "";
          EnableCloudwatchLogsExports: JsonNode = nil;
          Action: string = "RestoreDBClusterToPointInTime"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; Version: string = "2014-10-31";
          DeletionProtection: bool = false): Recallable =
  ## postRestoreDBClusterToPointInTime
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DBSubnetGroupName: string
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  var query_607794 = newJObject()
  var formData_607795 = newJObject()
  add(formData_607795, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_607795.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_607795, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_607795, "KmsKeyId", newJString(KmsKeyId))
  add(formData_607795, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_607795, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    formData_607795.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_607794, "Action", newJString(Action))
  if Tags != nil:
    formData_607795.add "Tags", Tags
  add(formData_607795, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607794, "Version", newJString(Version))
  add(formData_607795, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_607795, "DeletionProtection", newJBool(DeletionProtection))
  result = call_607793.call(nil, query_607794, nil, formData_607795, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_607769(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_607770, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_607771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_607743 = ref object of OpenApiRestCall_605573
proc url_GetRestoreDBClusterToPointInTime_607745(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBClusterToPointInTime_607744(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: JString (required)
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_607746 = query.getOrDefault("DeletionProtection")
  valid_607746 = validateParameter(valid_607746, JBool, required = false, default = nil)
  if valid_607746 != nil:
    section.add "DeletionProtection", valid_607746
  var valid_607747 = query.getOrDefault("UseLatestRestorableTime")
  valid_607747 = validateParameter(valid_607747, JBool, required = false, default = nil)
  if valid_607747 != nil:
    section.add "UseLatestRestorableTime", valid_607747
  var valid_607748 = query.getOrDefault("Tags")
  valid_607748 = validateParameter(valid_607748, JArray, required = false,
                                 default = nil)
  if valid_607748 != nil:
    section.add "Tags", valid_607748
  var valid_607749 = query.getOrDefault("KmsKeyId")
  valid_607749 = validateParameter(valid_607749, JString, required = false,
                                 default = nil)
  if valid_607749 != nil:
    section.add "KmsKeyId", valid_607749
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_607750 = query.getOrDefault("DBClusterIdentifier")
  valid_607750 = validateParameter(valid_607750, JString, required = true,
                                 default = nil)
  if valid_607750 != nil:
    section.add "DBClusterIdentifier", valid_607750
  var valid_607751 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_607751 = validateParameter(valid_607751, JString, required = true,
                                 default = nil)
  if valid_607751 != nil:
    section.add "SourceDBClusterIdentifier", valid_607751
  var valid_607752 = query.getOrDefault("RestoreToTime")
  valid_607752 = validateParameter(valid_607752, JString, required = false,
                                 default = nil)
  if valid_607752 != nil:
    section.add "RestoreToTime", valid_607752
  var valid_607753 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_607753 = validateParameter(valid_607753, JArray, required = false,
                                 default = nil)
  if valid_607753 != nil:
    section.add "EnableCloudwatchLogsExports", valid_607753
  var valid_607754 = query.getOrDefault("Action")
  valid_607754 = validateParameter(valid_607754, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_607754 != nil:
    section.add "Action", valid_607754
  var valid_607755 = query.getOrDefault("Port")
  valid_607755 = validateParameter(valid_607755, JInt, required = false, default = nil)
  if valid_607755 != nil:
    section.add "Port", valid_607755
  var valid_607756 = query.getOrDefault("VpcSecurityGroupIds")
  valid_607756 = validateParameter(valid_607756, JArray, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "VpcSecurityGroupIds", valid_607756
  var valid_607757 = query.getOrDefault("DBSubnetGroupName")
  valid_607757 = validateParameter(valid_607757, JString, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "DBSubnetGroupName", valid_607757
  var valid_607758 = query.getOrDefault("Version")
  valid_607758 = validateParameter(valid_607758, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607758 != nil:
    section.add "Version", valid_607758
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607759 = header.getOrDefault("X-Amz-Signature")
  valid_607759 = validateParameter(valid_607759, JString, required = false,
                                 default = nil)
  if valid_607759 != nil:
    section.add "X-Amz-Signature", valid_607759
  var valid_607760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607760 = validateParameter(valid_607760, JString, required = false,
                                 default = nil)
  if valid_607760 != nil:
    section.add "X-Amz-Content-Sha256", valid_607760
  var valid_607761 = header.getOrDefault("X-Amz-Date")
  valid_607761 = validateParameter(valid_607761, JString, required = false,
                                 default = nil)
  if valid_607761 != nil:
    section.add "X-Amz-Date", valid_607761
  var valid_607762 = header.getOrDefault("X-Amz-Credential")
  valid_607762 = validateParameter(valid_607762, JString, required = false,
                                 default = nil)
  if valid_607762 != nil:
    section.add "X-Amz-Credential", valid_607762
  var valid_607763 = header.getOrDefault("X-Amz-Security-Token")
  valid_607763 = validateParameter(valid_607763, JString, required = false,
                                 default = nil)
  if valid_607763 != nil:
    section.add "X-Amz-Security-Token", valid_607763
  var valid_607764 = header.getOrDefault("X-Amz-Algorithm")
  valid_607764 = validateParameter(valid_607764, JString, required = false,
                                 default = nil)
  if valid_607764 != nil:
    section.add "X-Amz-Algorithm", valid_607764
  var valid_607765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607765 = validateParameter(valid_607765, JString, required = false,
                                 default = nil)
  if valid_607765 != nil:
    section.add "X-Amz-SignedHeaders", valid_607765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607766: Call_GetRestoreDBClusterToPointInTime_607743;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_607766.validator(path, query, header, formData, body)
  let scheme = call_607766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607766.url(scheme.get, call_607766.host, call_607766.base,
                         call_607766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607766, url, valid)

proc call*(call_607767: Call_GetRestoreDBClusterToPointInTime_607743;
          DBClusterIdentifier: string; SourceDBClusterIdentifier: string;
          DeletionProtection: bool = false; UseLatestRestorableTime: bool = false;
          Tags: JsonNode = nil; KmsKeyId: string = ""; RestoreToTime: string = "";
          EnableCloudwatchLogsExports: JsonNode = nil;
          Action: string = "RestoreDBClusterToPointInTime"; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; DBSubnetGroupName: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterToPointInTime
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: string (required)
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   DBSubnetGroupName: string
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_607768 = newJObject()
  add(query_607768, "DeletionProtection", newJBool(DeletionProtection))
  add(query_607768, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_607768.add "Tags", Tags
  add(query_607768, "KmsKeyId", newJString(KmsKeyId))
  add(query_607768, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_607768, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_607768, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    query_607768.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_607768, "Action", newJString(Action))
  add(query_607768, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_607768.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_607768, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_607768, "Version", newJString(Version))
  result = call_607767.call(nil, query_607768, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_607743(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_607744, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_607745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_607812 = ref object of OpenApiRestCall_605573
proc url_PostStartDBCluster_607814(protocol: Scheme; host: string; base: string;
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

proc validate_PostStartDBCluster_607813(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607815 = query.getOrDefault("Action")
  valid_607815 = validateParameter(valid_607815, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_607815 != nil:
    section.add "Action", valid_607815
  var valid_607816 = query.getOrDefault("Version")
  valid_607816 = validateParameter(valid_607816, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607816 != nil:
    section.add "Version", valid_607816
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607817 = header.getOrDefault("X-Amz-Signature")
  valid_607817 = validateParameter(valid_607817, JString, required = false,
                                 default = nil)
  if valid_607817 != nil:
    section.add "X-Amz-Signature", valid_607817
  var valid_607818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607818 = validateParameter(valid_607818, JString, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "X-Amz-Content-Sha256", valid_607818
  var valid_607819 = header.getOrDefault("X-Amz-Date")
  valid_607819 = validateParameter(valid_607819, JString, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "X-Amz-Date", valid_607819
  var valid_607820 = header.getOrDefault("X-Amz-Credential")
  valid_607820 = validateParameter(valid_607820, JString, required = false,
                                 default = nil)
  if valid_607820 != nil:
    section.add "X-Amz-Credential", valid_607820
  var valid_607821 = header.getOrDefault("X-Amz-Security-Token")
  valid_607821 = validateParameter(valid_607821, JString, required = false,
                                 default = nil)
  if valid_607821 != nil:
    section.add "X-Amz-Security-Token", valid_607821
  var valid_607822 = header.getOrDefault("X-Amz-Algorithm")
  valid_607822 = validateParameter(valid_607822, JString, required = false,
                                 default = nil)
  if valid_607822 != nil:
    section.add "X-Amz-Algorithm", valid_607822
  var valid_607823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607823 = validateParameter(valid_607823, JString, required = false,
                                 default = nil)
  if valid_607823 != nil:
    section.add "X-Amz-SignedHeaders", valid_607823
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_607824 = formData.getOrDefault("DBClusterIdentifier")
  valid_607824 = validateParameter(valid_607824, JString, required = true,
                                 default = nil)
  if valid_607824 != nil:
    section.add "DBClusterIdentifier", valid_607824
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607825: Call_PostStartDBCluster_607812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_607825.validator(path, query, header, formData, body)
  let scheme = call_607825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607825.url(scheme.get, call_607825.host, call_607825.base,
                         call_607825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607825, url, valid)

proc call*(call_607826: Call_PostStartDBCluster_607812;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_607827 = newJObject()
  var formData_607828 = newJObject()
  add(query_607827, "Action", newJString(Action))
  add(query_607827, "Version", newJString(Version))
  add(formData_607828, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_607826.call(nil, query_607827, nil, formData_607828, nil)

var postStartDBCluster* = Call_PostStartDBCluster_607812(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_607813, base: "/",
    url: url_PostStartDBCluster_607814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_607796 = ref object of OpenApiRestCall_605573
proc url_GetStartDBCluster_607798(protocol: Scheme; host: string; base: string;
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

proc validate_GetStartDBCluster_607797(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_607799 = query.getOrDefault("DBClusterIdentifier")
  valid_607799 = validateParameter(valid_607799, JString, required = true,
                                 default = nil)
  if valid_607799 != nil:
    section.add "DBClusterIdentifier", valid_607799
  var valid_607800 = query.getOrDefault("Action")
  valid_607800 = validateParameter(valid_607800, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_607800 != nil:
    section.add "Action", valid_607800
  var valid_607801 = query.getOrDefault("Version")
  valid_607801 = validateParameter(valid_607801, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607801 != nil:
    section.add "Version", valid_607801
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607802 = header.getOrDefault("X-Amz-Signature")
  valid_607802 = validateParameter(valid_607802, JString, required = false,
                                 default = nil)
  if valid_607802 != nil:
    section.add "X-Amz-Signature", valid_607802
  var valid_607803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607803 = validateParameter(valid_607803, JString, required = false,
                                 default = nil)
  if valid_607803 != nil:
    section.add "X-Amz-Content-Sha256", valid_607803
  var valid_607804 = header.getOrDefault("X-Amz-Date")
  valid_607804 = validateParameter(valid_607804, JString, required = false,
                                 default = nil)
  if valid_607804 != nil:
    section.add "X-Amz-Date", valid_607804
  var valid_607805 = header.getOrDefault("X-Amz-Credential")
  valid_607805 = validateParameter(valid_607805, JString, required = false,
                                 default = nil)
  if valid_607805 != nil:
    section.add "X-Amz-Credential", valid_607805
  var valid_607806 = header.getOrDefault("X-Amz-Security-Token")
  valid_607806 = validateParameter(valid_607806, JString, required = false,
                                 default = nil)
  if valid_607806 != nil:
    section.add "X-Amz-Security-Token", valid_607806
  var valid_607807 = header.getOrDefault("X-Amz-Algorithm")
  valid_607807 = validateParameter(valid_607807, JString, required = false,
                                 default = nil)
  if valid_607807 != nil:
    section.add "X-Amz-Algorithm", valid_607807
  var valid_607808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607808 = validateParameter(valid_607808, JString, required = false,
                                 default = nil)
  if valid_607808 != nil:
    section.add "X-Amz-SignedHeaders", valid_607808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607809: Call_GetStartDBCluster_607796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_607809.validator(path, query, header, formData, body)
  let scheme = call_607809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607809.url(scheme.get, call_607809.host, call_607809.base,
                         call_607809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607809, url, valid)

proc call*(call_607810: Call_GetStartDBCluster_607796; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607811 = newJObject()
  add(query_607811, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_607811, "Action", newJString(Action))
  add(query_607811, "Version", newJString(Version))
  result = call_607810.call(nil, query_607811, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_607796(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_607797,
    base: "/", url: url_GetStartDBCluster_607798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_607845 = ref object of OpenApiRestCall_605573
proc url_PostStopDBCluster_607847(protocol: Scheme; host: string; base: string;
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

proc validate_PostStopDBCluster_607846(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607848 = query.getOrDefault("Action")
  valid_607848 = validateParameter(valid_607848, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_607848 != nil:
    section.add "Action", valid_607848
  var valid_607849 = query.getOrDefault("Version")
  valid_607849 = validateParameter(valid_607849, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607849 != nil:
    section.add "Version", valid_607849
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607850 = header.getOrDefault("X-Amz-Signature")
  valid_607850 = validateParameter(valid_607850, JString, required = false,
                                 default = nil)
  if valid_607850 != nil:
    section.add "X-Amz-Signature", valid_607850
  var valid_607851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607851 = validateParameter(valid_607851, JString, required = false,
                                 default = nil)
  if valid_607851 != nil:
    section.add "X-Amz-Content-Sha256", valid_607851
  var valid_607852 = header.getOrDefault("X-Amz-Date")
  valid_607852 = validateParameter(valid_607852, JString, required = false,
                                 default = nil)
  if valid_607852 != nil:
    section.add "X-Amz-Date", valid_607852
  var valid_607853 = header.getOrDefault("X-Amz-Credential")
  valid_607853 = validateParameter(valid_607853, JString, required = false,
                                 default = nil)
  if valid_607853 != nil:
    section.add "X-Amz-Credential", valid_607853
  var valid_607854 = header.getOrDefault("X-Amz-Security-Token")
  valid_607854 = validateParameter(valid_607854, JString, required = false,
                                 default = nil)
  if valid_607854 != nil:
    section.add "X-Amz-Security-Token", valid_607854
  var valid_607855 = header.getOrDefault("X-Amz-Algorithm")
  valid_607855 = validateParameter(valid_607855, JString, required = false,
                                 default = nil)
  if valid_607855 != nil:
    section.add "X-Amz-Algorithm", valid_607855
  var valid_607856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607856 = validateParameter(valid_607856, JString, required = false,
                                 default = nil)
  if valid_607856 != nil:
    section.add "X-Amz-SignedHeaders", valid_607856
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_607857 = formData.getOrDefault("DBClusterIdentifier")
  valid_607857 = validateParameter(valid_607857, JString, required = true,
                                 default = nil)
  if valid_607857 != nil:
    section.add "DBClusterIdentifier", valid_607857
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607858: Call_PostStopDBCluster_607845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_607858.validator(path, query, header, formData, body)
  let scheme = call_607858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607858.url(scheme.get, call_607858.host, call_607858.base,
                         call_607858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607858, url, valid)

proc call*(call_607859: Call_PostStopDBCluster_607845; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_607860 = newJObject()
  var formData_607861 = newJObject()
  add(query_607860, "Action", newJString(Action))
  add(query_607860, "Version", newJString(Version))
  add(formData_607861, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_607859.call(nil, query_607860, nil, formData_607861, nil)

var postStopDBCluster* = Call_PostStopDBCluster_607845(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_607846,
    base: "/", url: url_PostStopDBCluster_607847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_607829 = ref object of OpenApiRestCall_605573
proc url_GetStopDBCluster_607831(protocol: Scheme; host: string; base: string;
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

proc validate_GetStopDBCluster_607830(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_607832 = query.getOrDefault("DBClusterIdentifier")
  valid_607832 = validateParameter(valid_607832, JString, required = true,
                                 default = nil)
  if valid_607832 != nil:
    section.add "DBClusterIdentifier", valid_607832
  var valid_607833 = query.getOrDefault("Action")
  valid_607833 = validateParameter(valid_607833, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_607833 != nil:
    section.add "Action", valid_607833
  var valid_607834 = query.getOrDefault("Version")
  valid_607834 = validateParameter(valid_607834, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_607834 != nil:
    section.add "Version", valid_607834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607835 = header.getOrDefault("X-Amz-Signature")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "X-Amz-Signature", valid_607835
  var valid_607836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-Content-Sha256", valid_607836
  var valid_607837 = header.getOrDefault("X-Amz-Date")
  valid_607837 = validateParameter(valid_607837, JString, required = false,
                                 default = nil)
  if valid_607837 != nil:
    section.add "X-Amz-Date", valid_607837
  var valid_607838 = header.getOrDefault("X-Amz-Credential")
  valid_607838 = validateParameter(valid_607838, JString, required = false,
                                 default = nil)
  if valid_607838 != nil:
    section.add "X-Amz-Credential", valid_607838
  var valid_607839 = header.getOrDefault("X-Amz-Security-Token")
  valid_607839 = validateParameter(valid_607839, JString, required = false,
                                 default = nil)
  if valid_607839 != nil:
    section.add "X-Amz-Security-Token", valid_607839
  var valid_607840 = header.getOrDefault("X-Amz-Algorithm")
  valid_607840 = validateParameter(valid_607840, JString, required = false,
                                 default = nil)
  if valid_607840 != nil:
    section.add "X-Amz-Algorithm", valid_607840
  var valid_607841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607841 = validateParameter(valid_607841, JString, required = false,
                                 default = nil)
  if valid_607841 != nil:
    section.add "X-Amz-SignedHeaders", valid_607841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607842: Call_GetStopDBCluster_607829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_607842.validator(path, query, header, formData, body)
  let scheme = call_607842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607842.url(scheme.get, call_607842.host, call_607842.base,
                         call_607842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607842, url, valid)

proc call*(call_607843: Call_GetStopDBCluster_607829; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607844 = newJObject()
  add(query_607844, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_607844, "Action", newJString(Action))
  add(query_607844, "Version", newJString(Version))
  result = call_607843.call(nil, query_607844, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_607829(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_607830,
    base: "/", url: url_GetStopDBCluster_607831,
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

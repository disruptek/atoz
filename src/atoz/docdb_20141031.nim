
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

  OpenApiRestCall_610642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610642): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  Call_PostAddTagsToResource_611252 = ref object of OpenApiRestCall_610642
proc url_PostAddTagsToResource_611254(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTagsToResource_611253(path: JsonNode; query: JsonNode;
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
  var valid_611255 = query.getOrDefault("Action")
  valid_611255 = validateParameter(valid_611255, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_611255 != nil:
    section.add "Action", valid_611255
  var valid_611256 = query.getOrDefault("Version")
  valid_611256 = validateParameter(valid_611256, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611256 != nil:
    section.add "Version", valid_611256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611257 = header.getOrDefault("X-Amz-Signature")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Signature", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Content-Sha256", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Date")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Date", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Credential")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Credential", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Security-Token")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Security-Token", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Algorithm")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Algorithm", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-SignedHeaders", valid_611263
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_611264 = formData.getOrDefault("Tags")
  valid_611264 = validateParameter(valid_611264, JArray, required = true, default = nil)
  if valid_611264 != nil:
    section.add "Tags", valid_611264
  var valid_611265 = formData.getOrDefault("ResourceName")
  valid_611265 = validateParameter(valid_611265, JString, required = true,
                                 default = nil)
  if valid_611265 != nil:
    section.add "ResourceName", valid_611265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611266: Call_PostAddTagsToResource_611252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_611266.validator(path, query, header, formData, body)
  let scheme = call_611266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611266.url(scheme.get, call_611266.host, call_611266.base,
                         call_611266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611266, url, valid)

proc call*(call_611267: Call_PostAddTagsToResource_611252; Tags: JsonNode;
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
  var query_611268 = newJObject()
  var formData_611269 = newJObject()
  add(query_611268, "Action", newJString(Action))
  if Tags != nil:
    formData_611269.add "Tags", Tags
  add(query_611268, "Version", newJString(Version))
  add(formData_611269, "ResourceName", newJString(ResourceName))
  result = call_611267.call(nil, query_611268, nil, formData_611269, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_611252(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_611253, base: "/",
    url: url_PostAddTagsToResource_611254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_610980 = ref object of OpenApiRestCall_610642
proc url_GetAddTagsToResource_610982(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTagsToResource_610981(path: JsonNode; query: JsonNode;
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
  var valid_611094 = query.getOrDefault("Tags")
  valid_611094 = validateParameter(valid_611094, JArray, required = true, default = nil)
  if valid_611094 != nil:
    section.add "Tags", valid_611094
  var valid_611095 = query.getOrDefault("ResourceName")
  valid_611095 = validateParameter(valid_611095, JString, required = true,
                                 default = nil)
  if valid_611095 != nil:
    section.add "ResourceName", valid_611095
  var valid_611109 = query.getOrDefault("Action")
  valid_611109 = validateParameter(valid_611109, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_611109 != nil:
    section.add "Action", valid_611109
  var valid_611110 = query.getOrDefault("Version")
  valid_611110 = validateParameter(valid_611110, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611110 != nil:
    section.add "Version", valid_611110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611111 = header.getOrDefault("X-Amz-Signature")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Signature", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Content-Sha256", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Date")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Date", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Credential")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Credential", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Security-Token")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Security-Token", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Algorithm")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Algorithm", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-SignedHeaders", valid_611117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611140: Call_GetAddTagsToResource_610980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_611140.validator(path, query, header, formData, body)
  let scheme = call_611140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611140.url(scheme.get, call_611140.host, call_611140.base,
                         call_611140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611140, url, valid)

proc call*(call_611211: Call_GetAddTagsToResource_610980; Tags: JsonNode;
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
  var query_611212 = newJObject()
  if Tags != nil:
    query_611212.add "Tags", Tags
  add(query_611212, "ResourceName", newJString(ResourceName))
  add(query_611212, "Action", newJString(Action))
  add(query_611212, "Version", newJString(Version))
  result = call_611211.call(nil, query_611212, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_610980(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_610981, base: "/",
    url: url_GetAddTagsToResource_610982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_611288 = ref object of OpenApiRestCall_610642
proc url_PostApplyPendingMaintenanceAction_611290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplyPendingMaintenanceAction_611289(path: JsonNode;
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
  var valid_611291 = query.getOrDefault("Action")
  valid_611291 = validateParameter(valid_611291, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_611291 != nil:
    section.add "Action", valid_611291
  var valid_611292 = query.getOrDefault("Version")
  valid_611292 = validateParameter(valid_611292, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611292 != nil:
    section.add "Version", valid_611292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611293 = header.getOrDefault("X-Amz-Signature")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Signature", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Content-Sha256", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Date")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Date", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Credential")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Credential", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Security-Token")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Security-Token", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Algorithm")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Algorithm", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-SignedHeaders", valid_611299
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
  var valid_611300 = formData.getOrDefault("ResourceIdentifier")
  valid_611300 = validateParameter(valid_611300, JString, required = true,
                                 default = nil)
  if valid_611300 != nil:
    section.add "ResourceIdentifier", valid_611300
  var valid_611301 = formData.getOrDefault("ApplyAction")
  valid_611301 = validateParameter(valid_611301, JString, required = true,
                                 default = nil)
  if valid_611301 != nil:
    section.add "ApplyAction", valid_611301
  var valid_611302 = formData.getOrDefault("OptInType")
  valid_611302 = validateParameter(valid_611302, JString, required = true,
                                 default = nil)
  if valid_611302 != nil:
    section.add "OptInType", valid_611302
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611303: Call_PostApplyPendingMaintenanceAction_611288;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_611303.validator(path, query, header, formData, body)
  let scheme = call_611303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611303.url(scheme.get, call_611303.host, call_611303.base,
                         call_611303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611303, url, valid)

proc call*(call_611304: Call_PostApplyPendingMaintenanceAction_611288;
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
  var query_611305 = newJObject()
  var formData_611306 = newJObject()
  add(formData_611306, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_611306, "ApplyAction", newJString(ApplyAction))
  add(query_611305, "Action", newJString(Action))
  add(formData_611306, "OptInType", newJString(OptInType))
  add(query_611305, "Version", newJString(Version))
  result = call_611304.call(nil, query_611305, nil, formData_611306, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_611288(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_611289, base: "/",
    url: url_PostApplyPendingMaintenanceAction_611290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_611270 = ref object of OpenApiRestCall_610642
proc url_GetApplyPendingMaintenanceAction_611272(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplyPendingMaintenanceAction_611271(path: JsonNode;
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
  var valid_611273 = query.getOrDefault("ResourceIdentifier")
  valid_611273 = validateParameter(valid_611273, JString, required = true,
                                 default = nil)
  if valid_611273 != nil:
    section.add "ResourceIdentifier", valid_611273
  var valid_611274 = query.getOrDefault("ApplyAction")
  valid_611274 = validateParameter(valid_611274, JString, required = true,
                                 default = nil)
  if valid_611274 != nil:
    section.add "ApplyAction", valid_611274
  var valid_611275 = query.getOrDefault("Action")
  valid_611275 = validateParameter(valid_611275, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_611275 != nil:
    section.add "Action", valid_611275
  var valid_611276 = query.getOrDefault("OptInType")
  valid_611276 = validateParameter(valid_611276, JString, required = true,
                                 default = nil)
  if valid_611276 != nil:
    section.add "OptInType", valid_611276
  var valid_611277 = query.getOrDefault("Version")
  valid_611277 = validateParameter(valid_611277, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611277 != nil:
    section.add "Version", valid_611277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611278 = header.getOrDefault("X-Amz-Signature")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Signature", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Content-Sha256", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Date")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Date", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-Credential")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-Credential", valid_611281
  var valid_611282 = header.getOrDefault("X-Amz-Security-Token")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Security-Token", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-Algorithm")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Algorithm", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-SignedHeaders", valid_611284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611285: Call_GetApplyPendingMaintenanceAction_611270;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_611285.validator(path, query, header, formData, body)
  let scheme = call_611285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611285.url(scheme.get, call_611285.host, call_611285.base,
                         call_611285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611285, url, valid)

proc call*(call_611286: Call_GetApplyPendingMaintenanceAction_611270;
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
  var query_611287 = newJObject()
  add(query_611287, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_611287, "ApplyAction", newJString(ApplyAction))
  add(query_611287, "Action", newJString(Action))
  add(query_611287, "OptInType", newJString(OptInType))
  add(query_611287, "Version", newJString(Version))
  result = call_611286.call(nil, query_611287, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_611270(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_611271, base: "/",
    url: url_GetApplyPendingMaintenanceAction_611272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_611326 = ref object of OpenApiRestCall_610642
proc url_PostCopyDBClusterParameterGroup_611328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBClusterParameterGroup_611327(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Copies the specified cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611329 = query.getOrDefault("Action")
  valid_611329 = validateParameter(valid_611329, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_611329 != nil:
    section.add "Action", valid_611329
  var valid_611330 = query.getOrDefault("Version")
  valid_611330 = validateParameter(valid_611330, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611330 != nil:
    section.add "Version", valid_611330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611331 = header.getOrDefault("X-Amz-Signature")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Signature", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Content-Sha256", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Date")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Date", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Credential")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Credential", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Security-Token")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Security-Token", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Algorithm")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Algorithm", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-SignedHeaders", valid_611337
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid cluster parameter group.</p> </li> <li> <p>If the source cluster parameter group is in the same AWS Region as the copy, specify a valid parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source parameter group is in a different AWS Region than the copy, specify a valid cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied cluster parameter group.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBClusterParameterGroupIdentifier` field"
  var valid_611338 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_611338 = validateParameter(valid_611338, JString, required = true,
                                 default = nil)
  if valid_611338 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_611338
  var valid_611339 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_611339 = validateParameter(valid_611339, JString, required = true,
                                 default = nil)
  if valid_611339 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_611339
  var valid_611340 = formData.getOrDefault("Tags")
  valid_611340 = validateParameter(valid_611340, JArray, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "Tags", valid_611340
  var valid_611341 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_611341 = validateParameter(valid_611341, JString, required = true,
                                 default = nil)
  if valid_611341 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_611341
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611342: Call_PostCopyDBClusterParameterGroup_611326;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified cluster parameter group.
  ## 
  let valid = call_611342.validator(path, query, header, formData, body)
  let scheme = call_611342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611342.url(scheme.get, call_611342.host, call_611342.base,
                         call_611342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611342, url, valid)

proc call*(call_611343: Call_PostCopyDBClusterParameterGroup_611326;
          TargetDBClusterParameterGroupIdentifier: string;
          SourceDBClusterParameterGroupIdentifier: string;
          TargetDBClusterParameterGroupDescription: string;
          Action: string = "CopyDBClusterParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterParameterGroup
  ## Copies the specified cluster parameter group.
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid cluster parameter group.</p> </li> <li> <p>If the source cluster parameter group is in the same AWS Region as the copy, specify a valid parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source parameter group is in a different AWS Region than the copy, specify a valid cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   Version: string (required)
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied cluster parameter group.
  var query_611344 = newJObject()
  var formData_611345 = newJObject()
  add(formData_611345, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(formData_611345, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_611344, "Action", newJString(Action))
  if Tags != nil:
    formData_611345.add "Tags", Tags
  add(query_611344, "Version", newJString(Version))
  add(formData_611345, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  result = call_611343.call(nil, query_611344, nil, formData_611345, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_611326(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_611327, base: "/",
    url: url_PostCopyDBClusterParameterGroup_611328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_611307 = ref object of OpenApiRestCall_610642
proc url_GetCopyDBClusterParameterGroup_611309(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBClusterParameterGroup_611308(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Copies the specified cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Action: JString (required)
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid cluster parameter group.</p> </li> <li> <p>If the source cluster parameter group is in the same AWS Region as the copy, specify a valid parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source parameter group is in a different AWS Region than the copy, specify a valid cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TargetDBClusterParameterGroupDescription` field"
  var valid_611310 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_611310 = validateParameter(valid_611310, JString, required = true,
                                 default = nil)
  if valid_611310 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_611310
  var valid_611311 = query.getOrDefault("Tags")
  valid_611311 = validateParameter(valid_611311, JArray, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "Tags", valid_611311
  var valid_611312 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_611312 = validateParameter(valid_611312, JString, required = true,
                                 default = nil)
  if valid_611312 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_611312
  var valid_611313 = query.getOrDefault("Action")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_611313 != nil:
    section.add "Action", valid_611313
  var valid_611314 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_611314 = validateParameter(valid_611314, JString, required = true,
                                 default = nil)
  if valid_611314 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_611314
  var valid_611315 = query.getOrDefault("Version")
  valid_611315 = validateParameter(valid_611315, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611315 != nil:
    section.add "Version", valid_611315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611316 = header.getOrDefault("X-Amz-Signature")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Signature", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Content-Sha256", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Date")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Date", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Credential")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Credential", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Security-Token")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Security-Token", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Algorithm")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Algorithm", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-SignedHeaders", valid_611322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611323: Call_GetCopyDBClusterParameterGroup_611307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified cluster parameter group.
  ## 
  let valid = call_611323.validator(path, query, header, formData, body)
  let scheme = call_611323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611323.url(scheme.get, call_611323.host, call_611323.base,
                         call_611323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611323, url, valid)

proc call*(call_611324: Call_GetCopyDBClusterParameterGroup_611307;
          TargetDBClusterParameterGroupDescription: string;
          TargetDBClusterParameterGroupIdentifier: string;
          SourceDBClusterParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCopyDBClusterParameterGroup
  ## Copies the specified cluster parameter group.
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Action: string (required)
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid cluster parameter group.</p> </li> <li> <p>If the source cluster parameter group is in the same AWS Region as the copy, specify a valid parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source parameter group is in a different AWS Region than the copy, specify a valid cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_611325 = newJObject()
  add(query_611325, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    query_611325.add "Tags", Tags
  add(query_611325, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_611325, "Action", newJString(Action))
  add(query_611325, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_611325, "Version", newJString(Version))
  result = call_611324.call(nil, query_611325, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_611307(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_611308, base: "/",
    url: url_GetCopyDBClusterParameterGroup_611309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_611367 = ref object of OpenApiRestCall_610642
proc url_PostCopyDBClusterSnapshot_611369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBClusterSnapshot_611368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611370 = query.getOrDefault("Action")
  valid_611370 = validateParameter(valid_611370, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_611370 != nil:
    section.add "Action", valid_611370
  var valid_611371 = query.getOrDefault("Version")
  valid_611371 = validateParameter(valid_611371, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611371 != nil:
    section.add "Version", valid_611371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611372 = header.getOrDefault("X-Amz-Signature")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Signature", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Content-Sha256", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Date")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Date", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Credential")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Credential", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Security-Token")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Security-Token", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Algorithm")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Algorithm", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-SignedHeaders", valid_611378
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The cluster snapshot identifier for the encrypted cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new cluster snapshot to create from the source cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_611379 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_611379 = validateParameter(valid_611379, JString, required = true,
                                 default = nil)
  if valid_611379 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_611379
  var valid_611380 = formData.getOrDefault("KmsKeyId")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "KmsKeyId", valid_611380
  var valid_611381 = formData.getOrDefault("PreSignedUrl")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "PreSignedUrl", valid_611381
  var valid_611382 = formData.getOrDefault("CopyTags")
  valid_611382 = validateParameter(valid_611382, JBool, required = false, default = nil)
  if valid_611382 != nil:
    section.add "CopyTags", valid_611382
  var valid_611383 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_611383 = validateParameter(valid_611383, JString, required = true,
                                 default = nil)
  if valid_611383 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_611383
  var valid_611384 = formData.getOrDefault("Tags")
  valid_611384 = validateParameter(valid_611384, JArray, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "Tags", valid_611384
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611385: Call_PostCopyDBClusterSnapshot_611367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_611385.validator(path, query, header, formData, body)
  let scheme = call_611385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611385.url(scheme.get, call_611385.host, call_611385.base,
                         call_611385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611385, url, valid)

proc call*(call_611386: Call_PostCopyDBClusterSnapshot_611367;
          SourceDBClusterSnapshotIdentifier: string;
          TargetDBClusterSnapshotIdentifier: string; KmsKeyId: string = "";
          PreSignedUrl: string = ""; CopyTags: bool = false;
          Action: string = "CopyDBClusterSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The cluster snapshot identifier for the encrypted cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new cluster snapshot to create from the source cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   Version: string (required)
  var query_611387 = newJObject()
  var formData_611388 = newJObject()
  add(formData_611388, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_611388, "KmsKeyId", newJString(KmsKeyId))
  add(formData_611388, "PreSignedUrl", newJString(PreSignedUrl))
  add(formData_611388, "CopyTags", newJBool(CopyTags))
  add(formData_611388, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_611387, "Action", newJString(Action))
  if Tags != nil:
    formData_611388.add "Tags", Tags
  add(query_611387, "Version", newJString(Version))
  result = call_611386.call(nil, query_611387, nil, formData_611388, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_611367(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_611368, base: "/",
    url: url_PostCopyDBClusterSnapshot_611369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_611346 = ref object of OpenApiRestCall_610642
proc url_GetCopyDBClusterSnapshot_611348(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBClusterSnapshot_611347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The cluster snapshot identifier for the encrypted cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new cluster snapshot to create from the source cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Action: JString (required)
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_611349 = query.getOrDefault("Tags")
  valid_611349 = validateParameter(valid_611349, JArray, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "Tags", valid_611349
  var valid_611350 = query.getOrDefault("KmsKeyId")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "KmsKeyId", valid_611350
  var valid_611351 = query.getOrDefault("PreSignedUrl")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "PreSignedUrl", valid_611351
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_611352 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = nil)
  if valid_611352 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_611352
  var valid_611353 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_611353 = validateParameter(valid_611353, JString, required = true,
                                 default = nil)
  if valid_611353 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_611353
  var valid_611354 = query.getOrDefault("Action")
  valid_611354 = validateParameter(valid_611354, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_611354 != nil:
    section.add "Action", valid_611354
  var valid_611355 = query.getOrDefault("CopyTags")
  valid_611355 = validateParameter(valid_611355, JBool, required = false, default = nil)
  if valid_611355 != nil:
    section.add "CopyTags", valid_611355
  var valid_611356 = query.getOrDefault("Version")
  valid_611356 = validateParameter(valid_611356, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611356 != nil:
    section.add "Version", valid_611356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611357 = header.getOrDefault("X-Amz-Signature")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Signature", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Content-Sha256", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Date")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Date", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Credential")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Credential", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Security-Token")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Security-Token", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Algorithm")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Algorithm", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-SignedHeaders", valid_611363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611364: Call_GetCopyDBClusterSnapshot_611346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_611364.validator(path, query, header, formData, body)
  let scheme = call_611364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611364.url(scheme.get, call_611364.host, call_611364.base,
                         call_611364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611364, url, valid)

proc call*(call_611365: Call_GetCopyDBClusterSnapshot_611346;
          TargetDBClusterSnapshotIdentifier: string;
          SourceDBClusterSnapshotIdentifier: string; Tags: JsonNode = nil;
          KmsKeyId: string = ""; PreSignedUrl: string = "";
          Action: string = "CopyDBClusterSnapshot"; CopyTags: bool = false;
          Version: string = "2014-10-31"): Recallable =
  ## getCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The cluster snapshot identifier for the encrypted cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new cluster snapshot to create from the source cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Action: string (required)
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Version: string (required)
  var query_611366 = newJObject()
  if Tags != nil:
    query_611366.add "Tags", Tags
  add(query_611366, "KmsKeyId", newJString(KmsKeyId))
  add(query_611366, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_611366, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_611366, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_611366, "Action", newJString(Action))
  add(query_611366, "CopyTags", newJBool(CopyTags))
  add(query_611366, "Version", newJString(Version))
  result = call_611365.call(nil, query_611366, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_611346(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_611347, base: "/",
    url: url_GetCopyDBClusterSnapshot_611348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_611422 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBCluster_611424(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBCluster_611423(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611425 = query.getOrDefault("Action")
  valid_611425 = validateParameter(valid_611425, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_611425 != nil:
    section.add "Action", valid_611425
  var valid_611426 = query.getOrDefault("Version")
  valid_611426 = validateParameter(valid_611426, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611426 != nil:
    section.add "Version", valid_611426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611427 = header.getOrDefault("X-Amz-Signature")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Signature", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Content-Sha256", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Date")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Date", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Credential")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Credential", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Security-Token")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Security-Token", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Algorithm")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Algorithm", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-SignedHeaders", valid_611433
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : The port number on which the instances in the cluster accept connections.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   DBSubnetGroupName: JString
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the cluster is encrypted.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  section = newJObject()
  var valid_611434 = formData.getOrDefault("Port")
  valid_611434 = validateParameter(valid_611434, JInt, required = false, default = nil)
  if valid_611434 != nil:
    section.add "Port", valid_611434
  var valid_611435 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "PreferredMaintenanceWindow", valid_611435
  var valid_611436 = formData.getOrDefault("PreferredBackupWindow")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "PreferredBackupWindow", valid_611436
  assert formData != nil, "formData argument is necessary due to required `MasterUserPassword` field"
  var valid_611437 = formData.getOrDefault("MasterUserPassword")
  valid_611437 = validateParameter(valid_611437, JString, required = true,
                                 default = nil)
  if valid_611437 != nil:
    section.add "MasterUserPassword", valid_611437
  var valid_611438 = formData.getOrDefault("MasterUsername")
  valid_611438 = validateParameter(valid_611438, JString, required = true,
                                 default = nil)
  if valid_611438 != nil:
    section.add "MasterUsername", valid_611438
  var valid_611439 = formData.getOrDefault("EngineVersion")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "EngineVersion", valid_611439
  var valid_611440 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_611440 = validateParameter(valid_611440, JArray, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "VpcSecurityGroupIds", valid_611440
  var valid_611441 = formData.getOrDefault("AvailabilityZones")
  valid_611441 = validateParameter(valid_611441, JArray, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "AvailabilityZones", valid_611441
  var valid_611442 = formData.getOrDefault("BackupRetentionPeriod")
  valid_611442 = validateParameter(valid_611442, JInt, required = false, default = nil)
  if valid_611442 != nil:
    section.add "BackupRetentionPeriod", valid_611442
  var valid_611443 = formData.getOrDefault("Engine")
  valid_611443 = validateParameter(valid_611443, JString, required = true,
                                 default = nil)
  if valid_611443 != nil:
    section.add "Engine", valid_611443
  var valid_611444 = formData.getOrDefault("KmsKeyId")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "KmsKeyId", valid_611444
  var valid_611445 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_611445 = validateParameter(valid_611445, JArray, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "EnableCloudwatchLogsExports", valid_611445
  var valid_611446 = formData.getOrDefault("Tags")
  valid_611446 = validateParameter(valid_611446, JArray, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "Tags", valid_611446
  var valid_611447 = formData.getOrDefault("DBSubnetGroupName")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "DBSubnetGroupName", valid_611447
  var valid_611448 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "DBClusterParameterGroupName", valid_611448
  var valid_611449 = formData.getOrDefault("StorageEncrypted")
  valid_611449 = validateParameter(valid_611449, JBool, required = false, default = nil)
  if valid_611449 != nil:
    section.add "StorageEncrypted", valid_611449
  var valid_611450 = formData.getOrDefault("DBClusterIdentifier")
  valid_611450 = validateParameter(valid_611450, JString, required = true,
                                 default = nil)
  if valid_611450 != nil:
    section.add "DBClusterIdentifier", valid_611450
  var valid_611451 = formData.getOrDefault("DeletionProtection")
  valid_611451 = validateParameter(valid_611451, JBool, required = false, default = nil)
  if valid_611451 != nil:
    section.add "DeletionProtection", valid_611451
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611452: Call_PostCreateDBCluster_611422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  let valid = call_611452.validator(path, query, header, formData, body)
  let scheme = call_611452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611452.url(scheme.get, call_611452.host, call_611452.base,
                         call_611452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611452, url, valid)

proc call*(call_611453: Call_PostCreateDBCluster_611422;
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
  ## Creates a new Amazon DocumentDB cluster.
  ##   Port: int
  ##       : The port number on which the instances in the cluster accept connections.
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   DBSubnetGroupName: string
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   Version: string (required)
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the cluster is encrypted.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  var query_611454 = newJObject()
  var formData_611455 = newJObject()
  add(formData_611455, "Port", newJInt(Port))
  add(formData_611455, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_611455, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_611455, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_611455, "MasterUsername", newJString(MasterUsername))
  add(formData_611455, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_611455.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_611455.add "AvailabilityZones", AvailabilityZones
  add(formData_611455, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_611455, "Engine", newJString(Engine))
  add(formData_611455, "KmsKeyId", newJString(KmsKeyId))
  if EnableCloudwatchLogsExports != nil:
    formData_611455.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_611454, "Action", newJString(Action))
  if Tags != nil:
    formData_611455.add "Tags", Tags
  add(formData_611455, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_611455, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_611454, "Version", newJString(Version))
  add(formData_611455, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_611455, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_611455, "DeletionProtection", newJBool(DeletionProtection))
  result = call_611453.call(nil, query_611454, nil, formData_611455, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_611422(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_611423, base: "/",
    url: url_PostCreateDBCluster_611424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_611389 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBCluster_611391(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBCluster_611390(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the cluster is encrypted.
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   Action: JString (required)
  ##   Port: JInt
  ##       : The port number on which the instances in the cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DBSubnetGroupName: JString
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_611392 = query.getOrDefault("StorageEncrypted")
  valid_611392 = validateParameter(valid_611392, JBool, required = false, default = nil)
  if valid_611392 != nil:
    section.add "StorageEncrypted", valid_611392
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_611393 = query.getOrDefault("Engine")
  valid_611393 = validateParameter(valid_611393, JString, required = true,
                                 default = nil)
  if valid_611393 != nil:
    section.add "Engine", valid_611393
  var valid_611394 = query.getOrDefault("DeletionProtection")
  valid_611394 = validateParameter(valid_611394, JBool, required = false, default = nil)
  if valid_611394 != nil:
    section.add "DeletionProtection", valid_611394
  var valid_611395 = query.getOrDefault("Tags")
  valid_611395 = validateParameter(valid_611395, JArray, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "Tags", valid_611395
  var valid_611396 = query.getOrDefault("KmsKeyId")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "KmsKeyId", valid_611396
  var valid_611397 = query.getOrDefault("DBClusterIdentifier")
  valid_611397 = validateParameter(valid_611397, JString, required = true,
                                 default = nil)
  if valid_611397 != nil:
    section.add "DBClusterIdentifier", valid_611397
  var valid_611398 = query.getOrDefault("DBClusterParameterGroupName")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "DBClusterParameterGroupName", valid_611398
  var valid_611399 = query.getOrDefault("AvailabilityZones")
  valid_611399 = validateParameter(valid_611399, JArray, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "AvailabilityZones", valid_611399
  var valid_611400 = query.getOrDefault("MasterUsername")
  valid_611400 = validateParameter(valid_611400, JString, required = true,
                                 default = nil)
  if valid_611400 != nil:
    section.add "MasterUsername", valid_611400
  var valid_611401 = query.getOrDefault("BackupRetentionPeriod")
  valid_611401 = validateParameter(valid_611401, JInt, required = false, default = nil)
  if valid_611401 != nil:
    section.add "BackupRetentionPeriod", valid_611401
  var valid_611402 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_611402 = validateParameter(valid_611402, JArray, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "EnableCloudwatchLogsExports", valid_611402
  var valid_611403 = query.getOrDefault("EngineVersion")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "EngineVersion", valid_611403
  var valid_611404 = query.getOrDefault("Action")
  valid_611404 = validateParameter(valid_611404, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_611404 != nil:
    section.add "Action", valid_611404
  var valid_611405 = query.getOrDefault("Port")
  valid_611405 = validateParameter(valid_611405, JInt, required = false, default = nil)
  if valid_611405 != nil:
    section.add "Port", valid_611405
  var valid_611406 = query.getOrDefault("VpcSecurityGroupIds")
  valid_611406 = validateParameter(valid_611406, JArray, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "VpcSecurityGroupIds", valid_611406
  var valid_611407 = query.getOrDefault("MasterUserPassword")
  valid_611407 = validateParameter(valid_611407, JString, required = true,
                                 default = nil)
  if valid_611407 != nil:
    section.add "MasterUserPassword", valid_611407
  var valid_611408 = query.getOrDefault("DBSubnetGroupName")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "DBSubnetGroupName", valid_611408
  var valid_611409 = query.getOrDefault("PreferredBackupWindow")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "PreferredBackupWindow", valid_611409
  var valid_611410 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "PreferredMaintenanceWindow", valid_611410
  var valid_611411 = query.getOrDefault("Version")
  valid_611411 = validateParameter(valid_611411, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611411 != nil:
    section.add "Version", valid_611411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611412 = header.getOrDefault("X-Amz-Signature")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Signature", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Content-Sha256", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Date")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Date", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Credential")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Credential", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Security-Token")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Security-Token", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Algorithm")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Algorithm", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-SignedHeaders", valid_611418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611419: Call_GetCreateDBCluster_611389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  let valid = call_611419.validator(path, query, header, formData, body)
  let scheme = call_611419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611419.url(scheme.get, call_611419.host, call_611419.base,
                         call_611419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611419, url, valid)

proc call*(call_611420: Call_GetCreateDBCluster_611389; Engine: string;
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
  ## Creates a new Amazon DocumentDB cluster.
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the cluster is encrypted.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   Action: string (required)
  ##   Port: int
  ##       : The port number on which the instances in the cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DBSubnetGroupName: string
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   Version: string (required)
  var query_611421 = newJObject()
  add(query_611421, "StorageEncrypted", newJBool(StorageEncrypted))
  add(query_611421, "Engine", newJString(Engine))
  add(query_611421, "DeletionProtection", newJBool(DeletionProtection))
  if Tags != nil:
    query_611421.add "Tags", Tags
  add(query_611421, "KmsKeyId", newJString(KmsKeyId))
  add(query_611421, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_611421, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if AvailabilityZones != nil:
    query_611421.add "AvailabilityZones", AvailabilityZones
  add(query_611421, "MasterUsername", newJString(MasterUsername))
  add(query_611421, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if EnableCloudwatchLogsExports != nil:
    query_611421.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_611421, "EngineVersion", newJString(EngineVersion))
  add(query_611421, "Action", newJString(Action))
  add(query_611421, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_611421.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_611421, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_611421, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611421, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_611421, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_611421, "Version", newJString(Version))
  result = call_611420.call(nil, query_611421, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_611389(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_611390,
    base: "/", url: url_GetCreateDBCluster_611391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_611475 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBClusterParameterGroup_611477(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBClusterParameterGroup_611476(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611478 = query.getOrDefault("Action")
  valid_611478 = validateParameter(valid_611478, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_611478 != nil:
    section.add "Action", valid_611478
  var valid_611479 = query.getOrDefault("Version")
  valid_611479 = validateParameter(valid_611479, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611479 != nil:
    section.add "Version", valid_611479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611480 = header.getOrDefault("X-Amz-Signature")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Signature", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Content-Sha256", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Date")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Date", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Credential")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Credential", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Security-Token")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Security-Token", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Algorithm")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Algorithm", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-SignedHeaders", valid_611486
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##              : The description for the cluster parameter group.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster parameter group.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The cluster parameter group family name.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_611487 = formData.getOrDefault("Description")
  valid_611487 = validateParameter(valid_611487, JString, required = true,
                                 default = nil)
  if valid_611487 != nil:
    section.add "Description", valid_611487
  var valid_611488 = formData.getOrDefault("Tags")
  valid_611488 = validateParameter(valid_611488, JArray, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "Tags", valid_611488
  var valid_611489 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_611489 = validateParameter(valid_611489, JString, required = true,
                                 default = nil)
  if valid_611489 != nil:
    section.add "DBClusterParameterGroupName", valid_611489
  var valid_611490 = formData.getOrDefault("DBParameterGroupFamily")
  valid_611490 = validateParameter(valid_611490, JString, required = true,
                                 default = nil)
  if valid_611490 != nil:
    section.add "DBParameterGroupFamily", valid_611490
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611491: Call_PostCreateDBClusterParameterGroup_611475;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_611491.validator(path, query, header, formData, body)
  let scheme = call_611491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611491.url(scheme.get, call_611491.host, call_611491.base,
                         call_611491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611491, url, valid)

proc call*(call_611492: Call_PostCreateDBClusterParameterGroup_611475;
          Description: string; DBClusterParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBClusterParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterParameterGroup
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Description: string (required)
  ##              : The description for the cluster parameter group.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster parameter group.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##                         : The cluster parameter group family name.
  var query_611493 = newJObject()
  var formData_611494 = newJObject()
  add(formData_611494, "Description", newJString(Description))
  add(query_611493, "Action", newJString(Action))
  if Tags != nil:
    formData_611494.add "Tags", Tags
  add(formData_611494, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_611493, "Version", newJString(Version))
  add(formData_611494, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_611492.call(nil, query_611493, nil, formData_611494, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_611475(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_611476, base: "/",
    url: url_PostCreateDBClusterParameterGroup_611477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_611456 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBClusterParameterGroup_611458(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBClusterParameterGroup_611457(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster parameter group.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Action: JString (required)
  ##   Description: JString (required)
  ##              : The description for the cluster parameter group.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_611459 = query.getOrDefault("DBParameterGroupFamily")
  valid_611459 = validateParameter(valid_611459, JString, required = true,
                                 default = nil)
  if valid_611459 != nil:
    section.add "DBParameterGroupFamily", valid_611459
  var valid_611460 = query.getOrDefault("Tags")
  valid_611460 = validateParameter(valid_611460, JArray, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "Tags", valid_611460
  var valid_611461 = query.getOrDefault("DBClusterParameterGroupName")
  valid_611461 = validateParameter(valid_611461, JString, required = true,
                                 default = nil)
  if valid_611461 != nil:
    section.add "DBClusterParameterGroupName", valid_611461
  var valid_611462 = query.getOrDefault("Action")
  valid_611462 = validateParameter(valid_611462, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_611462 != nil:
    section.add "Action", valid_611462
  var valid_611463 = query.getOrDefault("Description")
  valid_611463 = validateParameter(valid_611463, JString, required = true,
                                 default = nil)
  if valid_611463 != nil:
    section.add "Description", valid_611463
  var valid_611464 = query.getOrDefault("Version")
  valid_611464 = validateParameter(valid_611464, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611464 != nil:
    section.add "Version", valid_611464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611465 = header.getOrDefault("X-Amz-Signature")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Signature", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Content-Sha256", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Date")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Date", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Credential")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Credential", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Security-Token")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Security-Token", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Algorithm")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Algorithm", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-SignedHeaders", valid_611471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_GetCreateDBClusterParameterGroup_611456;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_GetCreateDBClusterParameterGroup_611456;
          DBParameterGroupFamily: string; DBClusterParameterGroupName: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterParameterGroup
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   DBParameterGroupFamily: string (required)
  ##                         : The cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster parameter group.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Action: string (required)
  ##   Description: string (required)
  ##              : The description for the cluster parameter group.
  ##   Version: string (required)
  var query_611474 = newJObject()
  add(query_611474, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_611474.add "Tags", Tags
  add(query_611474, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_611474, "Action", newJString(Action))
  add(query_611474, "Description", newJString(Description))
  add(query_611474, "Version", newJString(Version))
  result = call_611473.call(nil, query_611474, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_611456(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_611457, base: "/",
    url: url_GetCreateDBClusterParameterGroup_611458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_611513 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBClusterSnapshot_611515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBClusterSnapshot_611514(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a snapshot of a cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611516 = query.getOrDefault("Action")
  valid_611516 = validateParameter(valid_611516, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_611516 != nil:
    section.add "Action", valid_611516
  var valid_611517 = query.getOrDefault("Version")
  valid_611517 = validateParameter(valid_611517, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611517 != nil:
    section.add "Version", valid_611517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611518 = header.getOrDefault("X-Amz-Signature")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Signature", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Content-Sha256", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Date")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Date", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Credential")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Credential", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Security-Token")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Security-Token", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Algorithm")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Algorithm", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-SignedHeaders", valid_611524
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The identifier of the cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_611525 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_611525 = validateParameter(valid_611525, JString, required = true,
                                 default = nil)
  if valid_611525 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_611525
  var valid_611526 = formData.getOrDefault("Tags")
  valid_611526 = validateParameter(valid_611526, JArray, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "Tags", valid_611526
  var valid_611527 = formData.getOrDefault("DBClusterIdentifier")
  valid_611527 = validateParameter(valid_611527, JString, required = true,
                                 default = nil)
  if valid_611527 != nil:
    section.add "DBClusterIdentifier", valid_611527
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611528: Call_PostCreateDBClusterSnapshot_611513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a cluster. 
  ## 
  let valid = call_611528.validator(path, query, header, formData, body)
  let scheme = call_611528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611528.url(scheme.get, call_611528.host, call_611528.base,
                         call_611528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611528, url, valid)

proc call*(call_611529: Call_PostCreateDBClusterSnapshot_611513;
          DBClusterSnapshotIdentifier: string; DBClusterIdentifier: string;
          Action: string = "CreateDBClusterSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterSnapshot
  ## Creates a snapshot of a cluster. 
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  var query_611530 = newJObject()
  var formData_611531 = newJObject()
  add(formData_611531, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_611530, "Action", newJString(Action))
  if Tags != nil:
    formData_611531.add "Tags", Tags
  add(query_611530, "Version", newJString(Version))
  add(formData_611531, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_611529.call(nil, query_611530, nil, formData_611531, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_611513(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_611514, base: "/",
    url: url_PostCreateDBClusterSnapshot_611515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_611495 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBClusterSnapshot_611497(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBClusterSnapshot_611496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a snapshot of a cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The identifier of the cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_611498 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_611498 = validateParameter(valid_611498, JString, required = true,
                                 default = nil)
  if valid_611498 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_611498
  var valid_611499 = query.getOrDefault("Tags")
  valid_611499 = validateParameter(valid_611499, JArray, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "Tags", valid_611499
  var valid_611500 = query.getOrDefault("DBClusterIdentifier")
  valid_611500 = validateParameter(valid_611500, JString, required = true,
                                 default = nil)
  if valid_611500 != nil:
    section.add "DBClusterIdentifier", valid_611500
  var valid_611501 = query.getOrDefault("Action")
  valid_611501 = validateParameter(valid_611501, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_611501 != nil:
    section.add "Action", valid_611501
  var valid_611502 = query.getOrDefault("Version")
  valid_611502 = validateParameter(valid_611502, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611502 != nil:
    section.add "Version", valid_611502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611503 = header.getOrDefault("X-Amz-Signature")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Signature", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Content-Sha256", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Date")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Date", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Credential")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Credential", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Security-Token")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Security-Token", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Algorithm")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Algorithm", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-SignedHeaders", valid_611509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611510: Call_GetCreateDBClusterSnapshot_611495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a cluster. 
  ## 
  let valid = call_611510.validator(path, query, header, formData, body)
  let scheme = call_611510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611510.url(scheme.get, call_611510.host, call_611510.base,
                         call_611510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611510, url, valid)

proc call*(call_611511: Call_GetCreateDBClusterSnapshot_611495;
          DBClusterSnapshotIdentifier: string; DBClusterIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBClusterSnapshot";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterSnapshot
  ## Creates a snapshot of a cluster. 
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611512 = newJObject()
  add(query_611512, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_611512.add "Tags", Tags
  add(query_611512, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_611512, "Action", newJString(Action))
  add(query_611512, "Version", newJString(Version))
  result = call_611511.call(nil, query_611512, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_611495(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_611496, base: "/",
    url: url_GetCreateDBClusterSnapshot_611497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_611556 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBInstance_611558(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_611557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611559 = query.getOrDefault("Action")
  valid_611559 = validateParameter(valid_611559, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_611559 != nil:
    section.add "Action", valid_611559
  var valid_611560 = query.getOrDefault("Version")
  valid_611560 = validateParameter(valid_611560, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611560 != nil:
    section.add "Version", valid_611560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611561 = header.getOrDefault("X-Amz-Signature")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Signature", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Content-Sha256", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Date")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Date", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Credential")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Credential", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Security-Token")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Security-Token", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Algorithm")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Algorithm", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-SignedHeaders", valid_611567
  result.add "header", section
  ## parameters in `formData` object:
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  section = newJObject()
  var valid_611568 = formData.getOrDefault("PromotionTier")
  valid_611568 = validateParameter(valid_611568, JInt, required = false, default = nil)
  if valid_611568 != nil:
    section.add "PromotionTier", valid_611568
  var valid_611569 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "PreferredMaintenanceWindow", valid_611569
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_611570 = formData.getOrDefault("DBInstanceClass")
  valid_611570 = validateParameter(valid_611570, JString, required = true,
                                 default = nil)
  if valid_611570 != nil:
    section.add "DBInstanceClass", valid_611570
  var valid_611571 = formData.getOrDefault("AvailabilityZone")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "AvailabilityZone", valid_611571
  var valid_611572 = formData.getOrDefault("Engine")
  valid_611572 = validateParameter(valid_611572, JString, required = true,
                                 default = nil)
  if valid_611572 != nil:
    section.add "Engine", valid_611572
  var valid_611573 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_611573 = validateParameter(valid_611573, JBool, required = false, default = nil)
  if valid_611573 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611573
  var valid_611574 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611574 = validateParameter(valid_611574, JString, required = true,
                                 default = nil)
  if valid_611574 != nil:
    section.add "DBInstanceIdentifier", valid_611574
  var valid_611575 = formData.getOrDefault("Tags")
  valid_611575 = validateParameter(valid_611575, JArray, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "Tags", valid_611575
  var valid_611576 = formData.getOrDefault("DBClusterIdentifier")
  valid_611576 = validateParameter(valid_611576, JString, required = true,
                                 default = nil)
  if valid_611576 != nil:
    section.add "DBClusterIdentifier", valid_611576
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611577: Call_PostCreateDBInstance_611556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new instance.
  ## 
  let valid = call_611577.validator(path, query, header, formData, body)
  let scheme = call_611577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611577.url(scheme.get, call_611577.host, call_611577.base,
                         call_611577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611577, url, valid)

proc call*(call_611578: Call_PostCreateDBInstance_611556; DBInstanceClass: string;
          Engine: string; DBInstanceIdentifier: string; DBClusterIdentifier: string;
          PromotionTier: int = 0; PreferredMaintenanceWindow: string = "";
          AvailabilityZone: string = ""; AutoMinorVersionUpgrade: bool = false;
          Action: string = "CreateDBInstance"; Tags: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBInstance
  ## Creates a new instance.
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  var query_611579 = newJObject()
  var formData_611580 = newJObject()
  add(formData_611580, "PromotionTier", newJInt(PromotionTier))
  add(formData_611580, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_611580, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_611580, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_611580, "Engine", newJString(Engine))
  add(formData_611580, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_611580, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611579, "Action", newJString(Action))
  if Tags != nil:
    formData_611580.add "Tags", Tags
  add(query_611579, "Version", newJString(Version))
  add(formData_611580, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_611578.call(nil, query_611579, nil, formData_611580, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_611556(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_611557, base: "/",
    url: url_PostCreateDBInstance_611558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_611532 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBInstance_611534(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_611533(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a new instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   Action: JString (required)
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Version: JString (required)
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_611535 = query.getOrDefault("Engine")
  valid_611535 = validateParameter(valid_611535, JString, required = true,
                                 default = nil)
  if valid_611535 != nil:
    section.add "Engine", valid_611535
  var valid_611536 = query.getOrDefault("Tags")
  valid_611536 = validateParameter(valid_611536, JArray, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "Tags", valid_611536
  var valid_611537 = query.getOrDefault("DBClusterIdentifier")
  valid_611537 = validateParameter(valid_611537, JString, required = true,
                                 default = nil)
  if valid_611537 != nil:
    section.add "DBClusterIdentifier", valid_611537
  var valid_611538 = query.getOrDefault("DBInstanceIdentifier")
  valid_611538 = validateParameter(valid_611538, JString, required = true,
                                 default = nil)
  if valid_611538 != nil:
    section.add "DBInstanceIdentifier", valid_611538
  var valid_611539 = query.getOrDefault("PromotionTier")
  valid_611539 = validateParameter(valid_611539, JInt, required = false, default = nil)
  if valid_611539 != nil:
    section.add "PromotionTier", valid_611539
  var valid_611540 = query.getOrDefault("Action")
  valid_611540 = validateParameter(valid_611540, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_611540 != nil:
    section.add "Action", valid_611540
  var valid_611541 = query.getOrDefault("AvailabilityZone")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "AvailabilityZone", valid_611541
  var valid_611542 = query.getOrDefault("Version")
  valid_611542 = validateParameter(valid_611542, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611542 != nil:
    section.add "Version", valid_611542
  var valid_611543 = query.getOrDefault("DBInstanceClass")
  valid_611543 = validateParameter(valid_611543, JString, required = true,
                                 default = nil)
  if valid_611543 != nil:
    section.add "DBInstanceClass", valid_611543
  var valid_611544 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "PreferredMaintenanceWindow", valid_611544
  var valid_611545 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_611545 = validateParameter(valid_611545, JBool, required = false, default = nil)
  if valid_611545 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611545
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611546 = header.getOrDefault("X-Amz-Signature")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Signature", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Content-Sha256", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Date")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Date", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Credential")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Credential", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Security-Token")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Security-Token", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Algorithm")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Algorithm", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-SignedHeaders", valid_611552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611553: Call_GetCreateDBInstance_611532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new instance.
  ## 
  let valid = call_611553.validator(path, query, header, formData, body)
  let scheme = call_611553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611553.url(scheme.get, call_611553.host, call_611553.base,
                         call_611553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611553, url, valid)

proc call*(call_611554: Call_GetCreateDBInstance_611532; Engine: string;
          DBClusterIdentifier: string; DBInstanceIdentifier: string;
          DBInstanceClass: string; Tags: JsonNode = nil; PromotionTier: int = 0;
          Action: string = "CreateDBInstance"; AvailabilityZone: string = "";
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false): Recallable =
  ## getCreateDBInstance
  ## Creates a new instance.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   Action: string (required)
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Version: string (required)
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  var query_611555 = newJObject()
  add(query_611555, "Engine", newJString(Engine))
  if Tags != nil:
    query_611555.add "Tags", Tags
  add(query_611555, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_611555, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611555, "PromotionTier", newJInt(PromotionTier))
  add(query_611555, "Action", newJString(Action))
  add(query_611555, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_611555, "Version", newJString(Version))
  add(query_611555, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_611555, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_611555, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_611554.call(nil, query_611555, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_611532(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_611533, base: "/",
    url: url_GetCreateDBInstance_611534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_611600 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSubnetGroup_611602(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_611601(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611603 = query.getOrDefault("Action")
  valid_611603 = validateParameter(valid_611603, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_611603 != nil:
    section.add "Action", valid_611603
  var valid_611604 = query.getOrDefault("Version")
  valid_611604 = validateParameter(valid_611604, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611604 != nil:
    section.add "Version", valid_611604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611605 = header.getOrDefault("X-Amz-Signature")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Signature", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Content-Sha256", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Date")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Date", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Credential")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Credential", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Security-Token")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Security-Token", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-Algorithm")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Algorithm", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-SignedHeaders", valid_611611
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the subnet group.
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_611612 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_611612 = validateParameter(valid_611612, JString, required = true,
                                 default = nil)
  if valid_611612 != nil:
    section.add "DBSubnetGroupDescription", valid_611612
  var valid_611613 = formData.getOrDefault("Tags")
  valid_611613 = validateParameter(valid_611613, JArray, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "Tags", valid_611613
  var valid_611614 = formData.getOrDefault("DBSubnetGroupName")
  valid_611614 = validateParameter(valid_611614, JString, required = true,
                                 default = nil)
  if valid_611614 != nil:
    section.add "DBSubnetGroupName", valid_611614
  var valid_611615 = formData.getOrDefault("SubnetIds")
  valid_611615 = validateParameter(valid_611615, JArray, required = true, default = nil)
  if valid_611615 != nil:
    section.add "SubnetIds", valid_611615
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611616: Call_PostCreateDBSubnetGroup_611600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_611616.validator(path, query, header, formData, body)
  let scheme = call_611616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611616.url(scheme.get, call_611616.host, call_611616.base,
                         call_611616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611616, url, valid)

proc call*(call_611617: Call_PostCreateDBSubnetGroup_611600;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Tags: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postCreateDBSubnetGroup
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the subnet group.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  var query_611618 = newJObject()
  var formData_611619 = newJObject()
  add(formData_611619, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_611618, "Action", newJString(Action))
  if Tags != nil:
    formData_611619.add "Tags", Tags
  add(formData_611619, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611618, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_611619.add "SubnetIds", SubnetIds
  result = call_611617.call(nil, query_611618, nil, formData_611619, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_611600(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_611601, base: "/",
    url: url_PostCreateDBSubnetGroup_611602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_611581 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSubnetGroup_611583(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_611582(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_611584 = query.getOrDefault("Tags")
  valid_611584 = validateParameter(valid_611584, JArray, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "Tags", valid_611584
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_611585 = query.getOrDefault("SubnetIds")
  valid_611585 = validateParameter(valid_611585, JArray, required = true, default = nil)
  if valid_611585 != nil:
    section.add "SubnetIds", valid_611585
  var valid_611586 = query.getOrDefault("Action")
  valid_611586 = validateParameter(valid_611586, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_611586 != nil:
    section.add "Action", valid_611586
  var valid_611587 = query.getOrDefault("DBSubnetGroupDescription")
  valid_611587 = validateParameter(valid_611587, JString, required = true,
                                 default = nil)
  if valid_611587 != nil:
    section.add "DBSubnetGroupDescription", valid_611587
  var valid_611588 = query.getOrDefault("DBSubnetGroupName")
  valid_611588 = validateParameter(valid_611588, JString, required = true,
                                 default = nil)
  if valid_611588 != nil:
    section.add "DBSubnetGroupName", valid_611588
  var valid_611589 = query.getOrDefault("Version")
  valid_611589 = validateParameter(valid_611589, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611589 != nil:
    section.add "Version", valid_611589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611590 = header.getOrDefault("X-Amz-Signature")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Signature", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Content-Sha256", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Date")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Date", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Credential")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Credential", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Security-Token")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Security-Token", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Algorithm")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Algorithm", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-SignedHeaders", valid_611596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611597: Call_GetCreateDBSubnetGroup_611581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_611597.validator(path, query, header, formData, body)
  let scheme = call_611597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611597.url(scheme.get, call_611597.host, call_611597.base,
                         call_611597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611597, url, valid)

proc call*(call_611598: Call_GetCreateDBSubnetGroup_611581; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBSubnetGroup
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_611599 = newJObject()
  if Tags != nil:
    query_611599.add "Tags", Tags
  if SubnetIds != nil:
    query_611599.add "SubnetIds", SubnetIds
  add(query_611599, "Action", newJString(Action))
  add(query_611599, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_611599, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611599, "Version", newJString(Version))
  result = call_611598.call(nil, query_611599, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_611581(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_611582, base: "/",
    url: url_GetCreateDBSubnetGroup_611583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_611638 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBCluster_611640(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBCluster_611639(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611641 = query.getOrDefault("Action")
  valid_611641 = validateParameter(valid_611641, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_611641 != nil:
    section.add "Action", valid_611641
  var valid_611642 = query.getOrDefault("Version")
  valid_611642 = validateParameter(valid_611642, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611642 != nil:
    section.add "Version", valid_611642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611643 = header.getOrDefault("X-Amz-Signature")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-Signature", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Content-Sha256", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Date")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Date", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Credential")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Credential", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Security-Token")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Security-Token", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Algorithm")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Algorithm", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-SignedHeaders", valid_611649
  result.add "header", section
  ## parameters in `formData` object:
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final cluster snapshot is created before the cluster is deleted. If <code>true</code> is specified, no cluster snapshot is created. If <code>false</code> is specified, a cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The cluster snapshot identifier of the new cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_611650 = formData.getOrDefault("SkipFinalSnapshot")
  valid_611650 = validateParameter(valid_611650, JBool, required = false, default = nil)
  if valid_611650 != nil:
    section.add "SkipFinalSnapshot", valid_611650
  var valid_611651 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_611651
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_611652 = formData.getOrDefault("DBClusterIdentifier")
  valid_611652 = validateParameter(valid_611652, JString, required = true,
                                 default = nil)
  if valid_611652 != nil:
    section.add "DBClusterIdentifier", valid_611652
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611653: Call_PostDeleteDBCluster_611638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ## 
  let valid = call_611653.validator(path, query, header, formData, body)
  let scheme = call_611653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611653.url(scheme.get, call_611653.host, call_611653.base,
                         call_611653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611653, url, valid)

proc call*(call_611654: Call_PostDeleteDBCluster_611638;
          DBClusterIdentifier: string; Action: string = "DeleteDBCluster";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBCluster
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final cluster snapshot is created before the cluster is deleted. If <code>true</code> is specified, no cluster snapshot is created. If <code>false</code> is specified, a cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The cluster snapshot identifier of the new cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  var query_611655 = newJObject()
  var formData_611656 = newJObject()
  add(query_611655, "Action", newJString(Action))
  add(formData_611656, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_611656, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_611655, "Version", newJString(Version))
  add(formData_611656, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_611654.call(nil, query_611655, nil, formData_611656, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_611638(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_611639, base: "/",
    url: url_PostDeleteDBCluster_611640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_611620 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBCluster_611622(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBCluster_611621(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final cluster snapshot is created before the cluster is deleted. If <code>true</code> is specified, no cluster snapshot is created. If <code>false</code> is specified, a cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The cluster snapshot identifier of the new cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_611623 = query.getOrDefault("DBClusterIdentifier")
  valid_611623 = validateParameter(valid_611623, JString, required = true,
                                 default = nil)
  if valid_611623 != nil:
    section.add "DBClusterIdentifier", valid_611623
  var valid_611624 = query.getOrDefault("SkipFinalSnapshot")
  valid_611624 = validateParameter(valid_611624, JBool, required = false, default = nil)
  if valid_611624 != nil:
    section.add "SkipFinalSnapshot", valid_611624
  var valid_611625 = query.getOrDefault("Action")
  valid_611625 = validateParameter(valid_611625, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_611625 != nil:
    section.add "Action", valid_611625
  var valid_611626 = query.getOrDefault("Version")
  valid_611626 = validateParameter(valid_611626, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611626 != nil:
    section.add "Version", valid_611626
  var valid_611627 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_611627
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611628 = header.getOrDefault("X-Amz-Signature")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Signature", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Content-Sha256", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Date")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Date", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Credential")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Credential", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Security-Token")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Security-Token", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Algorithm")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Algorithm", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-SignedHeaders", valid_611634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611635: Call_GetDeleteDBCluster_611620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ## 
  let valid = call_611635.validator(path, query, header, formData, body)
  let scheme = call_611635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611635.url(scheme.get, call_611635.host, call_611635.base,
                         call_611635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611635, url, valid)

proc call*(call_611636: Call_GetDeleteDBCluster_611620;
          DBClusterIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBCluster"; Version: string = "2014-10-31";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBCluster
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final cluster snapshot is created before the cluster is deleted. If <code>true</code> is specified, no cluster snapshot is created. If <code>false</code> is specified, a cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The cluster snapshot identifier of the new cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  var query_611637 = newJObject()
  add(query_611637, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_611637, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_611637, "Action", newJString(Action))
  add(query_611637, "Version", newJString(Version))
  add(query_611637, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_611636.call(nil, query_611637, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_611620(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_611621,
    base: "/", url: url_GetDeleteDBCluster_611622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_611673 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBClusterParameterGroup_611675(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBClusterParameterGroup_611674(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611676 = query.getOrDefault("Action")
  valid_611676 = validateParameter(valid_611676, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_611676 != nil:
    section.add "Action", valid_611676
  var valid_611677 = query.getOrDefault("Version")
  valid_611677 = validateParameter(valid_611677, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611677 != nil:
    section.add "Version", valid_611677
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611678 = header.getOrDefault("X-Amz-Signature")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Signature", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Content-Sha256", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Date")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Date", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Credential")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Credential", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Security-Token")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Security-Token", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Algorithm")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Algorithm", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-SignedHeaders", valid_611684
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_611685 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_611685 = validateParameter(valid_611685, JString, required = true,
                                 default = nil)
  if valid_611685 != nil:
    section.add "DBClusterParameterGroupName", valid_611685
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611686: Call_PostDeleteDBClusterParameterGroup_611673;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ## 
  let valid = call_611686.validator(path, query, header, formData, body)
  let scheme = call_611686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611686.url(scheme.get, call_611686.host, call_611686.base,
                         call_611686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611686, url, valid)

proc call*(call_611687: Call_PostDeleteDBClusterParameterGroup_611673;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_611688 = newJObject()
  var formData_611689 = newJObject()
  add(query_611688, "Action", newJString(Action))
  add(formData_611689, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_611688, "Version", newJString(Version))
  result = call_611687.call(nil, query_611688, nil, formData_611689, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_611673(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_611674, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_611675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_611657 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBClusterParameterGroup_611659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBClusterParameterGroup_611658(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_611660 = query.getOrDefault("DBClusterParameterGroupName")
  valid_611660 = validateParameter(valid_611660, JString, required = true,
                                 default = nil)
  if valid_611660 != nil:
    section.add "DBClusterParameterGroupName", valid_611660
  var valid_611661 = query.getOrDefault("Action")
  valid_611661 = validateParameter(valid_611661, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_611661 != nil:
    section.add "Action", valid_611661
  var valid_611662 = query.getOrDefault("Version")
  valid_611662 = validateParameter(valid_611662, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611662 != nil:
    section.add "Version", valid_611662
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611663 = header.getOrDefault("X-Amz-Signature")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Signature", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Content-Sha256", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Date")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Date", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Credential")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Credential", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Security-Token")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Security-Token", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Algorithm")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Algorithm", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-SignedHeaders", valid_611669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611670: Call_GetDeleteDBClusterParameterGroup_611657;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ## 
  let valid = call_611670.validator(path, query, header, formData, body)
  let scheme = call_611670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611670.url(scheme.get, call_611670.host, call_611670.base,
                         call_611670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611670, url, valid)

proc call*(call_611671: Call_GetDeleteDBClusterParameterGroup_611657;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611672 = newJObject()
  add(query_611672, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_611672, "Action", newJString(Action))
  add(query_611672, "Version", newJString(Version))
  result = call_611671.call(nil, query_611672, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_611657(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_611658, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_611659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_611706 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBClusterSnapshot_611708(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBClusterSnapshot_611707(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611709 = query.getOrDefault("Action")
  valid_611709 = validateParameter(valid_611709, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_611709 != nil:
    section.add "Action", valid_611709
  var valid_611710 = query.getOrDefault("Version")
  valid_611710 = validateParameter(valid_611710, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611710 != nil:
    section.add "Version", valid_611710
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611711 = header.getOrDefault("X-Amz-Signature")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Signature", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Content-Sha256", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Date")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Date", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Credential")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Credential", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Security-Token")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Security-Token", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Algorithm")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Algorithm", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-SignedHeaders", valid_611717
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_611718 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_611718 = validateParameter(valid_611718, JString, required = true,
                                 default = nil)
  if valid_611718 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_611718
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611719: Call_PostDeleteDBClusterSnapshot_611706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_611719.validator(path, query, header, formData, body)
  let scheme = call_611719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611719.url(scheme.get, call_611719.host, call_611719.base,
                         call_611719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611719, url, valid)

proc call*(call_611720: Call_PostDeleteDBClusterSnapshot_611706;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611721 = newJObject()
  var formData_611722 = newJObject()
  add(formData_611722, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_611721, "Action", newJString(Action))
  add(query_611721, "Version", newJString(Version))
  result = call_611720.call(nil, query_611721, nil, formData_611722, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_611706(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_611707, base: "/",
    url: url_PostDeleteDBClusterSnapshot_611708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_611690 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBClusterSnapshot_611692(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBClusterSnapshot_611691(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_611693 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_611693 = validateParameter(valid_611693, JString, required = true,
                                 default = nil)
  if valid_611693 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_611693
  var valid_611694 = query.getOrDefault("Action")
  valid_611694 = validateParameter(valid_611694, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_611694 != nil:
    section.add "Action", valid_611694
  var valid_611695 = query.getOrDefault("Version")
  valid_611695 = validateParameter(valid_611695, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611695 != nil:
    section.add "Version", valid_611695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611696 = header.getOrDefault("X-Amz-Signature")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Signature", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Content-Sha256", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Date")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Date", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Credential")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Credential", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-Security-Token")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Security-Token", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Algorithm")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Algorithm", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-SignedHeaders", valid_611702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611703: Call_GetDeleteDBClusterSnapshot_611690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_611703.validator(path, query, header, formData, body)
  let scheme = call_611703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611703.url(scheme.get, call_611703.host, call_611703.base,
                         call_611703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611703, url, valid)

proc call*(call_611704: Call_GetDeleteDBClusterSnapshot_611690;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611705 = newJObject()
  add(query_611705, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_611705, "Action", newJString(Action))
  add(query_611705, "Version", newJString(Version))
  result = call_611704.call(nil, query_611705, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_611690(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_611691, base: "/",
    url: url_GetDeleteDBClusterSnapshot_611692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_611739 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBInstance_611741(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_611740(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a previously provisioned instance. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611742 = query.getOrDefault("Action")
  valid_611742 = validateParameter(valid_611742, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_611742 != nil:
    section.add "Action", valid_611742
  var valid_611743 = query.getOrDefault("Version")
  valid_611743 = validateParameter(valid_611743, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611743 != nil:
    section.add "Version", valid_611743
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611744 = header.getOrDefault("X-Amz-Signature")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Signature", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Content-Sha256", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Date")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Date", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-Credential")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Credential", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Security-Token")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Security-Token", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Algorithm")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Algorithm", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-SignedHeaders", valid_611750
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611751 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611751 = validateParameter(valid_611751, JString, required = true,
                                 default = nil)
  if valid_611751 != nil:
    section.add "DBInstanceIdentifier", valid_611751
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611752: Call_PostDeleteDBInstance_611739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned instance. 
  ## 
  let valid = call_611752.validator(path, query, header, formData, body)
  let scheme = call_611752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611752.url(scheme.get, call_611752.host, call_611752.base,
                         call_611752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611752, url, valid)

proc call*(call_611753: Call_PostDeleteDBInstance_611739;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611754 = newJObject()
  var formData_611755 = newJObject()
  add(formData_611755, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611754, "Action", newJString(Action))
  add(query_611754, "Version", newJString(Version))
  result = call_611753.call(nil, query_611754, nil, formData_611755, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_611739(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_611740, base: "/",
    url: url_PostDeleteDBInstance_611741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_611723 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBInstance_611725(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_611724(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a previously provisioned instance. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611726 = query.getOrDefault("DBInstanceIdentifier")
  valid_611726 = validateParameter(valid_611726, JString, required = true,
                                 default = nil)
  if valid_611726 != nil:
    section.add "DBInstanceIdentifier", valid_611726
  var valid_611727 = query.getOrDefault("Action")
  valid_611727 = validateParameter(valid_611727, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_611727 != nil:
    section.add "Action", valid_611727
  var valid_611728 = query.getOrDefault("Version")
  valid_611728 = validateParameter(valid_611728, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611728 != nil:
    section.add "Version", valid_611728
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611729 = header.getOrDefault("X-Amz-Signature")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Signature", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Content-Sha256", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-Date")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-Date", valid_611731
  var valid_611732 = header.getOrDefault("X-Amz-Credential")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-Credential", valid_611732
  var valid_611733 = header.getOrDefault("X-Amz-Security-Token")
  valid_611733 = validateParameter(valid_611733, JString, required = false,
                                 default = nil)
  if valid_611733 != nil:
    section.add "X-Amz-Security-Token", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Algorithm")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Algorithm", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-SignedHeaders", valid_611735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611736: Call_GetDeleteDBInstance_611723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned instance. 
  ## 
  let valid = call_611736.validator(path, query, header, formData, body)
  let scheme = call_611736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611736.url(scheme.get, call_611736.host, call_611736.base,
                         call_611736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611736, url, valid)

proc call*(call_611737: Call_GetDeleteDBInstance_611723;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611738 = newJObject()
  add(query_611738, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611738, "Action", newJString(Action))
  add(query_611738, "Version", newJString(Version))
  result = call_611737.call(nil, query_611738, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_611723(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_611724, base: "/",
    url: url_GetDeleteDBInstance_611725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_611772 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSubnetGroup_611774(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_611773(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611775 = query.getOrDefault("Action")
  valid_611775 = validateParameter(valid_611775, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_611775 != nil:
    section.add "Action", valid_611775
  var valid_611776 = query.getOrDefault("Version")
  valid_611776 = validateParameter(valid_611776, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611776 != nil:
    section.add "Version", valid_611776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611777 = header.getOrDefault("X-Amz-Signature")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Signature", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Content-Sha256", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Date")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Date", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Credential")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Credential", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Security-Token")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Security-Token", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Algorithm")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Algorithm", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-SignedHeaders", valid_611783
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_611784 = formData.getOrDefault("DBSubnetGroupName")
  valid_611784 = validateParameter(valid_611784, JString, required = true,
                                 default = nil)
  if valid_611784 != nil:
    section.add "DBSubnetGroupName", valid_611784
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611785: Call_PostDeleteDBSubnetGroup_611772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_611785.validator(path, query, header, formData, body)
  let scheme = call_611785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611785.url(scheme.get, call_611785.host, call_611785.base,
                         call_611785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611785, url, valid)

proc call*(call_611786: Call_PostDeleteDBSubnetGroup_611772;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_611787 = newJObject()
  var formData_611788 = newJObject()
  add(query_611787, "Action", newJString(Action))
  add(formData_611788, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611787, "Version", newJString(Version))
  result = call_611786.call(nil, query_611787, nil, formData_611788, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_611772(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_611773, base: "/",
    url: url_PostDeleteDBSubnetGroup_611774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_611756 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSubnetGroup_611758(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_611757(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
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
  var valid_611759 = query.getOrDefault("Action")
  valid_611759 = validateParameter(valid_611759, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_611759 != nil:
    section.add "Action", valid_611759
  var valid_611760 = query.getOrDefault("DBSubnetGroupName")
  valid_611760 = validateParameter(valid_611760, JString, required = true,
                                 default = nil)
  if valid_611760 != nil:
    section.add "DBSubnetGroupName", valid_611760
  var valid_611761 = query.getOrDefault("Version")
  valid_611761 = validateParameter(valid_611761, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611761 != nil:
    section.add "Version", valid_611761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611762 = header.getOrDefault("X-Amz-Signature")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Signature", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Content-Sha256", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Date")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Date", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Credential")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Credential", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Security-Token")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Security-Token", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Algorithm")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Algorithm", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-SignedHeaders", valid_611768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611769: Call_GetDeleteDBSubnetGroup_611756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_611769.validator(path, query, header, formData, body)
  let scheme = call_611769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611769.url(scheme.get, call_611769.host, call_611769.base,
                         call_611769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611769, url, valid)

proc call*(call_611770: Call_GetDeleteDBSubnetGroup_611756;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_611771 = newJObject()
  add(query_611771, "Action", newJString(Action))
  add(query_611771, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611771, "Version", newJString(Version))
  result = call_611770.call(nil, query_611771, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_611756(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_611757, base: "/",
    url: url_GetDeleteDBSubnetGroup_611758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeCertificates_611808 = ref object of OpenApiRestCall_610642
proc url_PostDescribeCertificates_611810(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeCertificates_611809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611811 = query.getOrDefault("Action")
  valid_611811 = validateParameter(valid_611811, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_611811 != nil:
    section.add "Action", valid_611811
  var valid_611812 = query.getOrDefault("Version")
  valid_611812 = validateParameter(valid_611812, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611812 != nil:
    section.add "Version", valid_611812
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611813 = header.getOrDefault("X-Amz-Signature")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Signature", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Content-Sha256", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Date")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Date", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Credential")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Credential", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Security-Token")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Security-Token", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Algorithm")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Algorithm", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-SignedHeaders", valid_611819
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
  var valid_611820 = formData.getOrDefault("MaxRecords")
  valid_611820 = validateParameter(valid_611820, JInt, required = false, default = nil)
  if valid_611820 != nil:
    section.add "MaxRecords", valid_611820
  var valid_611821 = formData.getOrDefault("Marker")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "Marker", valid_611821
  var valid_611822 = formData.getOrDefault("CertificateIdentifier")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "CertificateIdentifier", valid_611822
  var valid_611823 = formData.getOrDefault("Filters")
  valid_611823 = validateParameter(valid_611823, JArray, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "Filters", valid_611823
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611824: Call_PostDescribeCertificates_611808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ## 
  let valid = call_611824.validator(path, query, header, formData, body)
  let scheme = call_611824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611824.url(scheme.get, call_611824.host, call_611824.base,
                         call_611824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611824, url, valid)

proc call*(call_611825: Call_PostDescribeCertificates_611808; MaxRecords: int = 0;
          Marker: string = ""; CertificateIdentifier: string = "";
          Action: string = "DescribeCertificates"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
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
  var query_611826 = newJObject()
  var formData_611827 = newJObject()
  add(formData_611827, "MaxRecords", newJInt(MaxRecords))
  add(formData_611827, "Marker", newJString(Marker))
  add(formData_611827, "CertificateIdentifier", newJString(CertificateIdentifier))
  add(query_611826, "Action", newJString(Action))
  if Filters != nil:
    formData_611827.add "Filters", Filters
  add(query_611826, "Version", newJString(Version))
  result = call_611825.call(nil, query_611826, nil, formData_611827, nil)

var postDescribeCertificates* = Call_PostDescribeCertificates_611808(
    name: "postDescribeCertificates", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_PostDescribeCertificates_611809, base: "/",
    url: url_PostDescribeCertificates_611810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeCertificates_611789 = ref object of OpenApiRestCall_610642
proc url_GetDescribeCertificates_611791(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeCertificates_611790(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
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
  var valid_611792 = query.getOrDefault("Marker")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "Marker", valid_611792
  var valid_611793 = query.getOrDefault("Action")
  valid_611793 = validateParameter(valid_611793, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_611793 != nil:
    section.add "Action", valid_611793
  var valid_611794 = query.getOrDefault("Version")
  valid_611794 = validateParameter(valid_611794, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611794 != nil:
    section.add "Version", valid_611794
  var valid_611795 = query.getOrDefault("CertificateIdentifier")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "CertificateIdentifier", valid_611795
  var valid_611796 = query.getOrDefault("Filters")
  valid_611796 = validateParameter(valid_611796, JArray, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "Filters", valid_611796
  var valid_611797 = query.getOrDefault("MaxRecords")
  valid_611797 = validateParameter(valid_611797, JInt, required = false, default = nil)
  if valid_611797 != nil:
    section.add "MaxRecords", valid_611797
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611798 = header.getOrDefault("X-Amz-Signature")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Signature", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Content-Sha256", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-Date")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-Date", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Credential")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Credential", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Security-Token")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Security-Token", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Algorithm")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Algorithm", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-SignedHeaders", valid_611804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611805: Call_GetDescribeCertificates_611789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ## 
  let valid = call_611805.validator(path, query, header, formData, body)
  let scheme = call_611805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611805.url(scheme.get, call_611805.host, call_611805.base,
                         call_611805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611805, url, valid)

proc call*(call_611806: Call_GetDescribeCertificates_611789; Marker: string = "";
          Action: string = "DescribeCertificates"; Version: string = "2014-10-31";
          CertificateIdentifier: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0): Recallable =
  ## getDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
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
  var query_611807 = newJObject()
  add(query_611807, "Marker", newJString(Marker))
  add(query_611807, "Action", newJString(Action))
  add(query_611807, "Version", newJString(Version))
  add(query_611807, "CertificateIdentifier", newJString(CertificateIdentifier))
  if Filters != nil:
    query_611807.add "Filters", Filters
  add(query_611807, "MaxRecords", newJInt(MaxRecords))
  result = call_611806.call(nil, query_611807, nil, nil, nil)

var getDescribeCertificates* = Call_GetDescribeCertificates_611789(
    name: "getDescribeCertificates", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_GetDescribeCertificates_611790, base: "/",
    url: url_GetDescribeCertificates_611791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_611847 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBClusterParameterGroups_611849(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterParameterGroups_611848(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611850 = query.getOrDefault("Action")
  valid_611850 = validateParameter(valid_611850, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_611850 != nil:
    section.add "Action", valid_611850
  var valid_611851 = query.getOrDefault("Version")
  valid_611851 = validateParameter(valid_611851, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611851 != nil:
    section.add "Version", valid_611851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611852 = header.getOrDefault("X-Amz-Signature")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Signature", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-Content-Sha256", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-Date")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Date", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Credential")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Credential", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Security-Token")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Security-Token", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Algorithm")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Algorithm", valid_611857
  var valid_611858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-SignedHeaders", valid_611858
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  section = newJObject()
  var valid_611859 = formData.getOrDefault("MaxRecords")
  valid_611859 = validateParameter(valid_611859, JInt, required = false, default = nil)
  if valid_611859 != nil:
    section.add "MaxRecords", valid_611859
  var valid_611860 = formData.getOrDefault("Marker")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "Marker", valid_611860
  var valid_611861 = formData.getOrDefault("Filters")
  valid_611861 = validateParameter(valid_611861, JArray, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "Filters", valid_611861
  var valid_611862 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "DBClusterParameterGroupName", valid_611862
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611863: Call_PostDescribeDBClusterParameterGroups_611847;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ## 
  let valid = call_611863.validator(path, query, header, formData, body)
  let scheme = call_611863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611863.url(scheme.get, call_611863.host, call_611863.base,
                         call_611863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611863, url, valid)

proc call*(call_611864: Call_PostDescribeDBClusterParameterGroups_611847;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBClusterParameterGroups";
          Filters: JsonNode = nil; DBClusterParameterGroupName: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_611865 = newJObject()
  var formData_611866 = newJObject()
  add(formData_611866, "MaxRecords", newJInt(MaxRecords))
  add(formData_611866, "Marker", newJString(Marker))
  add(query_611865, "Action", newJString(Action))
  if Filters != nil:
    formData_611866.add "Filters", Filters
  add(formData_611866, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_611865, "Version", newJString(Version))
  result = call_611864.call(nil, query_611865, nil, formData_611866, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_611847(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_611848, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_611849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_611828 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBClusterParameterGroups_611830(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterParameterGroups_611829(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_611831 = query.getOrDefault("Marker")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "Marker", valid_611831
  var valid_611832 = query.getOrDefault("DBClusterParameterGroupName")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "DBClusterParameterGroupName", valid_611832
  var valid_611833 = query.getOrDefault("Action")
  valid_611833 = validateParameter(valid_611833, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_611833 != nil:
    section.add "Action", valid_611833
  var valid_611834 = query.getOrDefault("Version")
  valid_611834 = validateParameter(valid_611834, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611834 != nil:
    section.add "Version", valid_611834
  var valid_611835 = query.getOrDefault("Filters")
  valid_611835 = validateParameter(valid_611835, JArray, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "Filters", valid_611835
  var valid_611836 = query.getOrDefault("MaxRecords")
  valid_611836 = validateParameter(valid_611836, JInt, required = false, default = nil)
  if valid_611836 != nil:
    section.add "MaxRecords", valid_611836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611837 = header.getOrDefault("X-Amz-Signature")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-Signature", valid_611837
  var valid_611838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "X-Amz-Content-Sha256", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-Date")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-Date", valid_611839
  var valid_611840 = header.getOrDefault("X-Amz-Credential")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Credential", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Security-Token")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Security-Token", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Algorithm")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Algorithm", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-SignedHeaders", valid_611843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611844: Call_GetDescribeDBClusterParameterGroups_611828;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ## 
  let valid = call_611844.validator(path, query, header, formData, body)
  let scheme = call_611844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611844.url(scheme.get, call_611844.host, call_611844.base,
                         call_611844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611844, url, valid)

proc call*(call_611845: Call_GetDescribeDBClusterParameterGroups_611828;
          Marker: string = ""; DBClusterParameterGroupName: string = "";
          Action: string = "DescribeDBClusterParameterGroups";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_611846 = newJObject()
  add(query_611846, "Marker", newJString(Marker))
  add(query_611846, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_611846, "Action", newJString(Action))
  add(query_611846, "Version", newJString(Version))
  if Filters != nil:
    query_611846.add "Filters", Filters
  add(query_611846, "MaxRecords", newJInt(MaxRecords))
  result = call_611845.call(nil, query_611846, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_611828(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_611829, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_611830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_611887 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBClusterParameters_611889(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterParameters_611888(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611890 = query.getOrDefault("Action")
  valid_611890 = validateParameter(valid_611890, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_611890 != nil:
    section.add "Action", valid_611890
  var valid_611891 = query.getOrDefault("Version")
  valid_611891 = validateParameter(valid_611891, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611891 != nil:
    section.add "Version", valid_611891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611892 = header.getOrDefault("X-Amz-Signature")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Signature", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Content-Sha256", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Date")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Date", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Credential")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Credential", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Security-Token")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Security-Token", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Algorithm")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Algorithm", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-SignedHeaders", valid_611898
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
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  section = newJObject()
  var valid_611899 = formData.getOrDefault("Source")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "Source", valid_611899
  var valid_611900 = formData.getOrDefault("MaxRecords")
  valid_611900 = validateParameter(valid_611900, JInt, required = false, default = nil)
  if valid_611900 != nil:
    section.add "MaxRecords", valid_611900
  var valid_611901 = formData.getOrDefault("Marker")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "Marker", valid_611901
  var valid_611902 = formData.getOrDefault("Filters")
  valid_611902 = validateParameter(valid_611902, JArray, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "Filters", valid_611902
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_611903 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_611903 = validateParameter(valid_611903, JString, required = true,
                                 default = nil)
  if valid_611903 != nil:
    section.add "DBClusterParameterGroupName", valid_611903
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611904: Call_PostDescribeDBClusterParameters_611887;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ## 
  let valid = call_611904.validator(path, query, header, formData, body)
  let scheme = call_611904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611904.url(scheme.get, call_611904.host, call_611904.base,
                         call_611904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611904, url, valid)

proc call*(call_611905: Call_PostDescribeDBClusterParameters_611887;
          DBClusterParameterGroupName: string; Source: string = "";
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBClusterParameters"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular cluster parameter group.
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
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_611906 = newJObject()
  var formData_611907 = newJObject()
  add(formData_611907, "Source", newJString(Source))
  add(formData_611907, "MaxRecords", newJInt(MaxRecords))
  add(formData_611907, "Marker", newJString(Marker))
  add(query_611906, "Action", newJString(Action))
  if Filters != nil:
    formData_611907.add "Filters", Filters
  add(formData_611907, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_611906, "Version", newJString(Version))
  result = call_611905.call(nil, query_611906, nil, formData_611907, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_611887(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_611888, base: "/",
    url: url_PostDescribeDBClusterParameters_611889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_611867 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBClusterParameters_611869(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterParameters_611868(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the detailed parameter list for a particular cluster parameter group.
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
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_611870 = query.getOrDefault("Marker")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "Marker", valid_611870
  var valid_611871 = query.getOrDefault("Source")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "Source", valid_611871
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_611872 = query.getOrDefault("DBClusterParameterGroupName")
  valid_611872 = validateParameter(valid_611872, JString, required = true,
                                 default = nil)
  if valid_611872 != nil:
    section.add "DBClusterParameterGroupName", valid_611872
  var valid_611873 = query.getOrDefault("Action")
  valid_611873 = validateParameter(valid_611873, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_611873 != nil:
    section.add "Action", valid_611873
  var valid_611874 = query.getOrDefault("Version")
  valid_611874 = validateParameter(valid_611874, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611874 != nil:
    section.add "Version", valid_611874
  var valid_611875 = query.getOrDefault("Filters")
  valid_611875 = validateParameter(valid_611875, JArray, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "Filters", valid_611875
  var valid_611876 = query.getOrDefault("MaxRecords")
  valid_611876 = validateParameter(valid_611876, JInt, required = false, default = nil)
  if valid_611876 != nil:
    section.add "MaxRecords", valid_611876
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611877 = header.getOrDefault("X-Amz-Signature")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Signature", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Content-Sha256", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Date")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Date", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Credential")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Credential", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Security-Token")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Security-Token", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Algorithm")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Algorithm", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-SignedHeaders", valid_611883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611884: Call_GetDescribeDBClusterParameters_611867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ## 
  let valid = call_611884.validator(path, query, header, formData, body)
  let scheme = call_611884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611884.url(scheme.get, call_611884.host, call_611884.base,
                         call_611884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611884, url, valid)

proc call*(call_611885: Call_GetDescribeDBClusterParameters_611867;
          DBClusterParameterGroupName: string; Marker: string = "";
          Source: string = ""; Action: string = "DescribeDBClusterParameters";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_611886 = newJObject()
  add(query_611886, "Marker", newJString(Marker))
  add(query_611886, "Source", newJString(Source))
  add(query_611886, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_611886, "Action", newJString(Action))
  add(query_611886, "Version", newJString(Version))
  if Filters != nil:
    query_611886.add "Filters", Filters
  add(query_611886, "MaxRecords", newJInt(MaxRecords))
  result = call_611885.call(nil, query_611886, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_611867(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_611868, base: "/",
    url: url_GetDescribeDBClusterParameters_611869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_611924 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBClusterSnapshotAttributes_611926(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_611925(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611927 = query.getOrDefault("Action")
  valid_611927 = validateParameter(valid_611927, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_611927 != nil:
    section.add "Action", valid_611927
  var valid_611928 = query.getOrDefault("Version")
  valid_611928 = validateParameter(valid_611928, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611928 != nil:
    section.add "Version", valid_611928
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611929 = header.getOrDefault("X-Amz-Signature")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Signature", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Content-Sha256", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Date")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Date", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-Credential")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Credential", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Security-Token")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Security-Token", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Algorithm")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Algorithm", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-SignedHeaders", valid_611935
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_611936 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_611936 = validateParameter(valid_611936, JString, required = true,
                                 default = nil)
  if valid_611936 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_611936
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611937: Call_PostDescribeDBClusterSnapshotAttributes_611924;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_611937.validator(path, query, header, formData, body)
  let scheme = call_611937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611937.url(scheme.get, call_611937.host, call_611937.base,
                         call_611937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611937, url, valid)

proc call*(call_611938: Call_PostDescribeDBClusterSnapshotAttributes_611924;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611939 = newJObject()
  var formData_611940 = newJObject()
  add(formData_611940, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_611939, "Action", newJString(Action))
  add(query_611939, "Version", newJString(Version))
  result = call_611938.call(nil, query_611939, nil, formData_611940, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_611924(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_611925, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_611926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_611908 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBClusterSnapshotAttributes_611910(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_611909(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_611911 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_611911 = validateParameter(valid_611911, JString, required = true,
                                 default = nil)
  if valid_611911 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_611911
  var valid_611912 = query.getOrDefault("Action")
  valid_611912 = validateParameter(valid_611912, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_611912 != nil:
    section.add "Action", valid_611912
  var valid_611913 = query.getOrDefault("Version")
  valid_611913 = validateParameter(valid_611913, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611913 != nil:
    section.add "Version", valid_611913
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611914 = header.getOrDefault("X-Amz-Signature")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Signature", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Content-Sha256", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Date")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Date", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Credential")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Credential", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Security-Token")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Security-Token", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Algorithm")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Algorithm", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-SignedHeaders", valid_611920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611921: Call_GetDescribeDBClusterSnapshotAttributes_611908;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_611921.validator(path, query, header, formData, body)
  let scheme = call_611921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611921.url(scheme.get, call_611921.host, call_611921.base,
                         call_611921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611921, url, valid)

proc call*(call_611922: Call_GetDescribeDBClusterSnapshotAttributes_611908;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611923 = newJObject()
  add(query_611923, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_611923, "Action", newJString(Action))
  add(query_611923, "Version", newJString(Version))
  result = call_611922.call(nil, query_611923, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_611908(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_611909, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_611910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_611964 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBClusterSnapshots_611966(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterSnapshots_611965(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611967 = query.getOrDefault("Action")
  valid_611967 = validateParameter(valid_611967, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_611967 != nil:
    section.add "Action", valid_611967
  var valid_611968 = query.getOrDefault("Version")
  valid_611968 = validateParameter(valid_611968, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611968 != nil:
    section.add "Version", valid_611968
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611969 = header.getOrDefault("X-Amz-Signature")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Signature", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Content-Sha256", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-Date")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-Date", valid_611971
  var valid_611972 = header.getOrDefault("X-Amz-Credential")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "X-Amz-Credential", valid_611972
  var valid_611973 = header.getOrDefault("X-Amz-Security-Token")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-Security-Token", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-Algorithm")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Algorithm", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-SignedHeaders", valid_611975
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_611976 = formData.getOrDefault("SnapshotType")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "SnapshotType", valid_611976
  var valid_611977 = formData.getOrDefault("MaxRecords")
  valid_611977 = validateParameter(valid_611977, JInt, required = false, default = nil)
  if valid_611977 != nil:
    section.add "MaxRecords", valid_611977
  var valid_611978 = formData.getOrDefault("IncludePublic")
  valid_611978 = validateParameter(valid_611978, JBool, required = false, default = nil)
  if valid_611978 != nil:
    section.add "IncludePublic", valid_611978
  var valid_611979 = formData.getOrDefault("Marker")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "Marker", valid_611979
  var valid_611980 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_611980
  var valid_611981 = formData.getOrDefault("IncludeShared")
  valid_611981 = validateParameter(valid_611981, JBool, required = false, default = nil)
  if valid_611981 != nil:
    section.add "IncludeShared", valid_611981
  var valid_611982 = formData.getOrDefault("Filters")
  valid_611982 = validateParameter(valid_611982, JArray, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "Filters", valid_611982
  var valid_611983 = formData.getOrDefault("DBClusterIdentifier")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "DBClusterIdentifier", valid_611983
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611984: Call_PostDescribeDBClusterSnapshots_611964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_611984.validator(path, query, header, formData, body)
  let scheme = call_611984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611984.url(scheme.get, call_611984.host, call_611984.base,
                         call_611984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611984, url, valid)

proc call*(call_611985: Call_PostDescribeDBClusterSnapshots_611964;
          SnapshotType: string = ""; MaxRecords: int = 0; IncludePublic: bool = false;
          Marker: string = ""; DBClusterSnapshotIdentifier: string = "";
          IncludeShared: bool = false;
          Action: string = "DescribeDBClusterSnapshots"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"; DBClusterIdentifier: string = ""): Recallable =
  ## postDescribeDBClusterSnapshots
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ##   SnapshotType: string
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  var query_611986 = newJObject()
  var formData_611987 = newJObject()
  add(formData_611987, "SnapshotType", newJString(SnapshotType))
  add(formData_611987, "MaxRecords", newJInt(MaxRecords))
  add(formData_611987, "IncludePublic", newJBool(IncludePublic))
  add(formData_611987, "Marker", newJString(Marker))
  add(formData_611987, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_611987, "IncludeShared", newJBool(IncludeShared))
  add(query_611986, "Action", newJString(Action))
  if Filters != nil:
    formData_611987.add "Filters", Filters
  add(query_611986, "Version", newJString(Version))
  add(formData_611987, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_611985.call(nil, query_611986, nil, formData_611987, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_611964(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_611965, base: "/",
    url: url_PostDescribeDBClusterSnapshots_611966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_611941 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBClusterSnapshots_611943(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterSnapshots_611942(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   SnapshotType: JString
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: JString (required)
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_611944 = query.getOrDefault("Marker")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "Marker", valid_611944
  var valid_611945 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_611945
  var valid_611946 = query.getOrDefault("DBClusterIdentifier")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "DBClusterIdentifier", valid_611946
  var valid_611947 = query.getOrDefault("SnapshotType")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "SnapshotType", valid_611947
  var valid_611948 = query.getOrDefault("IncludePublic")
  valid_611948 = validateParameter(valid_611948, JBool, required = false, default = nil)
  if valid_611948 != nil:
    section.add "IncludePublic", valid_611948
  var valid_611949 = query.getOrDefault("Action")
  valid_611949 = validateParameter(valid_611949, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_611949 != nil:
    section.add "Action", valid_611949
  var valid_611950 = query.getOrDefault("IncludeShared")
  valid_611950 = validateParameter(valid_611950, JBool, required = false, default = nil)
  if valid_611950 != nil:
    section.add "IncludeShared", valid_611950
  var valid_611951 = query.getOrDefault("Version")
  valid_611951 = validateParameter(valid_611951, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611951 != nil:
    section.add "Version", valid_611951
  var valid_611952 = query.getOrDefault("Filters")
  valid_611952 = validateParameter(valid_611952, JArray, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "Filters", valid_611952
  var valid_611953 = query.getOrDefault("MaxRecords")
  valid_611953 = validateParameter(valid_611953, JInt, required = false, default = nil)
  if valid_611953 != nil:
    section.add "MaxRecords", valid_611953
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611954 = header.getOrDefault("X-Amz-Signature")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Signature", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Content-Sha256", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-Date")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-Date", valid_611956
  var valid_611957 = header.getOrDefault("X-Amz-Credential")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-Credential", valid_611957
  var valid_611958 = header.getOrDefault("X-Amz-Security-Token")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-Security-Token", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Algorithm")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Algorithm", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-SignedHeaders", valid_611960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611961: Call_GetDescribeDBClusterSnapshots_611941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_611961.validator(path, query, header, formData, body)
  let scheme = call_611961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611961.url(scheme.get, call_611961.host, call_611961.base,
                         call_611961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611961, url, valid)

proc call*(call_611962: Call_GetDescribeDBClusterSnapshots_611941;
          Marker: string = ""; DBClusterSnapshotIdentifier: string = "";
          DBClusterIdentifier: string = ""; SnapshotType: string = "";
          IncludePublic: bool = false;
          Action: string = "DescribeDBClusterSnapshots";
          IncludeShared: bool = false; Version: string = "2014-10-31";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBClusterSnapshots
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   SnapshotType: string
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: string (required)
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_611963 = newJObject()
  add(query_611963, "Marker", newJString(Marker))
  add(query_611963, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_611963, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_611963, "SnapshotType", newJString(SnapshotType))
  add(query_611963, "IncludePublic", newJBool(IncludePublic))
  add(query_611963, "Action", newJString(Action))
  add(query_611963, "IncludeShared", newJBool(IncludeShared))
  add(query_611963, "Version", newJString(Version))
  if Filters != nil:
    query_611963.add "Filters", Filters
  add(query_611963, "MaxRecords", newJInt(MaxRecords))
  result = call_611962.call(nil, query_611963, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_611941(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_611942, base: "/",
    url: url_GetDescribeDBClusterSnapshots_611943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_612007 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBClusters_612009(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusters_612008(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612010 = query.getOrDefault("Action")
  valid_612010 = validateParameter(valid_612010, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_612010 != nil:
    section.add "Action", valid_612010
  var valid_612011 = query.getOrDefault("Version")
  valid_612011 = validateParameter(valid_612011, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612011 != nil:
    section.add "Version", valid_612011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612012 = header.getOrDefault("X-Amz-Signature")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-Signature", valid_612012
  var valid_612013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Content-Sha256", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-Date")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-Date", valid_612014
  var valid_612015 = header.getOrDefault("X-Amz-Credential")
  valid_612015 = validateParameter(valid_612015, JString, required = false,
                                 default = nil)
  if valid_612015 != nil:
    section.add "X-Amz-Credential", valid_612015
  var valid_612016 = header.getOrDefault("X-Amz-Security-Token")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-Security-Token", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-Algorithm")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-Algorithm", valid_612017
  var valid_612018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "X-Amz-SignedHeaders", valid_612018
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_612019 = formData.getOrDefault("MaxRecords")
  valid_612019 = validateParameter(valid_612019, JInt, required = false, default = nil)
  if valid_612019 != nil:
    section.add "MaxRecords", valid_612019
  var valid_612020 = formData.getOrDefault("Marker")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "Marker", valid_612020
  var valid_612021 = formData.getOrDefault("Filters")
  valid_612021 = validateParameter(valid_612021, JArray, required = false,
                                 default = nil)
  if valid_612021 != nil:
    section.add "Filters", valid_612021
  var valid_612022 = formData.getOrDefault("DBClusterIdentifier")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "DBClusterIdentifier", valid_612022
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612023: Call_PostDescribeDBClusters_612007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination.
  ## 
  let valid = call_612023.validator(path, query, header, formData, body)
  let scheme = call_612023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612023.url(scheme.get, call_612023.host, call_612023.base,
                         call_612023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612023, url, valid)

proc call*(call_612024: Call_PostDescribeDBClusters_612007; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBClusters";
          Filters: JsonNode = nil; Version: string = "2014-10-31";
          DBClusterIdentifier: string = ""): Recallable =
  ## postDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  var query_612025 = newJObject()
  var formData_612026 = newJObject()
  add(formData_612026, "MaxRecords", newJInt(MaxRecords))
  add(formData_612026, "Marker", newJString(Marker))
  add(query_612025, "Action", newJString(Action))
  if Filters != nil:
    formData_612026.add "Filters", Filters
  add(query_612025, "Version", newJString(Version))
  add(formData_612026, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_612024.call(nil, query_612025, nil, formData_612026, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_612007(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_612008, base: "/",
    url: url_PostDescribeDBClusters_612009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_611988 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBClusters_611990(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusters_611989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_611991 = query.getOrDefault("Marker")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "Marker", valid_611991
  var valid_611992 = query.getOrDefault("DBClusterIdentifier")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "DBClusterIdentifier", valid_611992
  var valid_611993 = query.getOrDefault("Action")
  valid_611993 = validateParameter(valid_611993, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_611993 != nil:
    section.add "Action", valid_611993
  var valid_611994 = query.getOrDefault("Version")
  valid_611994 = validateParameter(valid_611994, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_611994 != nil:
    section.add "Version", valid_611994
  var valid_611995 = query.getOrDefault("Filters")
  valid_611995 = validateParameter(valid_611995, JArray, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "Filters", valid_611995
  var valid_611996 = query.getOrDefault("MaxRecords")
  valid_611996 = validateParameter(valid_611996, JInt, required = false, default = nil)
  if valid_611996 != nil:
    section.add "MaxRecords", valid_611996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611997 = header.getOrDefault("X-Amz-Signature")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "X-Amz-Signature", valid_611997
  var valid_611998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-Content-Sha256", valid_611998
  var valid_611999 = header.getOrDefault("X-Amz-Date")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "X-Amz-Date", valid_611999
  var valid_612000 = header.getOrDefault("X-Amz-Credential")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "X-Amz-Credential", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-Security-Token")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-Security-Token", valid_612001
  var valid_612002 = header.getOrDefault("X-Amz-Algorithm")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-Algorithm", valid_612002
  var valid_612003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "X-Amz-SignedHeaders", valid_612003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612004: Call_GetDescribeDBClusters_611988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination.
  ## 
  let valid = call_612004.validator(path, query, header, formData, body)
  let scheme = call_612004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612004.url(scheme.get, call_612004.host, call_612004.base,
                         call_612004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612004, url, valid)

proc call*(call_612005: Call_GetDescribeDBClusters_611988; Marker: string = "";
          DBClusterIdentifier: string = ""; Action: string = "DescribeDBClusters";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_612006 = newJObject()
  add(query_612006, "Marker", newJString(Marker))
  add(query_612006, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_612006, "Action", newJString(Action))
  add(query_612006, "Version", newJString(Version))
  if Filters != nil:
    query_612006.add "Filters", Filters
  add(query_612006, "MaxRecords", newJInt(MaxRecords))
  result = call_612005.call(nil, query_612006, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_611988(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_611989, base: "/",
    url: url_GetDescribeDBClusters_611990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_612051 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBEngineVersions_612053(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_612052(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the available engines.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612054 = query.getOrDefault("Action")
  valid_612054 = validateParameter(valid_612054, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_612054 != nil:
    section.add "Action", valid_612054
  var valid_612055 = query.getOrDefault("Version")
  valid_612055 = validateParameter(valid_612055, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612055 != nil:
    section.add "Version", valid_612055
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612056 = header.getOrDefault("X-Amz-Signature")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-Signature", valid_612056
  var valid_612057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612057 = validateParameter(valid_612057, JString, required = false,
                                 default = nil)
  if valid_612057 != nil:
    section.add "X-Amz-Content-Sha256", valid_612057
  var valid_612058 = header.getOrDefault("X-Amz-Date")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-Date", valid_612058
  var valid_612059 = header.getOrDefault("X-Amz-Credential")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "X-Amz-Credential", valid_612059
  var valid_612060 = header.getOrDefault("X-Amz-Security-Token")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-Security-Token", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-Algorithm")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Algorithm", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-SignedHeaders", valid_612062
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
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  section = newJObject()
  var valid_612063 = formData.getOrDefault("DefaultOnly")
  valid_612063 = validateParameter(valid_612063, JBool, required = false, default = nil)
  if valid_612063 != nil:
    section.add "DefaultOnly", valid_612063
  var valid_612064 = formData.getOrDefault("MaxRecords")
  valid_612064 = validateParameter(valid_612064, JInt, required = false, default = nil)
  if valid_612064 != nil:
    section.add "MaxRecords", valid_612064
  var valid_612065 = formData.getOrDefault("EngineVersion")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "EngineVersion", valid_612065
  var valid_612066 = formData.getOrDefault("Marker")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "Marker", valid_612066
  var valid_612067 = formData.getOrDefault("Engine")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "Engine", valid_612067
  var valid_612068 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_612068 = validateParameter(valid_612068, JBool, required = false, default = nil)
  if valid_612068 != nil:
    section.add "ListSupportedCharacterSets", valid_612068
  var valid_612069 = formData.getOrDefault("ListSupportedTimezones")
  valid_612069 = validateParameter(valid_612069, JBool, required = false, default = nil)
  if valid_612069 != nil:
    section.add "ListSupportedTimezones", valid_612069
  var valid_612070 = formData.getOrDefault("Filters")
  valid_612070 = validateParameter(valid_612070, JArray, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "Filters", valid_612070
  var valid_612071 = formData.getOrDefault("DBParameterGroupFamily")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "DBParameterGroupFamily", valid_612071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612072: Call_PostDescribeDBEngineVersions_612051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available engines.
  ## 
  let valid = call_612072.validator(path, query, header, formData, body)
  let scheme = call_612072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612072.url(scheme.get, call_612072.host, call_612072.base,
                         call_612072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612072, url, valid)

proc call*(call_612073: Call_PostDescribeDBEngineVersions_612051;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions";
          ListSupportedTimezones: bool = false; Filters: JsonNode = nil;
          Version: string = "2014-10-31"; DBParameterGroupFamily: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ## Returns a list of the available engines.
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
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  var query_612074 = newJObject()
  var formData_612075 = newJObject()
  add(formData_612075, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_612075, "MaxRecords", newJInt(MaxRecords))
  add(formData_612075, "EngineVersion", newJString(EngineVersion))
  add(formData_612075, "Marker", newJString(Marker))
  add(formData_612075, "Engine", newJString(Engine))
  add(formData_612075, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_612074, "Action", newJString(Action))
  add(formData_612075, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  if Filters != nil:
    formData_612075.add "Filters", Filters
  add(query_612074, "Version", newJString(Version))
  add(formData_612075, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_612073.call(nil, query_612074, nil, formData_612075, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_612051(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_612052, base: "/",
    url: url_PostDescribeDBEngineVersions_612053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_612027 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBEngineVersions_612029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_612028(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the available engines.
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
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
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
  var valid_612030 = query.getOrDefault("Marker")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "Marker", valid_612030
  var valid_612031 = query.getOrDefault("ListSupportedTimezones")
  valid_612031 = validateParameter(valid_612031, JBool, required = false, default = nil)
  if valid_612031 != nil:
    section.add "ListSupportedTimezones", valid_612031
  var valid_612032 = query.getOrDefault("DBParameterGroupFamily")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "DBParameterGroupFamily", valid_612032
  var valid_612033 = query.getOrDefault("Engine")
  valid_612033 = validateParameter(valid_612033, JString, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "Engine", valid_612033
  var valid_612034 = query.getOrDefault("EngineVersion")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "EngineVersion", valid_612034
  var valid_612035 = query.getOrDefault("Action")
  valid_612035 = validateParameter(valid_612035, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_612035 != nil:
    section.add "Action", valid_612035
  var valid_612036 = query.getOrDefault("ListSupportedCharacterSets")
  valid_612036 = validateParameter(valid_612036, JBool, required = false, default = nil)
  if valid_612036 != nil:
    section.add "ListSupportedCharacterSets", valid_612036
  var valid_612037 = query.getOrDefault("Version")
  valid_612037 = validateParameter(valid_612037, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612037 != nil:
    section.add "Version", valid_612037
  var valid_612038 = query.getOrDefault("Filters")
  valid_612038 = validateParameter(valid_612038, JArray, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "Filters", valid_612038
  var valid_612039 = query.getOrDefault("MaxRecords")
  valid_612039 = validateParameter(valid_612039, JInt, required = false, default = nil)
  if valid_612039 != nil:
    section.add "MaxRecords", valid_612039
  var valid_612040 = query.getOrDefault("DefaultOnly")
  valid_612040 = validateParameter(valid_612040, JBool, required = false, default = nil)
  if valid_612040 != nil:
    section.add "DefaultOnly", valid_612040
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612041 = header.getOrDefault("X-Amz-Signature")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Signature", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Content-Sha256", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Date")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Date", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-Credential")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Credential", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-Security-Token")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-Security-Token", valid_612045
  var valid_612046 = header.getOrDefault("X-Amz-Algorithm")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Algorithm", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-SignedHeaders", valid_612047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612048: Call_GetDescribeDBEngineVersions_612027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available engines.
  ## 
  let valid = call_612048.validator(path, query, header, formData, body)
  let scheme = call_612048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612048.url(scheme.get, call_612048.host, call_612048.base,
                         call_612048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612048, url, valid)

proc call*(call_612049: Call_GetDescribeDBEngineVersions_612027;
          Marker: string = ""; ListSupportedTimezones: bool = false;
          DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2014-10-31";
          Filters: JsonNode = nil; MaxRecords: int = 0; DefaultOnly: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ## Returns a list of the available engines.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ListSupportedTimezones: bool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
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
  var query_612050 = newJObject()
  add(query_612050, "Marker", newJString(Marker))
  add(query_612050, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_612050, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_612050, "Engine", newJString(Engine))
  add(query_612050, "EngineVersion", newJString(EngineVersion))
  add(query_612050, "Action", newJString(Action))
  add(query_612050, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_612050, "Version", newJString(Version))
  if Filters != nil:
    query_612050.add "Filters", Filters
  add(query_612050, "MaxRecords", newJInt(MaxRecords))
  add(query_612050, "DefaultOnly", newJBool(DefaultOnly))
  result = call_612049.call(nil, query_612050, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_612027(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_612028, base: "/",
    url: url_GetDescribeDBEngineVersions_612029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_612095 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBInstances_612097(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_612096(path: JsonNode; query: JsonNode;
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
  var valid_612098 = query.getOrDefault("Action")
  valid_612098 = validateParameter(valid_612098, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_612098 != nil:
    section.add "Action", valid_612098
  var valid_612099 = query.getOrDefault("Version")
  valid_612099 = validateParameter(valid_612099, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612099 != nil:
    section.add "Version", valid_612099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612100 = header.getOrDefault("X-Amz-Signature")
  valid_612100 = validateParameter(valid_612100, JString, required = false,
                                 default = nil)
  if valid_612100 != nil:
    section.add "X-Amz-Signature", valid_612100
  var valid_612101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612101 = validateParameter(valid_612101, JString, required = false,
                                 default = nil)
  if valid_612101 != nil:
    section.add "X-Amz-Content-Sha256", valid_612101
  var valid_612102 = header.getOrDefault("X-Amz-Date")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Date", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-Credential")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Credential", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Security-Token")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Security-Token", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Algorithm")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Algorithm", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-SignedHeaders", valid_612106
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBInstanceIdentifier: JString
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  section = newJObject()
  var valid_612107 = formData.getOrDefault("MaxRecords")
  valid_612107 = validateParameter(valid_612107, JInt, required = false, default = nil)
  if valid_612107 != nil:
    section.add "MaxRecords", valid_612107
  var valid_612108 = formData.getOrDefault("Marker")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "Marker", valid_612108
  var valid_612109 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "DBInstanceIdentifier", valid_612109
  var valid_612110 = formData.getOrDefault("Filters")
  valid_612110 = validateParameter(valid_612110, JArray, required = false,
                                 default = nil)
  if valid_612110 != nil:
    section.add "Filters", valid_612110
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612111: Call_PostDescribeDBInstances_612095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_612111.validator(path, query, header, formData, body)
  let scheme = call_612111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612111.url(scheme.get, call_612111.host, call_612111.base,
                         call_612111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612111, url, valid)

proc call*(call_612112: Call_PostDescribeDBInstances_612095; MaxRecords: int = 0;
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
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  ##   Version: string (required)
  var query_612113 = newJObject()
  var formData_612114 = newJObject()
  add(formData_612114, "MaxRecords", newJInt(MaxRecords))
  add(formData_612114, "Marker", newJString(Marker))
  add(formData_612114, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612113, "Action", newJString(Action))
  if Filters != nil:
    formData_612114.add "Filters", Filters
  add(query_612113, "Version", newJString(Version))
  result = call_612112.call(nil, query_612113, nil, formData_612114, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_612095(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_612096, base: "/",
    url: url_PostDescribeDBInstances_612097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_612076 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBInstances_612078(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_612077(path: JsonNode; query: JsonNode;
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
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_612079 = query.getOrDefault("Marker")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "Marker", valid_612079
  var valid_612080 = query.getOrDefault("DBInstanceIdentifier")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "DBInstanceIdentifier", valid_612080
  var valid_612081 = query.getOrDefault("Action")
  valid_612081 = validateParameter(valid_612081, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_612081 != nil:
    section.add "Action", valid_612081
  var valid_612082 = query.getOrDefault("Version")
  valid_612082 = validateParameter(valid_612082, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612082 != nil:
    section.add "Version", valid_612082
  var valid_612083 = query.getOrDefault("Filters")
  valid_612083 = validateParameter(valid_612083, JArray, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "Filters", valid_612083
  var valid_612084 = query.getOrDefault("MaxRecords")
  valid_612084 = validateParameter(valid_612084, JInt, required = false, default = nil)
  if valid_612084 != nil:
    section.add "MaxRecords", valid_612084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612085 = header.getOrDefault("X-Amz-Signature")
  valid_612085 = validateParameter(valid_612085, JString, required = false,
                                 default = nil)
  if valid_612085 != nil:
    section.add "X-Amz-Signature", valid_612085
  var valid_612086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612086 = validateParameter(valid_612086, JString, required = false,
                                 default = nil)
  if valid_612086 != nil:
    section.add "X-Amz-Content-Sha256", valid_612086
  var valid_612087 = header.getOrDefault("X-Amz-Date")
  valid_612087 = validateParameter(valid_612087, JString, required = false,
                                 default = nil)
  if valid_612087 != nil:
    section.add "X-Amz-Date", valid_612087
  var valid_612088 = header.getOrDefault("X-Amz-Credential")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Credential", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Security-Token")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Security-Token", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Algorithm")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Algorithm", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-SignedHeaders", valid_612091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612092: Call_GetDescribeDBInstances_612076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_612092.validator(path, query, header, formData, body)
  let scheme = call_612092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612092.url(scheme.get, call_612092.host, call_612092.base,
                         call_612092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612092, url, valid)

proc call*(call_612093: Call_GetDescribeDBInstances_612076; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_612094 = newJObject()
  add(query_612094, "Marker", newJString(Marker))
  add(query_612094, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612094, "Action", newJString(Action))
  add(query_612094, "Version", newJString(Version))
  if Filters != nil:
    query_612094.add "Filters", Filters
  add(query_612094, "MaxRecords", newJInt(MaxRecords))
  result = call_612093.call(nil, query_612094, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_612076(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_612077, base: "/",
    url: url_GetDescribeDBInstances_612078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_612134 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSubnetGroups_612136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_612135(path: JsonNode; query: JsonNode;
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
  var valid_612137 = query.getOrDefault("Action")
  valid_612137 = validateParameter(valid_612137, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_612137 != nil:
    section.add "Action", valid_612137
  var valid_612138 = query.getOrDefault("Version")
  valid_612138 = validateParameter(valid_612138, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612138 != nil:
    section.add "Version", valid_612138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612139 = header.getOrDefault("X-Amz-Signature")
  valid_612139 = validateParameter(valid_612139, JString, required = false,
                                 default = nil)
  if valid_612139 != nil:
    section.add "X-Amz-Signature", valid_612139
  var valid_612140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612140 = validateParameter(valid_612140, JString, required = false,
                                 default = nil)
  if valid_612140 != nil:
    section.add "X-Amz-Content-Sha256", valid_612140
  var valid_612141 = header.getOrDefault("X-Amz-Date")
  valid_612141 = validateParameter(valid_612141, JString, required = false,
                                 default = nil)
  if valid_612141 != nil:
    section.add "X-Amz-Date", valid_612141
  var valid_612142 = header.getOrDefault("X-Amz-Credential")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-Credential", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-Security-Token")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-Security-Token", valid_612143
  var valid_612144 = header.getOrDefault("X-Amz-Algorithm")
  valid_612144 = validateParameter(valid_612144, JString, required = false,
                                 default = nil)
  if valid_612144 != nil:
    section.add "X-Amz-Algorithm", valid_612144
  var valid_612145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-SignedHeaders", valid_612145
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBSubnetGroupName: JString
  ##                    : The name of the subnet group to return details for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_612146 = formData.getOrDefault("MaxRecords")
  valid_612146 = validateParameter(valid_612146, JInt, required = false, default = nil)
  if valid_612146 != nil:
    section.add "MaxRecords", valid_612146
  var valid_612147 = formData.getOrDefault("Marker")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "Marker", valid_612147
  var valid_612148 = formData.getOrDefault("DBSubnetGroupName")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "DBSubnetGroupName", valid_612148
  var valid_612149 = formData.getOrDefault("Filters")
  valid_612149 = validateParameter(valid_612149, JArray, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "Filters", valid_612149
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612150: Call_PostDescribeDBSubnetGroups_612134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_612150.validator(path, query, header, formData, body)
  let scheme = call_612150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612150.url(scheme.get, call_612150.host, call_612150.base,
                         call_612150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612150, url, valid)

proc call*(call_612151: Call_PostDescribeDBSubnetGroups_612134;
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
  ##                    : The name of the subnet group to return details for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  var query_612152 = newJObject()
  var formData_612153 = newJObject()
  add(formData_612153, "MaxRecords", newJInt(MaxRecords))
  add(formData_612153, "Marker", newJString(Marker))
  add(query_612152, "Action", newJString(Action))
  add(formData_612153, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_612153.add "Filters", Filters
  add(query_612152, "Version", newJString(Version))
  result = call_612151.call(nil, query_612152, nil, formData_612153, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_612134(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_612135, base: "/",
    url: url_PostDescribeDBSubnetGroups_612136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_612115 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSubnetGroups_612117(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_612116(path: JsonNode; query: JsonNode;
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
  ##                    : The name of the subnet group to return details for.
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_612118 = query.getOrDefault("Marker")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "Marker", valid_612118
  var valid_612119 = query.getOrDefault("Action")
  valid_612119 = validateParameter(valid_612119, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_612119 != nil:
    section.add "Action", valid_612119
  var valid_612120 = query.getOrDefault("DBSubnetGroupName")
  valid_612120 = validateParameter(valid_612120, JString, required = false,
                                 default = nil)
  if valid_612120 != nil:
    section.add "DBSubnetGroupName", valid_612120
  var valid_612121 = query.getOrDefault("Version")
  valid_612121 = validateParameter(valid_612121, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612121 != nil:
    section.add "Version", valid_612121
  var valid_612122 = query.getOrDefault("Filters")
  valid_612122 = validateParameter(valid_612122, JArray, required = false,
                                 default = nil)
  if valid_612122 != nil:
    section.add "Filters", valid_612122
  var valid_612123 = query.getOrDefault("MaxRecords")
  valid_612123 = validateParameter(valid_612123, JInt, required = false, default = nil)
  if valid_612123 != nil:
    section.add "MaxRecords", valid_612123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612124 = header.getOrDefault("X-Amz-Signature")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "X-Amz-Signature", valid_612124
  var valid_612125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612125 = validateParameter(valid_612125, JString, required = false,
                                 default = nil)
  if valid_612125 != nil:
    section.add "X-Amz-Content-Sha256", valid_612125
  var valid_612126 = header.getOrDefault("X-Amz-Date")
  valid_612126 = validateParameter(valid_612126, JString, required = false,
                                 default = nil)
  if valid_612126 != nil:
    section.add "X-Amz-Date", valid_612126
  var valid_612127 = header.getOrDefault("X-Amz-Credential")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "X-Amz-Credential", valid_612127
  var valid_612128 = header.getOrDefault("X-Amz-Security-Token")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "X-Amz-Security-Token", valid_612128
  var valid_612129 = header.getOrDefault("X-Amz-Algorithm")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "X-Amz-Algorithm", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-SignedHeaders", valid_612130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612131: Call_GetDescribeDBSubnetGroups_612115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_612131.validator(path, query, header, formData, body)
  let scheme = call_612131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612131.url(scheme.get, call_612131.host, call_612131.base,
                         call_612131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612131, url, valid)

proc call*(call_612132: Call_GetDescribeDBSubnetGroups_612115; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : The name of the subnet group to return details for.
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_612133 = newJObject()
  add(query_612133, "Marker", newJString(Marker))
  add(query_612133, "Action", newJString(Action))
  add(query_612133, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612133, "Version", newJString(Version))
  if Filters != nil:
    query_612133.add "Filters", Filters
  add(query_612133, "MaxRecords", newJInt(MaxRecords))
  result = call_612132.call(nil, query_612133, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_612115(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_612116, base: "/",
    url: url_GetDescribeDBSubnetGroups_612117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_612173 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEngineDefaultClusterParameters_612175(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultClusterParameters_612174(path: JsonNode;
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
  var valid_612176 = query.getOrDefault("Action")
  valid_612176 = validateParameter(valid_612176, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_612176 != nil:
    section.add "Action", valid_612176
  var valid_612177 = query.getOrDefault("Version")
  valid_612177 = validateParameter(valid_612177, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612177 != nil:
    section.add "Version", valid_612177
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612178 = header.getOrDefault("X-Amz-Signature")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Signature", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Content-Sha256", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Date")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Date", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Credential")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Credential", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-Security-Token")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Security-Token", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Algorithm")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Algorithm", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-SignedHeaders", valid_612184
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  section = newJObject()
  var valid_612185 = formData.getOrDefault("MaxRecords")
  valid_612185 = validateParameter(valid_612185, JInt, required = false, default = nil)
  if valid_612185 != nil:
    section.add "MaxRecords", valid_612185
  var valid_612186 = formData.getOrDefault("Marker")
  valid_612186 = validateParameter(valid_612186, JString, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "Marker", valid_612186
  var valid_612187 = formData.getOrDefault("Filters")
  valid_612187 = validateParameter(valid_612187, JArray, required = false,
                                 default = nil)
  if valid_612187 != nil:
    section.add "Filters", valid_612187
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_612188 = formData.getOrDefault("DBParameterGroupFamily")
  valid_612188 = validateParameter(valid_612188, JString, required = true,
                                 default = nil)
  if valid_612188 != nil:
    section.add "DBParameterGroupFamily", valid_612188
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612189: Call_PostDescribeEngineDefaultClusterParameters_612173;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_612189.validator(path, query, header, formData, body)
  let scheme = call_612189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612189.url(scheme.get, call_612189.host, call_612189.base,
                         call_612189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612189, url, valid)

proc call*(call_612190: Call_PostDescribeEngineDefaultClusterParameters_612173;
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
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  var query_612191 = newJObject()
  var formData_612192 = newJObject()
  add(formData_612192, "MaxRecords", newJInt(MaxRecords))
  add(formData_612192, "Marker", newJString(Marker))
  add(query_612191, "Action", newJString(Action))
  if Filters != nil:
    formData_612192.add "Filters", Filters
  add(query_612191, "Version", newJString(Version))
  add(formData_612192, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_612190.call(nil, query_612191, nil, formData_612192, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_612173(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_612174,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_612175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_612154 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEngineDefaultClusterParameters_612156(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultClusterParameters_612155(path: JsonNode;
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
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_612157 = query.getOrDefault("Marker")
  valid_612157 = validateParameter(valid_612157, JString, required = false,
                                 default = nil)
  if valid_612157 != nil:
    section.add "Marker", valid_612157
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_612158 = query.getOrDefault("DBParameterGroupFamily")
  valid_612158 = validateParameter(valid_612158, JString, required = true,
                                 default = nil)
  if valid_612158 != nil:
    section.add "DBParameterGroupFamily", valid_612158
  var valid_612159 = query.getOrDefault("Action")
  valid_612159 = validateParameter(valid_612159, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_612159 != nil:
    section.add "Action", valid_612159
  var valid_612160 = query.getOrDefault("Version")
  valid_612160 = validateParameter(valid_612160, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612160 != nil:
    section.add "Version", valid_612160
  var valid_612161 = query.getOrDefault("Filters")
  valid_612161 = validateParameter(valid_612161, JArray, required = false,
                                 default = nil)
  if valid_612161 != nil:
    section.add "Filters", valid_612161
  var valid_612162 = query.getOrDefault("MaxRecords")
  valid_612162 = validateParameter(valid_612162, JInt, required = false, default = nil)
  if valid_612162 != nil:
    section.add "MaxRecords", valid_612162
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612163 = header.getOrDefault("X-Amz-Signature")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Signature", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Content-Sha256", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Date")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Date", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Credential")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Credential", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Security-Token")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Security-Token", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-Algorithm")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-Algorithm", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-SignedHeaders", valid_612169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612170: Call_GetDescribeEngineDefaultClusterParameters_612154;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_612170.validator(path, query, header, formData, body)
  let scheme = call_612170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612170.url(scheme.get, call_612170.host, call_612170.base,
                         call_612170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612170, url, valid)

proc call*(call_612171: Call_GetDescribeEngineDefaultClusterParameters_612154;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultClusterParameters";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_612172 = newJObject()
  add(query_612172, "Marker", newJString(Marker))
  add(query_612172, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_612172, "Action", newJString(Action))
  add(query_612172, "Version", newJString(Version))
  if Filters != nil:
    query_612172.add "Filters", Filters
  add(query_612172, "MaxRecords", newJInt(MaxRecords))
  result = call_612171.call(nil, query_612172, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_612154(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_612155,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_612156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_612210 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEventCategories_612212(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_612211(path: JsonNode; query: JsonNode;
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
  var valid_612213 = query.getOrDefault("Action")
  valid_612213 = validateParameter(valid_612213, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_612213 != nil:
    section.add "Action", valid_612213
  var valid_612214 = query.getOrDefault("Version")
  valid_612214 = validateParameter(valid_612214, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612214 != nil:
    section.add "Version", valid_612214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612215 = header.getOrDefault("X-Amz-Signature")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Signature", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Content-Sha256", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-Date")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-Date", valid_612217
  var valid_612218 = header.getOrDefault("X-Amz-Credential")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-Credential", valid_612218
  var valid_612219 = header.getOrDefault("X-Amz-Security-Token")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "X-Amz-Security-Token", valid_612219
  var valid_612220 = header.getOrDefault("X-Amz-Algorithm")
  valid_612220 = validateParameter(valid_612220, JString, required = false,
                                 default = nil)
  if valid_612220 != nil:
    section.add "X-Amz-Algorithm", valid_612220
  var valid_612221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612221 = validateParameter(valid_612221, JString, required = false,
                                 default = nil)
  if valid_612221 != nil:
    section.add "X-Amz-SignedHeaders", valid_612221
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_612222 = formData.getOrDefault("SourceType")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "SourceType", valid_612222
  var valid_612223 = formData.getOrDefault("Filters")
  valid_612223 = validateParameter(valid_612223, JArray, required = false,
                                 default = nil)
  if valid_612223 != nil:
    section.add "Filters", valid_612223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612224: Call_PostDescribeEventCategories_612210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_612224.validator(path, query, header, formData, body)
  let scheme = call_612224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612224.url(scheme.get, call_612224.host, call_612224.base,
                         call_612224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612224, url, valid)

proc call*(call_612225: Call_PostDescribeEventCategories_612210;
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
  var query_612226 = newJObject()
  var formData_612227 = newJObject()
  add(formData_612227, "SourceType", newJString(SourceType))
  add(query_612226, "Action", newJString(Action))
  if Filters != nil:
    formData_612227.add "Filters", Filters
  add(query_612226, "Version", newJString(Version))
  result = call_612225.call(nil, query_612226, nil, formData_612227, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_612210(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_612211, base: "/",
    url: url_PostDescribeEventCategories_612212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_612193 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEventCategories_612195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_612194(path: JsonNode; query: JsonNode;
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
  var valid_612196 = query.getOrDefault("SourceType")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "SourceType", valid_612196
  var valid_612197 = query.getOrDefault("Action")
  valid_612197 = validateParameter(valid_612197, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_612197 != nil:
    section.add "Action", valid_612197
  var valid_612198 = query.getOrDefault("Version")
  valid_612198 = validateParameter(valid_612198, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612198 != nil:
    section.add "Version", valid_612198
  var valid_612199 = query.getOrDefault("Filters")
  valid_612199 = validateParameter(valid_612199, JArray, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "Filters", valid_612199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612200 = header.getOrDefault("X-Amz-Signature")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-Signature", valid_612200
  var valid_612201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "X-Amz-Content-Sha256", valid_612201
  var valid_612202 = header.getOrDefault("X-Amz-Date")
  valid_612202 = validateParameter(valid_612202, JString, required = false,
                                 default = nil)
  if valid_612202 != nil:
    section.add "X-Amz-Date", valid_612202
  var valid_612203 = header.getOrDefault("X-Amz-Credential")
  valid_612203 = validateParameter(valid_612203, JString, required = false,
                                 default = nil)
  if valid_612203 != nil:
    section.add "X-Amz-Credential", valid_612203
  var valid_612204 = header.getOrDefault("X-Amz-Security-Token")
  valid_612204 = validateParameter(valid_612204, JString, required = false,
                                 default = nil)
  if valid_612204 != nil:
    section.add "X-Amz-Security-Token", valid_612204
  var valid_612205 = header.getOrDefault("X-Amz-Algorithm")
  valid_612205 = validateParameter(valid_612205, JString, required = false,
                                 default = nil)
  if valid_612205 != nil:
    section.add "X-Amz-Algorithm", valid_612205
  var valid_612206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612206 = validateParameter(valid_612206, JString, required = false,
                                 default = nil)
  if valid_612206 != nil:
    section.add "X-Amz-SignedHeaders", valid_612206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612207: Call_GetDescribeEventCategories_612193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_612207.validator(path, query, header, formData, body)
  let scheme = call_612207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612207.url(scheme.get, call_612207.host, call_612207.base,
                         call_612207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612207, url, valid)

proc call*(call_612208: Call_GetDescribeEventCategories_612193;
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
  var query_612209 = newJObject()
  add(query_612209, "SourceType", newJString(SourceType))
  add(query_612209, "Action", newJString(Action))
  add(query_612209, "Version", newJString(Version))
  if Filters != nil:
    query_612209.add "Filters", Filters
  result = call_612208.call(nil, query_612209, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_612193(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_612194, base: "/",
    url: url_GetDescribeEventCategories_612195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_612252 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEvents_612254(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_612253(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612255 = query.getOrDefault("Action")
  valid_612255 = validateParameter(valid_612255, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612255 != nil:
    section.add "Action", valid_612255
  var valid_612256 = query.getOrDefault("Version")
  valid_612256 = validateParameter(valid_612256, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612256 != nil:
    section.add "Version", valid_612256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612257 = header.getOrDefault("X-Amz-Signature")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-Signature", valid_612257
  var valid_612258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612258 = validateParameter(valid_612258, JString, required = false,
                                 default = nil)
  if valid_612258 != nil:
    section.add "X-Amz-Content-Sha256", valid_612258
  var valid_612259 = header.getOrDefault("X-Amz-Date")
  valid_612259 = validateParameter(valid_612259, JString, required = false,
                                 default = nil)
  if valid_612259 != nil:
    section.add "X-Amz-Date", valid_612259
  var valid_612260 = header.getOrDefault("X-Amz-Credential")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-Credential", valid_612260
  var valid_612261 = header.getOrDefault("X-Amz-Security-Token")
  valid_612261 = validateParameter(valid_612261, JString, required = false,
                                 default = nil)
  if valid_612261 != nil:
    section.add "X-Amz-Security-Token", valid_612261
  var valid_612262 = header.getOrDefault("X-Amz-Algorithm")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "X-Amz-Algorithm", valid_612262
  var valid_612263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612263 = validateParameter(valid_612263, JString, required = false,
                                 default = nil)
  if valid_612263 != nil:
    section.add "X-Amz-SignedHeaders", valid_612263
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
  var valid_612264 = formData.getOrDefault("MaxRecords")
  valid_612264 = validateParameter(valid_612264, JInt, required = false, default = nil)
  if valid_612264 != nil:
    section.add "MaxRecords", valid_612264
  var valid_612265 = formData.getOrDefault("Marker")
  valid_612265 = validateParameter(valid_612265, JString, required = false,
                                 default = nil)
  if valid_612265 != nil:
    section.add "Marker", valid_612265
  var valid_612266 = formData.getOrDefault("SourceIdentifier")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "SourceIdentifier", valid_612266
  var valid_612267 = formData.getOrDefault("SourceType")
  valid_612267 = validateParameter(valid_612267, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_612267 != nil:
    section.add "SourceType", valid_612267
  var valid_612268 = formData.getOrDefault("Duration")
  valid_612268 = validateParameter(valid_612268, JInt, required = false, default = nil)
  if valid_612268 != nil:
    section.add "Duration", valid_612268
  var valid_612269 = formData.getOrDefault("EndTime")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "EndTime", valid_612269
  var valid_612270 = formData.getOrDefault("StartTime")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "StartTime", valid_612270
  var valid_612271 = formData.getOrDefault("EventCategories")
  valid_612271 = validateParameter(valid_612271, JArray, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "EventCategories", valid_612271
  var valid_612272 = formData.getOrDefault("Filters")
  valid_612272 = validateParameter(valid_612272, JArray, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "Filters", valid_612272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612273: Call_PostDescribeEvents_612252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_612273.validator(path, query, header, formData, body)
  let scheme = call_612273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612273.url(scheme.get, call_612273.host, call_612273.base,
                         call_612273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612273, url, valid)

proc call*(call_612274: Call_PostDescribeEvents_612252; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeEvents
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
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
  var query_612275 = newJObject()
  var formData_612276 = newJObject()
  add(formData_612276, "MaxRecords", newJInt(MaxRecords))
  add(formData_612276, "Marker", newJString(Marker))
  add(formData_612276, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_612276, "SourceType", newJString(SourceType))
  add(formData_612276, "Duration", newJInt(Duration))
  add(formData_612276, "EndTime", newJString(EndTime))
  add(formData_612276, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_612276.add "EventCategories", EventCategories
  add(query_612275, "Action", newJString(Action))
  if Filters != nil:
    formData_612276.add "Filters", Filters
  add(query_612275, "Version", newJString(Version))
  result = call_612274.call(nil, query_612275, nil, formData_612276, nil)

var postDescribeEvents* = Call_PostDescribeEvents_612252(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_612253, base: "/",
    url: url_PostDescribeEvents_612254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_612228 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEvents_612230(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_612229(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
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
  var valid_612231 = query.getOrDefault("Marker")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "Marker", valid_612231
  var valid_612232 = query.getOrDefault("SourceType")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_612232 != nil:
    section.add "SourceType", valid_612232
  var valid_612233 = query.getOrDefault("SourceIdentifier")
  valid_612233 = validateParameter(valid_612233, JString, required = false,
                                 default = nil)
  if valid_612233 != nil:
    section.add "SourceIdentifier", valid_612233
  var valid_612234 = query.getOrDefault("EventCategories")
  valid_612234 = validateParameter(valid_612234, JArray, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "EventCategories", valid_612234
  var valid_612235 = query.getOrDefault("Action")
  valid_612235 = validateParameter(valid_612235, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612235 != nil:
    section.add "Action", valid_612235
  var valid_612236 = query.getOrDefault("StartTime")
  valid_612236 = validateParameter(valid_612236, JString, required = false,
                                 default = nil)
  if valid_612236 != nil:
    section.add "StartTime", valid_612236
  var valid_612237 = query.getOrDefault("Duration")
  valid_612237 = validateParameter(valid_612237, JInt, required = false, default = nil)
  if valid_612237 != nil:
    section.add "Duration", valid_612237
  var valid_612238 = query.getOrDefault("EndTime")
  valid_612238 = validateParameter(valid_612238, JString, required = false,
                                 default = nil)
  if valid_612238 != nil:
    section.add "EndTime", valid_612238
  var valid_612239 = query.getOrDefault("Version")
  valid_612239 = validateParameter(valid_612239, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612239 != nil:
    section.add "Version", valid_612239
  var valid_612240 = query.getOrDefault("Filters")
  valid_612240 = validateParameter(valid_612240, JArray, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "Filters", valid_612240
  var valid_612241 = query.getOrDefault("MaxRecords")
  valid_612241 = validateParameter(valid_612241, JInt, required = false, default = nil)
  if valid_612241 != nil:
    section.add "MaxRecords", valid_612241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612242 = header.getOrDefault("X-Amz-Signature")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "X-Amz-Signature", valid_612242
  var valid_612243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "X-Amz-Content-Sha256", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-Date")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Date", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Credential")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Credential", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-Security-Token")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-Security-Token", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-Algorithm")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-Algorithm", valid_612247
  var valid_612248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "X-Amz-SignedHeaders", valid_612248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612249: Call_GetDescribeEvents_612228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_612249.validator(path, query, header, formData, body)
  let scheme = call_612249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612249.url(scheme.get, call_612249.host, call_612249.base,
                         call_612249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612249, url, valid)

proc call*(call_612250: Call_GetDescribeEvents_612228; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEvents
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
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
  var query_612251 = newJObject()
  add(query_612251, "Marker", newJString(Marker))
  add(query_612251, "SourceType", newJString(SourceType))
  add(query_612251, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_612251.add "EventCategories", EventCategories
  add(query_612251, "Action", newJString(Action))
  add(query_612251, "StartTime", newJString(StartTime))
  add(query_612251, "Duration", newJInt(Duration))
  add(query_612251, "EndTime", newJString(EndTime))
  add(query_612251, "Version", newJString(Version))
  if Filters != nil:
    query_612251.add "Filters", Filters
  add(query_612251, "MaxRecords", newJInt(MaxRecords))
  result = call_612250.call(nil, query_612251, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_612228(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_612229,
    base: "/", url: url_GetDescribeEvents_612230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_612300 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOrderableDBInstanceOptions_612302(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_612301(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612303 = query.getOrDefault("Action")
  valid_612303 = validateParameter(valid_612303, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_612303 != nil:
    section.add "Action", valid_612303
  var valid_612304 = query.getOrDefault("Version")
  valid_612304 = validateParameter(valid_612304, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612304 != nil:
    section.add "Version", valid_612304
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612305 = header.getOrDefault("X-Amz-Signature")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-Signature", valid_612305
  var valid_612306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612306 = validateParameter(valid_612306, JString, required = false,
                                 default = nil)
  if valid_612306 != nil:
    section.add "X-Amz-Content-Sha256", valid_612306
  var valid_612307 = header.getOrDefault("X-Amz-Date")
  valid_612307 = validateParameter(valid_612307, JString, required = false,
                                 default = nil)
  if valid_612307 != nil:
    section.add "X-Amz-Date", valid_612307
  var valid_612308 = header.getOrDefault("X-Amz-Credential")
  valid_612308 = validateParameter(valid_612308, JString, required = false,
                                 default = nil)
  if valid_612308 != nil:
    section.add "X-Amz-Credential", valid_612308
  var valid_612309 = header.getOrDefault("X-Amz-Security-Token")
  valid_612309 = validateParameter(valid_612309, JString, required = false,
                                 default = nil)
  if valid_612309 != nil:
    section.add "X-Amz-Security-Token", valid_612309
  var valid_612310 = header.getOrDefault("X-Amz-Algorithm")
  valid_612310 = validateParameter(valid_612310, JString, required = false,
                                 default = nil)
  if valid_612310 != nil:
    section.add "X-Amz-Algorithm", valid_612310
  var valid_612311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612311 = validateParameter(valid_612311, JString, required = false,
                                 default = nil)
  if valid_612311 != nil:
    section.add "X-Amz-SignedHeaders", valid_612311
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_612312 = formData.getOrDefault("DBInstanceClass")
  valid_612312 = validateParameter(valid_612312, JString, required = false,
                                 default = nil)
  if valid_612312 != nil:
    section.add "DBInstanceClass", valid_612312
  var valid_612313 = formData.getOrDefault("MaxRecords")
  valid_612313 = validateParameter(valid_612313, JInt, required = false, default = nil)
  if valid_612313 != nil:
    section.add "MaxRecords", valid_612313
  var valid_612314 = formData.getOrDefault("EngineVersion")
  valid_612314 = validateParameter(valid_612314, JString, required = false,
                                 default = nil)
  if valid_612314 != nil:
    section.add "EngineVersion", valid_612314
  var valid_612315 = formData.getOrDefault("Marker")
  valid_612315 = validateParameter(valid_612315, JString, required = false,
                                 default = nil)
  if valid_612315 != nil:
    section.add "Marker", valid_612315
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_612316 = formData.getOrDefault("Engine")
  valid_612316 = validateParameter(valid_612316, JString, required = true,
                                 default = nil)
  if valid_612316 != nil:
    section.add "Engine", valid_612316
  var valid_612317 = formData.getOrDefault("Vpc")
  valid_612317 = validateParameter(valid_612317, JBool, required = false, default = nil)
  if valid_612317 != nil:
    section.add "Vpc", valid_612317
  var valid_612318 = formData.getOrDefault("LicenseModel")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "LicenseModel", valid_612318
  var valid_612319 = formData.getOrDefault("Filters")
  valid_612319 = validateParameter(valid_612319, JArray, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "Filters", valid_612319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612320: Call_PostDescribeOrderableDBInstanceOptions_612300;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  let valid = call_612320.validator(path, query, header, formData, body)
  let scheme = call_612320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612320.url(scheme.get, call_612320.host, call_612320.base,
                         call_612320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612320, url, valid)

proc call*(call_612321: Call_PostDescribeOrderableDBInstanceOptions_612300;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable instance options for the specified engine.
  ##   DBInstanceClass: string
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   Action: string (required)
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  var query_612322 = newJObject()
  var formData_612323 = newJObject()
  add(formData_612323, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612323, "MaxRecords", newJInt(MaxRecords))
  add(formData_612323, "EngineVersion", newJString(EngineVersion))
  add(formData_612323, "Marker", newJString(Marker))
  add(formData_612323, "Engine", newJString(Engine))
  add(formData_612323, "Vpc", newJBool(Vpc))
  add(query_612322, "Action", newJString(Action))
  add(formData_612323, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_612323.add "Filters", Filters
  add(query_612322, "Version", newJString(Version))
  result = call_612321.call(nil, query_612322, nil, formData_612323, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_612300(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_612301, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_612302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_612277 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOrderableDBInstanceOptions_612279(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_612278(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_612280 = query.getOrDefault("Marker")
  valid_612280 = validateParameter(valid_612280, JString, required = false,
                                 default = nil)
  if valid_612280 != nil:
    section.add "Marker", valid_612280
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_612281 = query.getOrDefault("Engine")
  valid_612281 = validateParameter(valid_612281, JString, required = true,
                                 default = nil)
  if valid_612281 != nil:
    section.add "Engine", valid_612281
  var valid_612282 = query.getOrDefault("LicenseModel")
  valid_612282 = validateParameter(valid_612282, JString, required = false,
                                 default = nil)
  if valid_612282 != nil:
    section.add "LicenseModel", valid_612282
  var valid_612283 = query.getOrDefault("Vpc")
  valid_612283 = validateParameter(valid_612283, JBool, required = false, default = nil)
  if valid_612283 != nil:
    section.add "Vpc", valid_612283
  var valid_612284 = query.getOrDefault("EngineVersion")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "EngineVersion", valid_612284
  var valid_612285 = query.getOrDefault("Action")
  valid_612285 = validateParameter(valid_612285, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_612285 != nil:
    section.add "Action", valid_612285
  var valid_612286 = query.getOrDefault("Version")
  valid_612286 = validateParameter(valid_612286, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612286 != nil:
    section.add "Version", valid_612286
  var valid_612287 = query.getOrDefault("DBInstanceClass")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "DBInstanceClass", valid_612287
  var valid_612288 = query.getOrDefault("Filters")
  valid_612288 = validateParameter(valid_612288, JArray, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "Filters", valid_612288
  var valid_612289 = query.getOrDefault("MaxRecords")
  valid_612289 = validateParameter(valid_612289, JInt, required = false, default = nil)
  if valid_612289 != nil:
    section.add "MaxRecords", valid_612289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612290 = header.getOrDefault("X-Amz-Signature")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "X-Amz-Signature", valid_612290
  var valid_612291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612291 = validateParameter(valid_612291, JString, required = false,
                                 default = nil)
  if valid_612291 != nil:
    section.add "X-Amz-Content-Sha256", valid_612291
  var valid_612292 = header.getOrDefault("X-Amz-Date")
  valid_612292 = validateParameter(valid_612292, JString, required = false,
                                 default = nil)
  if valid_612292 != nil:
    section.add "X-Amz-Date", valid_612292
  var valid_612293 = header.getOrDefault("X-Amz-Credential")
  valid_612293 = validateParameter(valid_612293, JString, required = false,
                                 default = nil)
  if valid_612293 != nil:
    section.add "X-Amz-Credential", valid_612293
  var valid_612294 = header.getOrDefault("X-Amz-Security-Token")
  valid_612294 = validateParameter(valid_612294, JString, required = false,
                                 default = nil)
  if valid_612294 != nil:
    section.add "X-Amz-Security-Token", valid_612294
  var valid_612295 = header.getOrDefault("X-Amz-Algorithm")
  valid_612295 = validateParameter(valid_612295, JString, required = false,
                                 default = nil)
  if valid_612295 != nil:
    section.add "X-Amz-Algorithm", valid_612295
  var valid_612296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612296 = validateParameter(valid_612296, JString, required = false,
                                 default = nil)
  if valid_612296 != nil:
    section.add "X-Amz-SignedHeaders", valid_612296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612297: Call_GetDescribeOrderableDBInstanceOptions_612277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  let valid = call_612297.validator(path, query, header, formData, body)
  let scheme = call_612297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612297.url(scheme.get, call_612297.host, call_612297.base,
                         call_612297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612297, url, valid)

proc call*(call_612298: Call_GetDescribeOrderableDBInstanceOptions_612277;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2014-10-31"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable instance options for the specified engine.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_612299 = newJObject()
  add(query_612299, "Marker", newJString(Marker))
  add(query_612299, "Engine", newJString(Engine))
  add(query_612299, "LicenseModel", newJString(LicenseModel))
  add(query_612299, "Vpc", newJBool(Vpc))
  add(query_612299, "EngineVersion", newJString(EngineVersion))
  add(query_612299, "Action", newJString(Action))
  add(query_612299, "Version", newJString(Version))
  add(query_612299, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_612299.add "Filters", Filters
  add(query_612299, "MaxRecords", newJInt(MaxRecords))
  result = call_612298.call(nil, query_612299, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_612277(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_612278, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_612279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_612343 = ref object of OpenApiRestCall_610642
proc url_PostDescribePendingMaintenanceActions_612345(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribePendingMaintenanceActions_612344(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612346 = query.getOrDefault("Action")
  valid_612346 = validateParameter(valid_612346, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_612346 != nil:
    section.add "Action", valid_612346
  var valid_612347 = query.getOrDefault("Version")
  valid_612347 = validateParameter(valid_612347, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612347 != nil:
    section.add "Version", valid_612347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612348 = header.getOrDefault("X-Amz-Signature")
  valid_612348 = validateParameter(valid_612348, JString, required = false,
                                 default = nil)
  if valid_612348 != nil:
    section.add "X-Amz-Signature", valid_612348
  var valid_612349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Content-Sha256", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-Date")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-Date", valid_612350
  var valid_612351 = header.getOrDefault("X-Amz-Credential")
  valid_612351 = validateParameter(valid_612351, JString, required = false,
                                 default = nil)
  if valid_612351 != nil:
    section.add "X-Amz-Credential", valid_612351
  var valid_612352 = header.getOrDefault("X-Amz-Security-Token")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-Security-Token", valid_612352
  var valid_612353 = header.getOrDefault("X-Amz-Algorithm")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "X-Amz-Algorithm", valid_612353
  var valid_612354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = nil)
  if valid_612354 != nil:
    section.add "X-Amz-SignedHeaders", valid_612354
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  section = newJObject()
  var valid_612355 = formData.getOrDefault("MaxRecords")
  valid_612355 = validateParameter(valid_612355, JInt, required = false, default = nil)
  if valid_612355 != nil:
    section.add "MaxRecords", valid_612355
  var valid_612356 = formData.getOrDefault("Marker")
  valid_612356 = validateParameter(valid_612356, JString, required = false,
                                 default = nil)
  if valid_612356 != nil:
    section.add "Marker", valid_612356
  var valid_612357 = formData.getOrDefault("ResourceIdentifier")
  valid_612357 = validateParameter(valid_612357, JString, required = false,
                                 default = nil)
  if valid_612357 != nil:
    section.add "ResourceIdentifier", valid_612357
  var valid_612358 = formData.getOrDefault("Filters")
  valid_612358 = validateParameter(valid_612358, JArray, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "Filters", valid_612358
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612359: Call_PostDescribePendingMaintenanceActions_612343;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ## 
  let valid = call_612359.validator(path, query, header, formData, body)
  let scheme = call_612359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612359.url(scheme.get, call_612359.host, call_612359.base,
                         call_612359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612359, url, valid)

proc call*(call_612360: Call_PostDescribePendingMaintenanceActions_612343;
          MaxRecords: int = 0; Marker: string = ""; ResourceIdentifier: string = "";
          Action: string = "DescribePendingMaintenanceActions";
          Filters: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   Version: string (required)
  var query_612361 = newJObject()
  var formData_612362 = newJObject()
  add(formData_612362, "MaxRecords", newJInt(MaxRecords))
  add(formData_612362, "Marker", newJString(Marker))
  add(formData_612362, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_612361, "Action", newJString(Action))
  if Filters != nil:
    formData_612362.add "Filters", Filters
  add(query_612361, "Version", newJString(Version))
  result = call_612360.call(nil, query_612361, nil, formData_612362, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_612343(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_612344, base: "/",
    url: url_PostDescribePendingMaintenanceActions_612345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_612324 = ref object of OpenApiRestCall_610642
proc url_GetDescribePendingMaintenanceActions_612326(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribePendingMaintenanceActions_612325(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
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
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_612327 = query.getOrDefault("ResourceIdentifier")
  valid_612327 = validateParameter(valid_612327, JString, required = false,
                                 default = nil)
  if valid_612327 != nil:
    section.add "ResourceIdentifier", valid_612327
  var valid_612328 = query.getOrDefault("Marker")
  valid_612328 = validateParameter(valid_612328, JString, required = false,
                                 default = nil)
  if valid_612328 != nil:
    section.add "Marker", valid_612328
  var valid_612329 = query.getOrDefault("Action")
  valid_612329 = validateParameter(valid_612329, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_612329 != nil:
    section.add "Action", valid_612329
  var valid_612330 = query.getOrDefault("Version")
  valid_612330 = validateParameter(valid_612330, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612330 != nil:
    section.add "Version", valid_612330
  var valid_612331 = query.getOrDefault("Filters")
  valid_612331 = validateParameter(valid_612331, JArray, required = false,
                                 default = nil)
  if valid_612331 != nil:
    section.add "Filters", valid_612331
  var valid_612332 = query.getOrDefault("MaxRecords")
  valid_612332 = validateParameter(valid_612332, JInt, required = false, default = nil)
  if valid_612332 != nil:
    section.add "MaxRecords", valid_612332
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612333 = header.getOrDefault("X-Amz-Signature")
  valid_612333 = validateParameter(valid_612333, JString, required = false,
                                 default = nil)
  if valid_612333 != nil:
    section.add "X-Amz-Signature", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-Content-Sha256", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-Date")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-Date", valid_612335
  var valid_612336 = header.getOrDefault("X-Amz-Credential")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Credential", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-Security-Token")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Security-Token", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-Algorithm")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-Algorithm", valid_612338
  var valid_612339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "X-Amz-SignedHeaders", valid_612339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612340: Call_GetDescribePendingMaintenanceActions_612324;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ## 
  let valid = call_612340.validator(path, query, header, formData, body)
  let scheme = call_612340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612340.url(scheme.get, call_612340.host, call_612340.base,
                         call_612340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612340, url, valid)

proc call*(call_612341: Call_GetDescribePendingMaintenanceActions_612324;
          ResourceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribePendingMaintenanceActions";
          Version: string = "2014-10-31"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  var query_612342 = newJObject()
  add(query_612342, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_612342, "Marker", newJString(Marker))
  add(query_612342, "Action", newJString(Action))
  add(query_612342, "Version", newJString(Version))
  if Filters != nil:
    query_612342.add "Filters", Filters
  add(query_612342, "MaxRecords", newJInt(MaxRecords))
  result = call_612341.call(nil, query_612342, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_612324(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_612325, base: "/",
    url: url_GetDescribePendingMaintenanceActions_612326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_612380 = ref object of OpenApiRestCall_610642
proc url_PostFailoverDBCluster_612382(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostFailoverDBCluster_612381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612383 = query.getOrDefault("Action")
  valid_612383 = validateParameter(valid_612383, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_612383 != nil:
    section.add "Action", valid_612383
  var valid_612384 = query.getOrDefault("Version")
  valid_612384 = validateParameter(valid_612384, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612384 != nil:
    section.add "Version", valid_612384
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612385 = header.getOrDefault("X-Amz-Signature")
  valid_612385 = validateParameter(valid_612385, JString, required = false,
                                 default = nil)
  if valid_612385 != nil:
    section.add "X-Amz-Signature", valid_612385
  var valid_612386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612386 = validateParameter(valid_612386, JString, required = false,
                                 default = nil)
  if valid_612386 != nil:
    section.add "X-Amz-Content-Sha256", valid_612386
  var valid_612387 = header.getOrDefault("X-Amz-Date")
  valid_612387 = validateParameter(valid_612387, JString, required = false,
                                 default = nil)
  if valid_612387 != nil:
    section.add "X-Amz-Date", valid_612387
  var valid_612388 = header.getOrDefault("X-Amz-Credential")
  valid_612388 = validateParameter(valid_612388, JString, required = false,
                                 default = nil)
  if valid_612388 != nil:
    section.add "X-Amz-Credential", valid_612388
  var valid_612389 = header.getOrDefault("X-Amz-Security-Token")
  valid_612389 = validateParameter(valid_612389, JString, required = false,
                                 default = nil)
  if valid_612389 != nil:
    section.add "X-Amz-Security-Token", valid_612389
  var valid_612390 = header.getOrDefault("X-Amz-Algorithm")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-Algorithm", valid_612390
  var valid_612391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "X-Amz-SignedHeaders", valid_612391
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_612392 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_612392 = validateParameter(valid_612392, JString, required = false,
                                 default = nil)
  if valid_612392 != nil:
    section.add "TargetDBInstanceIdentifier", valid_612392
  var valid_612393 = formData.getOrDefault("DBClusterIdentifier")
  valid_612393 = validateParameter(valid_612393, JString, required = false,
                                 default = nil)
  if valid_612393 != nil:
    section.add "DBClusterIdentifier", valid_612393
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612394: Call_PostFailoverDBCluster_612380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_612394.validator(path, query, header, formData, body)
  let scheme = call_612394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612394.url(scheme.get, call_612394.host, call_612394.base,
                         call_612394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612394, url, valid)

proc call*(call_612395: Call_PostFailoverDBCluster_612380;
          Action: string = "FailoverDBCluster";
          TargetDBInstanceIdentifier: string = ""; Version: string = "2014-10-31";
          DBClusterIdentifier: string = ""): Recallable =
  ## postFailoverDBCluster
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ##   Action: string (required)
  ##   TargetDBInstanceIdentifier: string
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string
  ##                      : <p>A cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  var query_612396 = newJObject()
  var formData_612397 = newJObject()
  add(query_612396, "Action", newJString(Action))
  add(formData_612397, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_612396, "Version", newJString(Version))
  add(formData_612397, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_612395.call(nil, query_612396, nil, formData_612397, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_612380(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_612381, base: "/",
    url: url_PostFailoverDBCluster_612382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_612363 = ref object of OpenApiRestCall_610642
proc url_GetFailoverDBCluster_612365(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFailoverDBCluster_612364(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString
  ##                      : <p>A cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612366 = query.getOrDefault("DBClusterIdentifier")
  valid_612366 = validateParameter(valid_612366, JString, required = false,
                                 default = nil)
  if valid_612366 != nil:
    section.add "DBClusterIdentifier", valid_612366
  var valid_612367 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "TargetDBInstanceIdentifier", valid_612367
  var valid_612368 = query.getOrDefault("Action")
  valid_612368 = validateParameter(valid_612368, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_612368 != nil:
    section.add "Action", valid_612368
  var valid_612369 = query.getOrDefault("Version")
  valid_612369 = validateParameter(valid_612369, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612369 != nil:
    section.add "Version", valid_612369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612370 = header.getOrDefault("X-Amz-Signature")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "X-Amz-Signature", valid_612370
  var valid_612371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "X-Amz-Content-Sha256", valid_612371
  var valid_612372 = header.getOrDefault("X-Amz-Date")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "X-Amz-Date", valid_612372
  var valid_612373 = header.getOrDefault("X-Amz-Credential")
  valid_612373 = validateParameter(valid_612373, JString, required = false,
                                 default = nil)
  if valid_612373 != nil:
    section.add "X-Amz-Credential", valid_612373
  var valid_612374 = header.getOrDefault("X-Amz-Security-Token")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "X-Amz-Security-Token", valid_612374
  var valid_612375 = header.getOrDefault("X-Amz-Algorithm")
  valid_612375 = validateParameter(valid_612375, JString, required = false,
                                 default = nil)
  if valid_612375 != nil:
    section.add "X-Amz-Algorithm", valid_612375
  var valid_612376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612376 = validateParameter(valid_612376, JString, required = false,
                                 default = nil)
  if valid_612376 != nil:
    section.add "X-Amz-SignedHeaders", valid_612376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612377: Call_GetFailoverDBCluster_612363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_612377.validator(path, query, header, formData, body)
  let scheme = call_612377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612377.url(scheme.get, call_612377.host, call_612377.base,
                         call_612377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612377, url, valid)

proc call*(call_612378: Call_GetFailoverDBCluster_612363;
          DBClusterIdentifier: string = ""; TargetDBInstanceIdentifier: string = "";
          Action: string = "FailoverDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getFailoverDBCluster
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>A cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   TargetDBInstanceIdentifier: string
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612379 = newJObject()
  add(query_612379, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_612379, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_612379, "Action", newJString(Action))
  add(query_612379, "Version", newJString(Version))
  result = call_612378.call(nil, query_612379, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_612363(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_612364, base: "/",
    url: url_GetFailoverDBCluster_612365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_612415 = ref object of OpenApiRestCall_610642
proc url_PostListTagsForResource_612417(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_612416(path: JsonNode; query: JsonNode;
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
  var valid_612418 = query.getOrDefault("Action")
  valid_612418 = validateParameter(valid_612418, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_612418 != nil:
    section.add "Action", valid_612418
  var valid_612419 = query.getOrDefault("Version")
  valid_612419 = validateParameter(valid_612419, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612419 != nil:
    section.add "Version", valid_612419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612420 = header.getOrDefault("X-Amz-Signature")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Signature", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Content-Sha256", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Date")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Date", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-Credential")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-Credential", valid_612423
  var valid_612424 = header.getOrDefault("X-Amz-Security-Token")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-Security-Token", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Algorithm")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Algorithm", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-SignedHeaders", valid_612426
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_612427 = formData.getOrDefault("Filters")
  valid_612427 = validateParameter(valid_612427, JArray, required = false,
                                 default = nil)
  if valid_612427 != nil:
    section.add "Filters", valid_612427
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_612428 = formData.getOrDefault("ResourceName")
  valid_612428 = validateParameter(valid_612428, JString, required = true,
                                 default = nil)
  if valid_612428 != nil:
    section.add "ResourceName", valid_612428
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612429: Call_PostListTagsForResource_612415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_612429.validator(path, query, header, formData, body)
  let scheme = call_612429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612429.url(scheme.get, call_612429.host, call_612429.base,
                         call_612429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612429, url, valid)

proc call*(call_612430: Call_PostListTagsForResource_612415; ResourceName: string;
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
  var query_612431 = newJObject()
  var formData_612432 = newJObject()
  add(query_612431, "Action", newJString(Action))
  if Filters != nil:
    formData_612432.add "Filters", Filters
  add(query_612431, "Version", newJString(Version))
  add(formData_612432, "ResourceName", newJString(ResourceName))
  result = call_612430.call(nil, query_612431, nil, formData_612432, nil)

var postListTagsForResource* = Call_PostListTagsForResource_612415(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_612416, base: "/",
    url: url_PostListTagsForResource_612417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_612398 = ref object of OpenApiRestCall_610642
proc url_GetListTagsForResource_612400(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_612399(path: JsonNode; query: JsonNode;
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
  var valid_612401 = query.getOrDefault("ResourceName")
  valid_612401 = validateParameter(valid_612401, JString, required = true,
                                 default = nil)
  if valid_612401 != nil:
    section.add "ResourceName", valid_612401
  var valid_612402 = query.getOrDefault("Action")
  valid_612402 = validateParameter(valid_612402, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_612402 != nil:
    section.add "Action", valid_612402
  var valid_612403 = query.getOrDefault("Version")
  valid_612403 = validateParameter(valid_612403, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612403 != nil:
    section.add "Version", valid_612403
  var valid_612404 = query.getOrDefault("Filters")
  valid_612404 = validateParameter(valid_612404, JArray, required = false,
                                 default = nil)
  if valid_612404 != nil:
    section.add "Filters", valid_612404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612405 = header.getOrDefault("X-Amz-Signature")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Signature", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Content-Sha256", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Date")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Date", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-Credential")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-Credential", valid_612408
  var valid_612409 = header.getOrDefault("X-Amz-Security-Token")
  valid_612409 = validateParameter(valid_612409, JString, required = false,
                                 default = nil)
  if valid_612409 != nil:
    section.add "X-Amz-Security-Token", valid_612409
  var valid_612410 = header.getOrDefault("X-Amz-Algorithm")
  valid_612410 = validateParameter(valid_612410, JString, required = false,
                                 default = nil)
  if valid_612410 != nil:
    section.add "X-Amz-Algorithm", valid_612410
  var valid_612411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612411 = validateParameter(valid_612411, JString, required = false,
                                 default = nil)
  if valid_612411 != nil:
    section.add "X-Amz-SignedHeaders", valid_612411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612412: Call_GetListTagsForResource_612398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_612412.validator(path, query, header, formData, body)
  let scheme = call_612412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612412.url(scheme.get, call_612412.host, call_612412.base,
                         call_612412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612412, url, valid)

proc call*(call_612413: Call_GetListTagsForResource_612398; ResourceName: string;
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
  var query_612414 = newJObject()
  add(query_612414, "ResourceName", newJString(ResourceName))
  add(query_612414, "Action", newJString(Action))
  add(query_612414, "Version", newJString(Version))
  if Filters != nil:
    query_612414.add "Filters", Filters
  result = call_612413.call(nil, query_612414, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_612398(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_612399, base: "/",
    url: url_GetListTagsForResource_612400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_612462 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBCluster_612464(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBCluster_612463(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612465 = query.getOrDefault("Action")
  valid_612465 = validateParameter(valid_612465, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_612465 != nil:
    section.add "Action", valid_612465
  var valid_612466 = query.getOrDefault("Version")
  valid_612466 = validateParameter(valid_612466, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612466 != nil:
    section.add "Version", valid_612466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612467 = header.getOrDefault("X-Amz-Signature")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "X-Amz-Signature", valid_612467
  var valid_612468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612468 = validateParameter(valid_612468, JString, required = false,
                                 default = nil)
  if valid_612468 != nil:
    section.add "X-Amz-Content-Sha256", valid_612468
  var valid_612469 = header.getOrDefault("X-Amz-Date")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "X-Amz-Date", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-Credential")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-Credential", valid_612470
  var valid_612471 = header.getOrDefault("X-Amz-Security-Token")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "X-Amz-Security-Token", valid_612471
  var valid_612472 = header.getOrDefault("X-Amz-Algorithm")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "X-Amz-Algorithm", valid_612472
  var valid_612473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-SignedHeaders", valid_612473
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  section = newJObject()
  var valid_612474 = formData.getOrDefault("Port")
  valid_612474 = validateParameter(valid_612474, JInt, required = false, default = nil)
  if valid_612474 != nil:
    section.add "Port", valid_612474
  var valid_612475 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "PreferredMaintenanceWindow", valid_612475
  var valid_612476 = formData.getOrDefault("PreferredBackupWindow")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "PreferredBackupWindow", valid_612476
  var valid_612477 = formData.getOrDefault("MasterUserPassword")
  valid_612477 = validateParameter(valid_612477, JString, required = false,
                                 default = nil)
  if valid_612477 != nil:
    section.add "MasterUserPassword", valid_612477
  var valid_612478 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_612478 = validateParameter(valid_612478, JArray, required = false,
                                 default = nil)
  if valid_612478 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_612478
  var valid_612479 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_612479 = validateParameter(valid_612479, JArray, required = false,
                                 default = nil)
  if valid_612479 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_612479
  var valid_612480 = formData.getOrDefault("EngineVersion")
  valid_612480 = validateParameter(valid_612480, JString, required = false,
                                 default = nil)
  if valid_612480 != nil:
    section.add "EngineVersion", valid_612480
  var valid_612481 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_612481 = validateParameter(valid_612481, JArray, required = false,
                                 default = nil)
  if valid_612481 != nil:
    section.add "VpcSecurityGroupIds", valid_612481
  var valid_612482 = formData.getOrDefault("BackupRetentionPeriod")
  valid_612482 = validateParameter(valid_612482, JInt, required = false, default = nil)
  if valid_612482 != nil:
    section.add "BackupRetentionPeriod", valid_612482
  var valid_612483 = formData.getOrDefault("ApplyImmediately")
  valid_612483 = validateParameter(valid_612483, JBool, required = false, default = nil)
  if valid_612483 != nil:
    section.add "ApplyImmediately", valid_612483
  var valid_612484 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_612484 = validateParameter(valid_612484, JString, required = false,
                                 default = nil)
  if valid_612484 != nil:
    section.add "DBClusterParameterGroupName", valid_612484
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_612485 = formData.getOrDefault("DBClusterIdentifier")
  valid_612485 = validateParameter(valid_612485, JString, required = true,
                                 default = nil)
  if valid_612485 != nil:
    section.add "DBClusterIdentifier", valid_612485
  var valid_612486 = formData.getOrDefault("DeletionProtection")
  valid_612486 = validateParameter(valid_612486, JBool, required = false, default = nil)
  if valid_612486 != nil:
    section.add "DeletionProtection", valid_612486
  var valid_612487 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "NewDBClusterIdentifier", valid_612487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612488: Call_PostModifyDBCluster_612462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_612488.validator(path, query, header, formData, body)
  let scheme = call_612488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612488.url(scheme.get, call_612488.host, call_612488.base,
                         call_612488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612488, url, valid)

proc call*(call_612489: Call_PostModifyDBCluster_612462;
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
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   Port: int
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  var query_612490 = newJObject()
  var formData_612491 = newJObject()
  add(formData_612491, "Port", newJInt(Port))
  add(formData_612491, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_612491, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_612491, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_612491.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_612491.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_612491, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_612491.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_612491, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_612491, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_612490, "Action", newJString(Action))
  add(formData_612491, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_612490, "Version", newJString(Version))
  add(formData_612491, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_612491, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_612491, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  result = call_612489.call(nil, query_612490, nil, formData_612491, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_612462(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_612463, base: "/",
    url: url_PostModifyDBCluster_612464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_612433 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBCluster_612435(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBCluster_612434(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Action: JString (required)
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   Port: JInt
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   Version: JString (required)
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  var valid_612436 = query.getOrDefault("DeletionProtection")
  valid_612436 = validateParameter(valid_612436, JBool, required = false, default = nil)
  if valid_612436 != nil:
    section.add "DeletionProtection", valid_612436
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_612437 = query.getOrDefault("DBClusterIdentifier")
  valid_612437 = validateParameter(valid_612437, JString, required = true,
                                 default = nil)
  if valid_612437 != nil:
    section.add "DBClusterIdentifier", valid_612437
  var valid_612438 = query.getOrDefault("DBClusterParameterGroupName")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "DBClusterParameterGroupName", valid_612438
  var valid_612439 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_612439 = validateParameter(valid_612439, JArray, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_612439
  var valid_612440 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_612440 = validateParameter(valid_612440, JArray, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_612440
  var valid_612441 = query.getOrDefault("BackupRetentionPeriod")
  valid_612441 = validateParameter(valid_612441, JInt, required = false, default = nil)
  if valid_612441 != nil:
    section.add "BackupRetentionPeriod", valid_612441
  var valid_612442 = query.getOrDefault("EngineVersion")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "EngineVersion", valid_612442
  var valid_612443 = query.getOrDefault("Action")
  valid_612443 = validateParameter(valid_612443, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_612443 != nil:
    section.add "Action", valid_612443
  var valid_612444 = query.getOrDefault("ApplyImmediately")
  valid_612444 = validateParameter(valid_612444, JBool, required = false, default = nil)
  if valid_612444 != nil:
    section.add "ApplyImmediately", valid_612444
  var valid_612445 = query.getOrDefault("NewDBClusterIdentifier")
  valid_612445 = validateParameter(valid_612445, JString, required = false,
                                 default = nil)
  if valid_612445 != nil:
    section.add "NewDBClusterIdentifier", valid_612445
  var valid_612446 = query.getOrDefault("Port")
  valid_612446 = validateParameter(valid_612446, JInt, required = false, default = nil)
  if valid_612446 != nil:
    section.add "Port", valid_612446
  var valid_612447 = query.getOrDefault("VpcSecurityGroupIds")
  valid_612447 = validateParameter(valid_612447, JArray, required = false,
                                 default = nil)
  if valid_612447 != nil:
    section.add "VpcSecurityGroupIds", valid_612447
  var valid_612448 = query.getOrDefault("MasterUserPassword")
  valid_612448 = validateParameter(valid_612448, JString, required = false,
                                 default = nil)
  if valid_612448 != nil:
    section.add "MasterUserPassword", valid_612448
  var valid_612449 = query.getOrDefault("Version")
  valid_612449 = validateParameter(valid_612449, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612449 != nil:
    section.add "Version", valid_612449
  var valid_612450 = query.getOrDefault("PreferredBackupWindow")
  valid_612450 = validateParameter(valid_612450, JString, required = false,
                                 default = nil)
  if valid_612450 != nil:
    section.add "PreferredBackupWindow", valid_612450
  var valid_612451 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_612451 = validateParameter(valid_612451, JString, required = false,
                                 default = nil)
  if valid_612451 != nil:
    section.add "PreferredMaintenanceWindow", valid_612451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612452 = header.getOrDefault("X-Amz-Signature")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-Signature", valid_612452
  var valid_612453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612453 = validateParameter(valid_612453, JString, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "X-Amz-Content-Sha256", valid_612453
  var valid_612454 = header.getOrDefault("X-Amz-Date")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Date", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-Credential")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-Credential", valid_612455
  var valid_612456 = header.getOrDefault("X-Amz-Security-Token")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Security-Token", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-Algorithm")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-Algorithm", valid_612457
  var valid_612458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-SignedHeaders", valid_612458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612459: Call_GetModifyDBCluster_612433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_612459.validator(path, query, header, formData, body)
  let scheme = call_612459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612459.url(scheme.get, call_612459.host, call_612459.base,
                         call_612459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612459, url, valid)

proc call*(call_612460: Call_GetModifyDBCluster_612433;
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
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   Port: int
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_612461 = newJObject()
  add(query_612461, "DeletionProtection", newJBool(DeletionProtection))
  add(query_612461, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_612461, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_612461.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_612461.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_612461, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_612461, "EngineVersion", newJString(EngineVersion))
  add(query_612461, "Action", newJString(Action))
  add(query_612461, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_612461, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_612461, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_612461.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_612461, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_612461, "Version", newJString(Version))
  add(query_612461, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_612461, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_612460.call(nil, query_612461, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_612433(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_612434,
    base: "/", url: url_GetModifyDBCluster_612435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_612509 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBClusterParameterGroup_612511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBClusterParameterGroup_612510(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612512 = query.getOrDefault("Action")
  valid_612512 = validateParameter(valid_612512, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_612512 != nil:
    section.add "Action", valid_612512
  var valid_612513 = query.getOrDefault("Version")
  valid_612513 = validateParameter(valid_612513, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612513 != nil:
    section.add "Version", valid_612513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612514 = header.getOrDefault("X-Amz-Signature")
  valid_612514 = validateParameter(valid_612514, JString, required = false,
                                 default = nil)
  if valid_612514 != nil:
    section.add "X-Amz-Signature", valid_612514
  var valid_612515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612515 = validateParameter(valid_612515, JString, required = false,
                                 default = nil)
  if valid_612515 != nil:
    section.add "X-Amz-Content-Sha256", valid_612515
  var valid_612516 = header.getOrDefault("X-Amz-Date")
  valid_612516 = validateParameter(valid_612516, JString, required = false,
                                 default = nil)
  if valid_612516 != nil:
    section.add "X-Amz-Date", valid_612516
  var valid_612517 = header.getOrDefault("X-Amz-Credential")
  valid_612517 = validateParameter(valid_612517, JString, required = false,
                                 default = nil)
  if valid_612517 != nil:
    section.add "X-Amz-Credential", valid_612517
  var valid_612518 = header.getOrDefault("X-Amz-Security-Token")
  valid_612518 = validateParameter(valid_612518, JString, required = false,
                                 default = nil)
  if valid_612518 != nil:
    section.add "X-Amz-Security-Token", valid_612518
  var valid_612519 = header.getOrDefault("X-Amz-Algorithm")
  valid_612519 = validateParameter(valid_612519, JString, required = false,
                                 default = nil)
  if valid_612519 != nil:
    section.add "X-Amz-Algorithm", valid_612519
  var valid_612520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612520 = validateParameter(valid_612520, JString, required = false,
                                 default = nil)
  if valid_612520 != nil:
    section.add "X-Amz-SignedHeaders", valid_612520
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_612521 = formData.getOrDefault("Parameters")
  valid_612521 = validateParameter(valid_612521, JArray, required = true, default = nil)
  if valid_612521 != nil:
    section.add "Parameters", valid_612521
  var valid_612522 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_612522 = validateParameter(valid_612522, JString, required = true,
                                 default = nil)
  if valid_612522 != nil:
    section.add "DBClusterParameterGroupName", valid_612522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612523: Call_PostModifyDBClusterParameterGroup_612509;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_612523.validator(path, query, header, formData, body)
  let scheme = call_612523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612523.url(scheme.get, call_612523.host, call_612523.base,
                         call_612523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612523, url, valid)

proc call*(call_612524: Call_PostModifyDBClusterParameterGroup_612509;
          Parameters: JsonNode; DBClusterParameterGroupName: string;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the cluster parameter group to modify.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the cluster parameter group to modify.
  ##   Version: string (required)
  var query_612525 = newJObject()
  var formData_612526 = newJObject()
  add(query_612525, "Action", newJString(Action))
  if Parameters != nil:
    formData_612526.add "Parameters", Parameters
  add(formData_612526, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_612525, "Version", newJString(Version))
  result = call_612524.call(nil, query_612525, nil, formData_612526, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_612509(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_612510, base: "/",
    url: url_PostModifyDBClusterParameterGroup_612511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_612492 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBClusterParameterGroup_612494(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBClusterParameterGroup_612493(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to modify.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Parameters` field"
  var valid_612495 = query.getOrDefault("Parameters")
  valid_612495 = validateParameter(valid_612495, JArray, required = true, default = nil)
  if valid_612495 != nil:
    section.add "Parameters", valid_612495
  var valid_612496 = query.getOrDefault("DBClusterParameterGroupName")
  valid_612496 = validateParameter(valid_612496, JString, required = true,
                                 default = nil)
  if valid_612496 != nil:
    section.add "DBClusterParameterGroupName", valid_612496
  var valid_612497 = query.getOrDefault("Action")
  valid_612497 = validateParameter(valid_612497, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_612497 != nil:
    section.add "Action", valid_612497
  var valid_612498 = query.getOrDefault("Version")
  valid_612498 = validateParameter(valid_612498, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612498 != nil:
    section.add "Version", valid_612498
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612499 = header.getOrDefault("X-Amz-Signature")
  valid_612499 = validateParameter(valid_612499, JString, required = false,
                                 default = nil)
  if valid_612499 != nil:
    section.add "X-Amz-Signature", valid_612499
  var valid_612500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612500 = validateParameter(valid_612500, JString, required = false,
                                 default = nil)
  if valid_612500 != nil:
    section.add "X-Amz-Content-Sha256", valid_612500
  var valid_612501 = header.getOrDefault("X-Amz-Date")
  valid_612501 = validateParameter(valid_612501, JString, required = false,
                                 default = nil)
  if valid_612501 != nil:
    section.add "X-Amz-Date", valid_612501
  var valid_612502 = header.getOrDefault("X-Amz-Credential")
  valid_612502 = validateParameter(valid_612502, JString, required = false,
                                 default = nil)
  if valid_612502 != nil:
    section.add "X-Amz-Credential", valid_612502
  var valid_612503 = header.getOrDefault("X-Amz-Security-Token")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "X-Amz-Security-Token", valid_612503
  var valid_612504 = header.getOrDefault("X-Amz-Algorithm")
  valid_612504 = validateParameter(valid_612504, JString, required = false,
                                 default = nil)
  if valid_612504 != nil:
    section.add "X-Amz-Algorithm", valid_612504
  var valid_612505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612505 = validateParameter(valid_612505, JString, required = false,
                                 default = nil)
  if valid_612505 != nil:
    section.add "X-Amz-SignedHeaders", valid_612505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612506: Call_GetModifyDBClusterParameterGroup_612492;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_612506.validator(path, query, header, formData, body)
  let scheme = call_612506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612506.url(scheme.get, call_612506.host, call_612506.base,
                         call_612506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612506, url, valid)

proc call*(call_612507: Call_GetModifyDBClusterParameterGroup_612492;
          Parameters: JsonNode; DBClusterParameterGroupName: string;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the cluster parameter group to modify.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the cluster parameter group to modify.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612508 = newJObject()
  if Parameters != nil:
    query_612508.add "Parameters", Parameters
  add(query_612508, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_612508, "Action", newJString(Action))
  add(query_612508, "Version", newJString(Version))
  result = call_612507.call(nil, query_612508, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_612492(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_612493, base: "/",
    url: url_GetModifyDBClusterParameterGroup_612494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_612546 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBClusterSnapshotAttribute_612548(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBClusterSnapshotAttribute_612547(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612549 = query.getOrDefault("Action")
  valid_612549 = validateParameter(valid_612549, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_612549 != nil:
    section.add "Action", valid_612549
  var valid_612550 = query.getOrDefault("Version")
  valid_612550 = validateParameter(valid_612550, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612550 != nil:
    section.add "Version", valid_612550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612551 = header.getOrDefault("X-Amz-Signature")
  valid_612551 = validateParameter(valid_612551, JString, required = false,
                                 default = nil)
  if valid_612551 != nil:
    section.add "X-Amz-Signature", valid_612551
  var valid_612552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612552 = validateParameter(valid_612552, JString, required = false,
                                 default = nil)
  if valid_612552 != nil:
    section.add "X-Amz-Content-Sha256", valid_612552
  var valid_612553 = header.getOrDefault("X-Amz-Date")
  valid_612553 = validateParameter(valid_612553, JString, required = false,
                                 default = nil)
  if valid_612553 != nil:
    section.add "X-Amz-Date", valid_612553
  var valid_612554 = header.getOrDefault("X-Amz-Credential")
  valid_612554 = validateParameter(valid_612554, JString, required = false,
                                 default = nil)
  if valid_612554 != nil:
    section.add "X-Amz-Credential", valid_612554
  var valid_612555 = header.getOrDefault("X-Amz-Security-Token")
  valid_612555 = validateParameter(valid_612555, JString, required = false,
                                 default = nil)
  if valid_612555 != nil:
    section.add "X-Amz-Security-Token", valid_612555
  var valid_612556 = header.getOrDefault("X-Amz-Algorithm")
  valid_612556 = validateParameter(valid_612556, JString, required = false,
                                 default = nil)
  if valid_612556 != nil:
    section.add "X-Amz-Algorithm", valid_612556
  var valid_612557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612557 = validateParameter(valid_612557, JString, required = false,
                                 default = nil)
  if valid_612557 != nil:
    section.add "X-Amz-SignedHeaders", valid_612557
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_612558 = formData.getOrDefault("AttributeName")
  valid_612558 = validateParameter(valid_612558, JString, required = true,
                                 default = nil)
  if valid_612558 != nil:
    section.add "AttributeName", valid_612558
  var valid_612559 = formData.getOrDefault("ValuesToAdd")
  valid_612559 = validateParameter(valid_612559, JArray, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "ValuesToAdd", valid_612559
  var valid_612560 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_612560 = validateParameter(valid_612560, JString, required = true,
                                 default = nil)
  if valid_612560 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_612560
  var valid_612561 = formData.getOrDefault("ValuesToRemove")
  valid_612561 = validateParameter(valid_612561, JArray, required = false,
                                 default = nil)
  if valid_612561 != nil:
    section.add "ValuesToRemove", valid_612561
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612562: Call_PostModifyDBClusterSnapshotAttribute_612546;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_612562.validator(path, query, header, formData, body)
  let scheme = call_612562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612562.url(scheme.get, call_612562.host, call_612562.base,
                         call_612562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612562, url, valid)

proc call*(call_612563: Call_PostModifyDBClusterSnapshotAttribute_612546;
          AttributeName: string; DBClusterSnapshotIdentifier: string;
          ValuesToAdd: JsonNode = nil;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToRemove: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   AttributeName: string (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   Action: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  ##   Version: string (required)
  var query_612564 = newJObject()
  var formData_612565 = newJObject()
  add(formData_612565, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    formData_612565.add "ValuesToAdd", ValuesToAdd
  add(formData_612565, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_612564, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_612565.add "ValuesToRemove", ValuesToRemove
  add(query_612564, "Version", newJString(Version))
  result = call_612563.call(nil, query_612564, nil, formData_612565, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_612546(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_612547, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_612548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_612527 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBClusterSnapshotAttribute_612529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBClusterSnapshotAttribute_612528(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   Action: JString (required)
  ##   AttributeName: JString (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_612530 = query.getOrDefault("ValuesToRemove")
  valid_612530 = validateParameter(valid_612530, JArray, required = false,
                                 default = nil)
  if valid_612530 != nil:
    section.add "ValuesToRemove", valid_612530
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_612531 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_612531 = validateParameter(valid_612531, JString, required = true,
                                 default = nil)
  if valid_612531 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_612531
  var valid_612532 = query.getOrDefault("Action")
  valid_612532 = validateParameter(valid_612532, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_612532 != nil:
    section.add "Action", valid_612532
  var valid_612533 = query.getOrDefault("AttributeName")
  valid_612533 = validateParameter(valid_612533, JString, required = true,
                                 default = nil)
  if valid_612533 != nil:
    section.add "AttributeName", valid_612533
  var valid_612534 = query.getOrDefault("ValuesToAdd")
  valid_612534 = validateParameter(valid_612534, JArray, required = false,
                                 default = nil)
  if valid_612534 != nil:
    section.add "ValuesToAdd", valid_612534
  var valid_612535 = query.getOrDefault("Version")
  valid_612535 = validateParameter(valid_612535, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612535 != nil:
    section.add "Version", valid_612535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612536 = header.getOrDefault("X-Amz-Signature")
  valid_612536 = validateParameter(valid_612536, JString, required = false,
                                 default = nil)
  if valid_612536 != nil:
    section.add "X-Amz-Signature", valid_612536
  var valid_612537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612537 = validateParameter(valid_612537, JString, required = false,
                                 default = nil)
  if valid_612537 != nil:
    section.add "X-Amz-Content-Sha256", valid_612537
  var valid_612538 = header.getOrDefault("X-Amz-Date")
  valid_612538 = validateParameter(valid_612538, JString, required = false,
                                 default = nil)
  if valid_612538 != nil:
    section.add "X-Amz-Date", valid_612538
  var valid_612539 = header.getOrDefault("X-Amz-Credential")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "X-Amz-Credential", valid_612539
  var valid_612540 = header.getOrDefault("X-Amz-Security-Token")
  valid_612540 = validateParameter(valid_612540, JString, required = false,
                                 default = nil)
  if valid_612540 != nil:
    section.add "X-Amz-Security-Token", valid_612540
  var valid_612541 = header.getOrDefault("X-Amz-Algorithm")
  valid_612541 = validateParameter(valid_612541, JString, required = false,
                                 default = nil)
  if valid_612541 != nil:
    section.add "X-Amz-Algorithm", valid_612541
  var valid_612542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612542 = validateParameter(valid_612542, JString, required = false,
                                 default = nil)
  if valid_612542 != nil:
    section.add "X-Amz-SignedHeaders", valid_612542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612543: Call_GetModifyDBClusterSnapshotAttribute_612527;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_612543.validator(path, query, header, formData, body)
  let scheme = call_612543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612543.url(scheme.get, call_612543.host, call_612543.base,
                         call_612543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612543, url, valid)

proc call*(call_612544: Call_GetModifyDBClusterSnapshotAttribute_612527;
          DBClusterSnapshotIdentifier: string; AttributeName: string;
          ValuesToRemove: JsonNode = nil;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToAdd: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   Action: string (required)
  ##   AttributeName: string (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Version: string (required)
  var query_612545 = newJObject()
  if ValuesToRemove != nil:
    query_612545.add "ValuesToRemove", ValuesToRemove
  add(query_612545, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_612545, "Action", newJString(Action))
  add(query_612545, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    query_612545.add "ValuesToAdd", ValuesToAdd
  add(query_612545, "Version", newJString(Version))
  result = call_612544.call(nil, query_612545, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_612527(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_612528, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_612529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_612589 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBInstance_612591(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_612590(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612592 = query.getOrDefault("Action")
  valid_612592 = validateParameter(valid_612592, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_612592 != nil:
    section.add "Action", valid_612592
  var valid_612593 = query.getOrDefault("Version")
  valid_612593 = validateParameter(valid_612593, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612593 != nil:
    section.add "Version", valid_612593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612594 = header.getOrDefault("X-Amz-Signature")
  valid_612594 = validateParameter(valid_612594, JString, required = false,
                                 default = nil)
  if valid_612594 != nil:
    section.add "X-Amz-Signature", valid_612594
  var valid_612595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612595 = validateParameter(valid_612595, JString, required = false,
                                 default = nil)
  if valid_612595 != nil:
    section.add "X-Amz-Content-Sha256", valid_612595
  var valid_612596 = header.getOrDefault("X-Amz-Date")
  valid_612596 = validateParameter(valid_612596, JString, required = false,
                                 default = nil)
  if valid_612596 != nil:
    section.add "X-Amz-Date", valid_612596
  var valid_612597 = header.getOrDefault("X-Amz-Credential")
  valid_612597 = validateParameter(valid_612597, JString, required = false,
                                 default = nil)
  if valid_612597 != nil:
    section.add "X-Amz-Credential", valid_612597
  var valid_612598 = header.getOrDefault("X-Amz-Security-Token")
  valid_612598 = validateParameter(valid_612598, JString, required = false,
                                 default = nil)
  if valid_612598 != nil:
    section.add "X-Amz-Security-Token", valid_612598
  var valid_612599 = header.getOrDefault("X-Amz-Algorithm")
  valid_612599 = validateParameter(valid_612599, JString, required = false,
                                 default = nil)
  if valid_612599 != nil:
    section.add "X-Amz-Algorithm", valid_612599
  var valid_612600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612600 = validateParameter(valid_612600, JString, required = false,
                                 default = nil)
  if valid_612600 != nil:
    section.add "X-Amz-SignedHeaders", valid_612600
  result.add "header", section
  ## parameters in `formData` object:
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the instance. </p> <p> If this parameter is set to <code>false</code>, changes to the instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new instance identifier for the instance when renaming an instance. When you change the instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  section = newJObject()
  var valid_612601 = formData.getOrDefault("PromotionTier")
  valid_612601 = validateParameter(valid_612601, JInt, required = false, default = nil)
  if valid_612601 != nil:
    section.add "PromotionTier", valid_612601
  var valid_612602 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_612602 = validateParameter(valid_612602, JString, required = false,
                                 default = nil)
  if valid_612602 != nil:
    section.add "PreferredMaintenanceWindow", valid_612602
  var valid_612603 = formData.getOrDefault("DBInstanceClass")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "DBInstanceClass", valid_612603
  var valid_612604 = formData.getOrDefault("CACertificateIdentifier")
  valid_612604 = validateParameter(valid_612604, JString, required = false,
                                 default = nil)
  if valid_612604 != nil:
    section.add "CACertificateIdentifier", valid_612604
  var valid_612605 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_612605 = validateParameter(valid_612605, JBool, required = false, default = nil)
  if valid_612605 != nil:
    section.add "AutoMinorVersionUpgrade", valid_612605
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612606 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612606 = validateParameter(valid_612606, JString, required = true,
                                 default = nil)
  if valid_612606 != nil:
    section.add "DBInstanceIdentifier", valid_612606
  var valid_612607 = formData.getOrDefault("ApplyImmediately")
  valid_612607 = validateParameter(valid_612607, JBool, required = false, default = nil)
  if valid_612607 != nil:
    section.add "ApplyImmediately", valid_612607
  var valid_612608 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_612608 = validateParameter(valid_612608, JString, required = false,
                                 default = nil)
  if valid_612608 != nil:
    section.add "NewDBInstanceIdentifier", valid_612608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612609: Call_PostModifyDBInstance_612589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_612609.validator(path, query, header, formData, body)
  let scheme = call_612609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612609.url(scheme.get, call_612609.host, call_612609.base,
                         call_612609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612609, url, valid)

proc call*(call_612610: Call_PostModifyDBInstance_612589;
          DBInstanceIdentifier: string; PromotionTier: int = 0;
          PreferredMaintenanceWindow: string = ""; DBInstanceClass: string = "";
          CACertificateIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Action: string = "ModifyDBInstance"; NewDBInstanceIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBInstance
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the instance. </p> <p> If this parameter is set to <code>false</code>, changes to the instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   Action: string (required)
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new instance identifier for the instance when renaming an instance. When you change the instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Version: string (required)
  var query_612611 = newJObject()
  var formData_612612 = newJObject()
  add(formData_612612, "PromotionTier", newJInt(PromotionTier))
  add(formData_612612, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_612612, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612612, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(formData_612612, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_612612, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_612612, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_612611, "Action", newJString(Action))
  add(formData_612612, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_612611, "Version", newJString(Version))
  result = call_612610.call(nil, query_612611, nil, formData_612612, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_612589(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_612590, base: "/",
    url: url_PostModifyDBInstance_612591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_612566 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBInstance_612568(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_612567(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new instance identifier for the instance when renaming an instance. When you change the instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   Action: JString (required)
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the instance. </p> <p> If this parameter is set to <code>false</code>, changes to the instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  section = newJObject()
  var valid_612569 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_612569 = validateParameter(valid_612569, JString, required = false,
                                 default = nil)
  if valid_612569 != nil:
    section.add "NewDBInstanceIdentifier", valid_612569
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612570 = query.getOrDefault("DBInstanceIdentifier")
  valid_612570 = validateParameter(valid_612570, JString, required = true,
                                 default = nil)
  if valid_612570 != nil:
    section.add "DBInstanceIdentifier", valid_612570
  var valid_612571 = query.getOrDefault("PromotionTier")
  valid_612571 = validateParameter(valid_612571, JInt, required = false, default = nil)
  if valid_612571 != nil:
    section.add "PromotionTier", valid_612571
  var valid_612572 = query.getOrDefault("CACertificateIdentifier")
  valid_612572 = validateParameter(valid_612572, JString, required = false,
                                 default = nil)
  if valid_612572 != nil:
    section.add "CACertificateIdentifier", valid_612572
  var valid_612573 = query.getOrDefault("Action")
  valid_612573 = validateParameter(valid_612573, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_612573 != nil:
    section.add "Action", valid_612573
  var valid_612574 = query.getOrDefault("ApplyImmediately")
  valid_612574 = validateParameter(valid_612574, JBool, required = false, default = nil)
  if valid_612574 != nil:
    section.add "ApplyImmediately", valid_612574
  var valid_612575 = query.getOrDefault("Version")
  valid_612575 = validateParameter(valid_612575, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612575 != nil:
    section.add "Version", valid_612575
  var valid_612576 = query.getOrDefault("DBInstanceClass")
  valid_612576 = validateParameter(valid_612576, JString, required = false,
                                 default = nil)
  if valid_612576 != nil:
    section.add "DBInstanceClass", valid_612576
  var valid_612577 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_612577 = validateParameter(valid_612577, JString, required = false,
                                 default = nil)
  if valid_612577 != nil:
    section.add "PreferredMaintenanceWindow", valid_612577
  var valid_612578 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_612578 = validateParameter(valid_612578, JBool, required = false, default = nil)
  if valid_612578 != nil:
    section.add "AutoMinorVersionUpgrade", valid_612578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612579 = header.getOrDefault("X-Amz-Signature")
  valid_612579 = validateParameter(valid_612579, JString, required = false,
                                 default = nil)
  if valid_612579 != nil:
    section.add "X-Amz-Signature", valid_612579
  var valid_612580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612580 = validateParameter(valid_612580, JString, required = false,
                                 default = nil)
  if valid_612580 != nil:
    section.add "X-Amz-Content-Sha256", valid_612580
  var valid_612581 = header.getOrDefault("X-Amz-Date")
  valid_612581 = validateParameter(valid_612581, JString, required = false,
                                 default = nil)
  if valid_612581 != nil:
    section.add "X-Amz-Date", valid_612581
  var valid_612582 = header.getOrDefault("X-Amz-Credential")
  valid_612582 = validateParameter(valid_612582, JString, required = false,
                                 default = nil)
  if valid_612582 != nil:
    section.add "X-Amz-Credential", valid_612582
  var valid_612583 = header.getOrDefault("X-Amz-Security-Token")
  valid_612583 = validateParameter(valid_612583, JString, required = false,
                                 default = nil)
  if valid_612583 != nil:
    section.add "X-Amz-Security-Token", valid_612583
  var valid_612584 = header.getOrDefault("X-Amz-Algorithm")
  valid_612584 = validateParameter(valid_612584, JString, required = false,
                                 default = nil)
  if valid_612584 != nil:
    section.add "X-Amz-Algorithm", valid_612584
  var valid_612585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612585 = validateParameter(valid_612585, JString, required = false,
                                 default = nil)
  if valid_612585 != nil:
    section.add "X-Amz-SignedHeaders", valid_612585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612586: Call_GetModifyDBInstance_612566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_612586.validator(path, query, header, formData, body)
  let scheme = call_612586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612586.url(scheme.get, call_612586.host, call_612586.base,
                         call_612586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612586, url, valid)

proc call*(call_612587: Call_GetModifyDBInstance_612566;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          PromotionTier: int = 0; CACertificateIdentifier: string = "";
          Action: string = "ModifyDBInstance"; ApplyImmediately: bool = false;
          Version: string = "2014-10-31"; DBInstanceClass: string = "";
          PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false): Recallable =
  ## getModifyDBInstance
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new instance identifier for the instance when renaming an instance. When you change the instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the instance. </p> <p> If this parameter is set to <code>false</code>, changes to the instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  var query_612588 = newJObject()
  add(query_612588, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_612588, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612588, "PromotionTier", newJInt(PromotionTier))
  add(query_612588, "CACertificateIdentifier", newJString(CACertificateIdentifier))
  add(query_612588, "Action", newJString(Action))
  add(query_612588, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_612588, "Version", newJString(Version))
  add(query_612588, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_612588, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_612588, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_612587.call(nil, query_612588, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_612566(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_612567, base: "/",
    url: url_GetModifyDBInstance_612568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_612631 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBSubnetGroup_612633(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_612632(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612634 = query.getOrDefault("Action")
  valid_612634 = validateParameter(valid_612634, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_612634 != nil:
    section.add "Action", valid_612634
  var valid_612635 = query.getOrDefault("Version")
  valid_612635 = validateParameter(valid_612635, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612635 != nil:
    section.add "Version", valid_612635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612636 = header.getOrDefault("X-Amz-Signature")
  valid_612636 = validateParameter(valid_612636, JString, required = false,
                                 default = nil)
  if valid_612636 != nil:
    section.add "X-Amz-Signature", valid_612636
  var valid_612637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612637 = validateParameter(valid_612637, JString, required = false,
                                 default = nil)
  if valid_612637 != nil:
    section.add "X-Amz-Content-Sha256", valid_612637
  var valid_612638 = header.getOrDefault("X-Amz-Date")
  valid_612638 = validateParameter(valid_612638, JString, required = false,
                                 default = nil)
  if valid_612638 != nil:
    section.add "X-Amz-Date", valid_612638
  var valid_612639 = header.getOrDefault("X-Amz-Credential")
  valid_612639 = validateParameter(valid_612639, JString, required = false,
                                 default = nil)
  if valid_612639 != nil:
    section.add "X-Amz-Credential", valid_612639
  var valid_612640 = header.getOrDefault("X-Amz-Security-Token")
  valid_612640 = validateParameter(valid_612640, JString, required = false,
                                 default = nil)
  if valid_612640 != nil:
    section.add "X-Amz-Security-Token", valid_612640
  var valid_612641 = header.getOrDefault("X-Amz-Algorithm")
  valid_612641 = validateParameter(valid_612641, JString, required = false,
                                 default = nil)
  if valid_612641 != nil:
    section.add "X-Amz-Algorithm", valid_612641
  var valid_612642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612642 = validateParameter(valid_612642, JString, required = false,
                                 default = nil)
  if valid_612642 != nil:
    section.add "X-Amz-SignedHeaders", valid_612642
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  section = newJObject()
  var valid_612643 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_612643 = validateParameter(valid_612643, JString, required = false,
                                 default = nil)
  if valid_612643 != nil:
    section.add "DBSubnetGroupDescription", valid_612643
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_612644 = formData.getOrDefault("DBSubnetGroupName")
  valid_612644 = validateParameter(valid_612644, JString, required = true,
                                 default = nil)
  if valid_612644 != nil:
    section.add "DBSubnetGroupName", valid_612644
  var valid_612645 = formData.getOrDefault("SubnetIds")
  valid_612645 = validateParameter(valid_612645, JArray, required = true, default = nil)
  if valid_612645 != nil:
    section.add "SubnetIds", valid_612645
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612646: Call_PostModifyDBSubnetGroup_612631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_612646.validator(path, query, header, formData, body)
  let scheme = call_612646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612646.url(scheme.get, call_612646.host, call_612646.base,
                         call_612646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612646, url, valid)

proc call*(call_612647: Call_PostModifyDBSubnetGroup_612631;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2014-10-31"): Recallable =
  ## postModifyDBSubnetGroup
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  var query_612648 = newJObject()
  var formData_612649 = newJObject()
  add(formData_612649, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_612648, "Action", newJString(Action))
  add(formData_612649, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612648, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_612649.add "SubnetIds", SubnetIds
  result = call_612647.call(nil, query_612648, nil, formData_612649, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_612631(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_612632, base: "/",
    url: url_PostModifyDBSubnetGroup_612633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_612613 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBSubnetGroup_612615(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_612614(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_612616 = query.getOrDefault("SubnetIds")
  valid_612616 = validateParameter(valid_612616, JArray, required = true, default = nil)
  if valid_612616 != nil:
    section.add "SubnetIds", valid_612616
  var valid_612617 = query.getOrDefault("Action")
  valid_612617 = validateParameter(valid_612617, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_612617 != nil:
    section.add "Action", valid_612617
  var valid_612618 = query.getOrDefault("DBSubnetGroupDescription")
  valid_612618 = validateParameter(valid_612618, JString, required = false,
                                 default = nil)
  if valid_612618 != nil:
    section.add "DBSubnetGroupDescription", valid_612618
  var valid_612619 = query.getOrDefault("DBSubnetGroupName")
  valid_612619 = validateParameter(valid_612619, JString, required = true,
                                 default = nil)
  if valid_612619 != nil:
    section.add "DBSubnetGroupName", valid_612619
  var valid_612620 = query.getOrDefault("Version")
  valid_612620 = validateParameter(valid_612620, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612620 != nil:
    section.add "Version", valid_612620
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612621 = header.getOrDefault("X-Amz-Signature")
  valid_612621 = validateParameter(valid_612621, JString, required = false,
                                 default = nil)
  if valid_612621 != nil:
    section.add "X-Amz-Signature", valid_612621
  var valid_612622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612622 = validateParameter(valid_612622, JString, required = false,
                                 default = nil)
  if valid_612622 != nil:
    section.add "X-Amz-Content-Sha256", valid_612622
  var valid_612623 = header.getOrDefault("X-Amz-Date")
  valid_612623 = validateParameter(valid_612623, JString, required = false,
                                 default = nil)
  if valid_612623 != nil:
    section.add "X-Amz-Date", valid_612623
  var valid_612624 = header.getOrDefault("X-Amz-Credential")
  valid_612624 = validateParameter(valid_612624, JString, required = false,
                                 default = nil)
  if valid_612624 != nil:
    section.add "X-Amz-Credential", valid_612624
  var valid_612625 = header.getOrDefault("X-Amz-Security-Token")
  valid_612625 = validateParameter(valid_612625, JString, required = false,
                                 default = nil)
  if valid_612625 != nil:
    section.add "X-Amz-Security-Token", valid_612625
  var valid_612626 = header.getOrDefault("X-Amz-Algorithm")
  valid_612626 = validateParameter(valid_612626, JString, required = false,
                                 default = nil)
  if valid_612626 != nil:
    section.add "X-Amz-Algorithm", valid_612626
  var valid_612627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612627 = validateParameter(valid_612627, JString, required = false,
                                 default = nil)
  if valid_612627 != nil:
    section.add "X-Amz-SignedHeaders", valid_612627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612628: Call_GetModifyDBSubnetGroup_612613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_612628.validator(path, query, header, formData, body)
  let scheme = call_612628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612628.url(scheme.get, call_612628.host, call_612628.base,
                         call_612628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612628, url, valid)

proc call*(call_612629: Call_GetModifyDBSubnetGroup_612613; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBSubnetGroup
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_612630 = newJObject()
  if SubnetIds != nil:
    query_612630.add "SubnetIds", SubnetIds
  add(query_612630, "Action", newJString(Action))
  add(query_612630, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_612630, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612630, "Version", newJString(Version))
  result = call_612629.call(nil, query_612630, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_612613(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_612614, base: "/",
    url: url_GetModifyDBSubnetGroup_612615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_612667 = ref object of OpenApiRestCall_610642
proc url_PostRebootDBInstance_612669(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_612668(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612670 = query.getOrDefault("Action")
  valid_612670 = validateParameter(valid_612670, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_612670 != nil:
    section.add "Action", valid_612670
  var valid_612671 = query.getOrDefault("Version")
  valid_612671 = validateParameter(valid_612671, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612671 != nil:
    section.add "Version", valid_612671
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612672 = header.getOrDefault("X-Amz-Signature")
  valid_612672 = validateParameter(valid_612672, JString, required = false,
                                 default = nil)
  if valid_612672 != nil:
    section.add "X-Amz-Signature", valid_612672
  var valid_612673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612673 = validateParameter(valid_612673, JString, required = false,
                                 default = nil)
  if valid_612673 != nil:
    section.add "X-Amz-Content-Sha256", valid_612673
  var valid_612674 = header.getOrDefault("X-Amz-Date")
  valid_612674 = validateParameter(valid_612674, JString, required = false,
                                 default = nil)
  if valid_612674 != nil:
    section.add "X-Amz-Date", valid_612674
  var valid_612675 = header.getOrDefault("X-Amz-Credential")
  valid_612675 = validateParameter(valid_612675, JString, required = false,
                                 default = nil)
  if valid_612675 != nil:
    section.add "X-Amz-Credential", valid_612675
  var valid_612676 = header.getOrDefault("X-Amz-Security-Token")
  valid_612676 = validateParameter(valid_612676, JString, required = false,
                                 default = nil)
  if valid_612676 != nil:
    section.add "X-Amz-Security-Token", valid_612676
  var valid_612677 = header.getOrDefault("X-Amz-Algorithm")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "X-Amz-Algorithm", valid_612677
  var valid_612678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612678 = validateParameter(valid_612678, JString, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "X-Amz-SignedHeaders", valid_612678
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  var valid_612679 = formData.getOrDefault("ForceFailover")
  valid_612679 = validateParameter(valid_612679, JBool, required = false, default = nil)
  if valid_612679 != nil:
    section.add "ForceFailover", valid_612679
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612680 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612680 = validateParameter(valid_612680, JString, required = true,
                                 default = nil)
  if valid_612680 != nil:
    section.add "DBInstanceIdentifier", valid_612680
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612681: Call_PostRebootDBInstance_612667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_612681.validator(path, query, header, formData, body)
  let scheme = call_612681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612681.url(scheme.get, call_612681.host, call_612681.base,
                         call_612681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612681, url, valid)

proc call*(call_612682: Call_PostRebootDBInstance_612667;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-10-31"): Recallable =
  ## postRebootDBInstance
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612683 = newJObject()
  var formData_612684 = newJObject()
  add(formData_612684, "ForceFailover", newJBool(ForceFailover))
  add(formData_612684, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612683, "Action", newJString(Action))
  add(query_612683, "Version", newJString(Version))
  result = call_612682.call(nil, query_612683, nil, formData_612684, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_612667(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_612668, base: "/",
    url: url_PostRebootDBInstance_612669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_612650 = ref object of OpenApiRestCall_610642
proc url_GetRebootDBInstance_612652(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_612651(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612653 = query.getOrDefault("ForceFailover")
  valid_612653 = validateParameter(valid_612653, JBool, required = false, default = nil)
  if valid_612653 != nil:
    section.add "ForceFailover", valid_612653
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612654 = query.getOrDefault("DBInstanceIdentifier")
  valid_612654 = validateParameter(valid_612654, JString, required = true,
                                 default = nil)
  if valid_612654 != nil:
    section.add "DBInstanceIdentifier", valid_612654
  var valid_612655 = query.getOrDefault("Action")
  valid_612655 = validateParameter(valid_612655, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_612655 != nil:
    section.add "Action", valid_612655
  var valid_612656 = query.getOrDefault("Version")
  valid_612656 = validateParameter(valid_612656, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612656 != nil:
    section.add "Version", valid_612656
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612657 = header.getOrDefault("X-Amz-Signature")
  valid_612657 = validateParameter(valid_612657, JString, required = false,
                                 default = nil)
  if valid_612657 != nil:
    section.add "X-Amz-Signature", valid_612657
  var valid_612658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612658 = validateParameter(valid_612658, JString, required = false,
                                 default = nil)
  if valid_612658 != nil:
    section.add "X-Amz-Content-Sha256", valid_612658
  var valid_612659 = header.getOrDefault("X-Amz-Date")
  valid_612659 = validateParameter(valid_612659, JString, required = false,
                                 default = nil)
  if valid_612659 != nil:
    section.add "X-Amz-Date", valid_612659
  var valid_612660 = header.getOrDefault("X-Amz-Credential")
  valid_612660 = validateParameter(valid_612660, JString, required = false,
                                 default = nil)
  if valid_612660 != nil:
    section.add "X-Amz-Credential", valid_612660
  var valid_612661 = header.getOrDefault("X-Amz-Security-Token")
  valid_612661 = validateParameter(valid_612661, JString, required = false,
                                 default = nil)
  if valid_612661 != nil:
    section.add "X-Amz-Security-Token", valid_612661
  var valid_612662 = header.getOrDefault("X-Amz-Algorithm")
  valid_612662 = validateParameter(valid_612662, JString, required = false,
                                 default = nil)
  if valid_612662 != nil:
    section.add "X-Amz-Algorithm", valid_612662
  var valid_612663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612663 = validateParameter(valid_612663, JString, required = false,
                                 default = nil)
  if valid_612663 != nil:
    section.add "X-Amz-SignedHeaders", valid_612663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612664: Call_GetRebootDBInstance_612650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_612664.validator(path, query, header, formData, body)
  let scheme = call_612664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612664.url(scheme.get, call_612664.host, call_612664.base,
                         call_612664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612664, url, valid)

proc call*(call_612665: Call_GetRebootDBInstance_612650;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-10-31"): Recallable =
  ## getRebootDBInstance
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612666 = newJObject()
  add(query_612666, "ForceFailover", newJBool(ForceFailover))
  add(query_612666, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612666, "Action", newJString(Action))
  add(query_612666, "Version", newJString(Version))
  result = call_612665.call(nil, query_612666, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_612650(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_612651, base: "/",
    url: url_GetRebootDBInstance_612652, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_612702 = ref object of OpenApiRestCall_610642
proc url_PostRemoveTagsFromResource_612704(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_612703(path: JsonNode; query: JsonNode;
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
  var valid_612705 = query.getOrDefault("Action")
  valid_612705 = validateParameter(valid_612705, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_612705 != nil:
    section.add "Action", valid_612705
  var valid_612706 = query.getOrDefault("Version")
  valid_612706 = validateParameter(valid_612706, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612706 != nil:
    section.add "Version", valid_612706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612707 = header.getOrDefault("X-Amz-Signature")
  valid_612707 = validateParameter(valid_612707, JString, required = false,
                                 default = nil)
  if valid_612707 != nil:
    section.add "X-Amz-Signature", valid_612707
  var valid_612708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612708 = validateParameter(valid_612708, JString, required = false,
                                 default = nil)
  if valid_612708 != nil:
    section.add "X-Amz-Content-Sha256", valid_612708
  var valid_612709 = header.getOrDefault("X-Amz-Date")
  valid_612709 = validateParameter(valid_612709, JString, required = false,
                                 default = nil)
  if valid_612709 != nil:
    section.add "X-Amz-Date", valid_612709
  var valid_612710 = header.getOrDefault("X-Amz-Credential")
  valid_612710 = validateParameter(valid_612710, JString, required = false,
                                 default = nil)
  if valid_612710 != nil:
    section.add "X-Amz-Credential", valid_612710
  var valid_612711 = header.getOrDefault("X-Amz-Security-Token")
  valid_612711 = validateParameter(valid_612711, JString, required = false,
                                 default = nil)
  if valid_612711 != nil:
    section.add "X-Amz-Security-Token", valid_612711
  var valid_612712 = header.getOrDefault("X-Amz-Algorithm")
  valid_612712 = validateParameter(valid_612712, JString, required = false,
                                 default = nil)
  if valid_612712 != nil:
    section.add "X-Amz-Algorithm", valid_612712
  var valid_612713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612713 = validateParameter(valid_612713, JString, required = false,
                                 default = nil)
  if valid_612713 != nil:
    section.add "X-Amz-SignedHeaders", valid_612713
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_612714 = formData.getOrDefault("TagKeys")
  valid_612714 = validateParameter(valid_612714, JArray, required = true, default = nil)
  if valid_612714 != nil:
    section.add "TagKeys", valid_612714
  var valid_612715 = formData.getOrDefault("ResourceName")
  valid_612715 = validateParameter(valid_612715, JString, required = true,
                                 default = nil)
  if valid_612715 != nil:
    section.add "ResourceName", valid_612715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612716: Call_PostRemoveTagsFromResource_612702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_612716.validator(path, query, header, formData, body)
  let scheme = call_612716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612716.url(scheme.get, call_612716.host, call_612716.base,
                         call_612716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612716, url, valid)

proc call*(call_612717: Call_PostRemoveTagsFromResource_612702; TagKeys: JsonNode;
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
  var query_612718 = newJObject()
  var formData_612719 = newJObject()
  if TagKeys != nil:
    formData_612719.add "TagKeys", TagKeys
  add(query_612718, "Action", newJString(Action))
  add(query_612718, "Version", newJString(Version))
  add(formData_612719, "ResourceName", newJString(ResourceName))
  result = call_612717.call(nil, query_612718, nil, formData_612719, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_612702(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_612703, base: "/",
    url: url_PostRemoveTagsFromResource_612704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_612685 = ref object of OpenApiRestCall_610642
proc url_GetRemoveTagsFromResource_612687(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_612686(path: JsonNode; query: JsonNode;
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
  var valid_612688 = query.getOrDefault("ResourceName")
  valid_612688 = validateParameter(valid_612688, JString, required = true,
                                 default = nil)
  if valid_612688 != nil:
    section.add "ResourceName", valid_612688
  var valid_612689 = query.getOrDefault("TagKeys")
  valid_612689 = validateParameter(valid_612689, JArray, required = true, default = nil)
  if valid_612689 != nil:
    section.add "TagKeys", valid_612689
  var valid_612690 = query.getOrDefault("Action")
  valid_612690 = validateParameter(valid_612690, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_612690 != nil:
    section.add "Action", valid_612690
  var valid_612691 = query.getOrDefault("Version")
  valid_612691 = validateParameter(valid_612691, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612691 != nil:
    section.add "Version", valid_612691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612692 = header.getOrDefault("X-Amz-Signature")
  valid_612692 = validateParameter(valid_612692, JString, required = false,
                                 default = nil)
  if valid_612692 != nil:
    section.add "X-Amz-Signature", valid_612692
  var valid_612693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612693 = validateParameter(valid_612693, JString, required = false,
                                 default = nil)
  if valid_612693 != nil:
    section.add "X-Amz-Content-Sha256", valid_612693
  var valid_612694 = header.getOrDefault("X-Amz-Date")
  valid_612694 = validateParameter(valid_612694, JString, required = false,
                                 default = nil)
  if valid_612694 != nil:
    section.add "X-Amz-Date", valid_612694
  var valid_612695 = header.getOrDefault("X-Amz-Credential")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "X-Amz-Credential", valid_612695
  var valid_612696 = header.getOrDefault("X-Amz-Security-Token")
  valid_612696 = validateParameter(valid_612696, JString, required = false,
                                 default = nil)
  if valid_612696 != nil:
    section.add "X-Amz-Security-Token", valid_612696
  var valid_612697 = header.getOrDefault("X-Amz-Algorithm")
  valid_612697 = validateParameter(valid_612697, JString, required = false,
                                 default = nil)
  if valid_612697 != nil:
    section.add "X-Amz-Algorithm", valid_612697
  var valid_612698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612698 = validateParameter(valid_612698, JString, required = false,
                                 default = nil)
  if valid_612698 != nil:
    section.add "X-Amz-SignedHeaders", valid_612698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612699: Call_GetRemoveTagsFromResource_612685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_612699.validator(path, query, header, formData, body)
  let scheme = call_612699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612699.url(scheme.get, call_612699.host, call_612699.base,
                         call_612699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612699, url, valid)

proc call*(call_612700: Call_GetRemoveTagsFromResource_612685;
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
  var query_612701 = newJObject()
  add(query_612701, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_612701.add "TagKeys", TagKeys
  add(query_612701, "Action", newJString(Action))
  add(query_612701, "Version", newJString(Version))
  result = call_612700.call(nil, query_612701, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_612685(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_612686, base: "/",
    url: url_GetRemoveTagsFromResource_612687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_612738 = ref object of OpenApiRestCall_610642
proc url_PostResetDBClusterParameterGroup_612740(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBClusterParameterGroup_612739(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612741 = query.getOrDefault("Action")
  valid_612741 = validateParameter(valid_612741, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_612741 != nil:
    section.add "Action", valid_612741
  var valid_612742 = query.getOrDefault("Version")
  valid_612742 = validateParameter(valid_612742, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612742 != nil:
    section.add "Version", valid_612742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612743 = header.getOrDefault("X-Amz-Signature")
  valid_612743 = validateParameter(valid_612743, JString, required = false,
                                 default = nil)
  if valid_612743 != nil:
    section.add "X-Amz-Signature", valid_612743
  var valid_612744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612744 = validateParameter(valid_612744, JString, required = false,
                                 default = nil)
  if valid_612744 != nil:
    section.add "X-Amz-Content-Sha256", valid_612744
  var valid_612745 = header.getOrDefault("X-Amz-Date")
  valid_612745 = validateParameter(valid_612745, JString, required = false,
                                 default = nil)
  if valid_612745 != nil:
    section.add "X-Amz-Date", valid_612745
  var valid_612746 = header.getOrDefault("X-Amz-Credential")
  valid_612746 = validateParameter(valid_612746, JString, required = false,
                                 default = nil)
  if valid_612746 != nil:
    section.add "X-Amz-Credential", valid_612746
  var valid_612747 = header.getOrDefault("X-Amz-Security-Token")
  valid_612747 = validateParameter(valid_612747, JString, required = false,
                                 default = nil)
  if valid_612747 != nil:
    section.add "X-Amz-Security-Token", valid_612747
  var valid_612748 = header.getOrDefault("X-Amz-Algorithm")
  valid_612748 = validateParameter(valid_612748, JString, required = false,
                                 default = nil)
  if valid_612748 != nil:
    section.add "X-Amz-Algorithm", valid_612748
  var valid_612749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612749 = validateParameter(valid_612749, JString, required = false,
                                 default = nil)
  if valid_612749 != nil:
    section.add "X-Amz-SignedHeaders", valid_612749
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Parameters: JArray
  ##             : A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to reset.
  section = newJObject()
  var valid_612750 = formData.getOrDefault("ResetAllParameters")
  valid_612750 = validateParameter(valid_612750, JBool, required = false, default = nil)
  if valid_612750 != nil:
    section.add "ResetAllParameters", valid_612750
  var valid_612751 = formData.getOrDefault("Parameters")
  valid_612751 = validateParameter(valid_612751, JArray, required = false,
                                 default = nil)
  if valid_612751 != nil:
    section.add "Parameters", valid_612751
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_612752 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_612752 = validateParameter(valid_612752, JString, required = true,
                                 default = nil)
  if valid_612752 != nil:
    section.add "DBClusterParameterGroupName", valid_612752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612753: Call_PostResetDBClusterParameterGroup_612738;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_612753.validator(path, query, header, formData, body)
  let scheme = call_612753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612753.url(scheme.get, call_612753.host, call_612753.base,
                         call_612753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612753, url, valid)

proc call*(call_612754: Call_PostResetDBClusterParameterGroup_612738;
          DBClusterParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBClusterParameterGroup";
          Parameters: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Action: string (required)
  ##   Parameters: JArray
  ##             : A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the cluster parameter group to reset.
  ##   Version: string (required)
  var query_612755 = newJObject()
  var formData_612756 = newJObject()
  add(formData_612756, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_612755, "Action", newJString(Action))
  if Parameters != nil:
    formData_612756.add "Parameters", Parameters
  add(formData_612756, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_612755, "Version", newJString(Version))
  result = call_612754.call(nil, query_612755, nil, formData_612756, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_612738(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_612739, base: "/",
    url: url_PostResetDBClusterParameterGroup_612740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_612720 = ref object of OpenApiRestCall_610642
proc url_GetResetDBClusterParameterGroup_612722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBClusterParameterGroup_612721(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612723 = query.getOrDefault("Parameters")
  valid_612723 = validateParameter(valid_612723, JArray, required = false,
                                 default = nil)
  if valid_612723 != nil:
    section.add "Parameters", valid_612723
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_612724 = query.getOrDefault("DBClusterParameterGroupName")
  valid_612724 = validateParameter(valid_612724, JString, required = true,
                                 default = nil)
  if valid_612724 != nil:
    section.add "DBClusterParameterGroupName", valid_612724
  var valid_612725 = query.getOrDefault("ResetAllParameters")
  valid_612725 = validateParameter(valid_612725, JBool, required = false, default = nil)
  if valid_612725 != nil:
    section.add "ResetAllParameters", valid_612725
  var valid_612726 = query.getOrDefault("Action")
  valid_612726 = validateParameter(valid_612726, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_612726 != nil:
    section.add "Action", valid_612726
  var valid_612727 = query.getOrDefault("Version")
  valid_612727 = validateParameter(valid_612727, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612727 != nil:
    section.add "Version", valid_612727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612728 = header.getOrDefault("X-Amz-Signature")
  valid_612728 = validateParameter(valid_612728, JString, required = false,
                                 default = nil)
  if valid_612728 != nil:
    section.add "X-Amz-Signature", valid_612728
  var valid_612729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612729 = validateParameter(valid_612729, JString, required = false,
                                 default = nil)
  if valid_612729 != nil:
    section.add "X-Amz-Content-Sha256", valid_612729
  var valid_612730 = header.getOrDefault("X-Amz-Date")
  valid_612730 = validateParameter(valid_612730, JString, required = false,
                                 default = nil)
  if valid_612730 != nil:
    section.add "X-Amz-Date", valid_612730
  var valid_612731 = header.getOrDefault("X-Amz-Credential")
  valid_612731 = validateParameter(valid_612731, JString, required = false,
                                 default = nil)
  if valid_612731 != nil:
    section.add "X-Amz-Credential", valid_612731
  var valid_612732 = header.getOrDefault("X-Amz-Security-Token")
  valid_612732 = validateParameter(valid_612732, JString, required = false,
                                 default = nil)
  if valid_612732 != nil:
    section.add "X-Amz-Security-Token", valid_612732
  var valid_612733 = header.getOrDefault("X-Amz-Algorithm")
  valid_612733 = validateParameter(valid_612733, JString, required = false,
                                 default = nil)
  if valid_612733 != nil:
    section.add "X-Amz-Algorithm", valid_612733
  var valid_612734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612734 = validateParameter(valid_612734, JString, required = false,
                                 default = nil)
  if valid_612734 != nil:
    section.add "X-Amz-SignedHeaders", valid_612734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612735: Call_GetResetDBClusterParameterGroup_612720;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_612735.validator(path, query, header, formData, body)
  let scheme = call_612735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612735.url(scheme.get, call_612735.host, call_612735.base,
                         call_612735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612735, url, valid)

proc call*(call_612736: Call_GetResetDBClusterParameterGroup_612720;
          DBClusterParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   Parameters: JArray
  ##             : A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the cluster parameter group to reset.
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612737 = newJObject()
  if Parameters != nil:
    query_612737.add "Parameters", Parameters
  add(query_612737, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_612737, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_612737, "Action", newJString(Action))
  add(query_612737, "Version", newJString(Version))
  result = call_612736.call(nil, query_612737, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_612720(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_612721, base: "/",
    url: url_GetResetDBClusterParameterGroup_612722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_612784 = ref object of OpenApiRestCall_610642
proc url_PostRestoreDBClusterFromSnapshot_612786(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBClusterFromSnapshot_612785(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612787 = query.getOrDefault("Action")
  valid_612787 = validateParameter(valid_612787, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_612787 != nil:
    section.add "Action", valid_612787
  var valid_612788 = query.getOrDefault("Version")
  valid_612788 = validateParameter(valid_612788, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612788 != nil:
    section.add "Version", valid_612788
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612789 = header.getOrDefault("X-Amz-Signature")
  valid_612789 = validateParameter(valid_612789, JString, required = false,
                                 default = nil)
  if valid_612789 != nil:
    section.add "X-Amz-Signature", valid_612789
  var valid_612790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612790 = validateParameter(valid_612790, JString, required = false,
                                 default = nil)
  if valid_612790 != nil:
    section.add "X-Amz-Content-Sha256", valid_612790
  var valid_612791 = header.getOrDefault("X-Amz-Date")
  valid_612791 = validateParameter(valid_612791, JString, required = false,
                                 default = nil)
  if valid_612791 != nil:
    section.add "X-Amz-Date", valid_612791
  var valid_612792 = header.getOrDefault("X-Amz-Credential")
  valid_612792 = validateParameter(valid_612792, JString, required = false,
                                 default = nil)
  if valid_612792 != nil:
    section.add "X-Amz-Credential", valid_612792
  var valid_612793 = header.getOrDefault("X-Amz-Security-Token")
  valid_612793 = validateParameter(valid_612793, JString, required = false,
                                 default = nil)
  if valid_612793 != nil:
    section.add "X-Amz-Security-Token", valid_612793
  var valid_612794 = header.getOrDefault("X-Amz-Algorithm")
  valid_612794 = validateParameter(valid_612794, JString, required = false,
                                 default = nil)
  if valid_612794 != nil:
    section.add "X-Amz-Algorithm", valid_612794
  var valid_612795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612795 = validateParameter(valid_612795, JString, required = false,
                                 default = nil)
  if valid_612795 != nil:
    section.add "X-Amz-SignedHeaders", valid_612795
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new cluster.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new cluster will belong to.
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the cluster to create from the snapshot or cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  section = newJObject()
  var valid_612796 = formData.getOrDefault("Port")
  valid_612796 = validateParameter(valid_612796, JInt, required = false, default = nil)
  if valid_612796 != nil:
    section.add "Port", valid_612796
  var valid_612797 = formData.getOrDefault("EngineVersion")
  valid_612797 = validateParameter(valid_612797, JString, required = false,
                                 default = nil)
  if valid_612797 != nil:
    section.add "EngineVersion", valid_612797
  var valid_612798 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_612798 = validateParameter(valid_612798, JArray, required = false,
                                 default = nil)
  if valid_612798 != nil:
    section.add "VpcSecurityGroupIds", valid_612798
  var valid_612799 = formData.getOrDefault("AvailabilityZones")
  valid_612799 = validateParameter(valid_612799, JArray, required = false,
                                 default = nil)
  if valid_612799 != nil:
    section.add "AvailabilityZones", valid_612799
  var valid_612800 = formData.getOrDefault("KmsKeyId")
  valid_612800 = validateParameter(valid_612800, JString, required = false,
                                 default = nil)
  if valid_612800 != nil:
    section.add "KmsKeyId", valid_612800
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_612801 = formData.getOrDefault("Engine")
  valid_612801 = validateParameter(valid_612801, JString, required = true,
                                 default = nil)
  if valid_612801 != nil:
    section.add "Engine", valid_612801
  var valid_612802 = formData.getOrDefault("SnapshotIdentifier")
  valid_612802 = validateParameter(valid_612802, JString, required = true,
                                 default = nil)
  if valid_612802 != nil:
    section.add "SnapshotIdentifier", valid_612802
  var valid_612803 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_612803 = validateParameter(valid_612803, JArray, required = false,
                                 default = nil)
  if valid_612803 != nil:
    section.add "EnableCloudwatchLogsExports", valid_612803
  var valid_612804 = formData.getOrDefault("Tags")
  valid_612804 = validateParameter(valid_612804, JArray, required = false,
                                 default = nil)
  if valid_612804 != nil:
    section.add "Tags", valid_612804
  var valid_612805 = formData.getOrDefault("DBSubnetGroupName")
  valid_612805 = validateParameter(valid_612805, JString, required = false,
                                 default = nil)
  if valid_612805 != nil:
    section.add "DBSubnetGroupName", valid_612805
  var valid_612806 = formData.getOrDefault("DBClusterIdentifier")
  valid_612806 = validateParameter(valid_612806, JString, required = true,
                                 default = nil)
  if valid_612806 != nil:
    section.add "DBClusterIdentifier", valid_612806
  var valid_612807 = formData.getOrDefault("DeletionProtection")
  valid_612807 = validateParameter(valid_612807, JBool, required = false, default = nil)
  if valid_612807 != nil:
    section.add "DeletionProtection", valid_612807
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612808: Call_PostRestoreDBClusterFromSnapshot_612784;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  let valid = call_612808.validator(path, query, header, formData, body)
  let scheme = call_612808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612808.url(scheme.get, call_612808.host, call_612808.base,
                         call_612808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612808, url, valid)

proc call*(call_612809: Call_PostRestoreDBClusterFromSnapshot_612784;
          Engine: string; SnapshotIdentifier: string; DBClusterIdentifier: string;
          Port: int = 0; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZones: JsonNode = nil;
          KmsKeyId: string = ""; EnableCloudwatchLogsExports: JsonNode = nil;
          Action: string = "RestoreDBClusterFromSnapshot"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; Version: string = "2014-10-31";
          DeletionProtection: bool = false): Recallable =
  ## postRestoreDBClusterFromSnapshot
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new cluster.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new cluster will belong to.
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the cluster to create from the snapshot or cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  var query_612810 = newJObject()
  var formData_612811 = newJObject()
  add(formData_612811, "Port", newJInt(Port))
  add(formData_612811, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_612811.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_612811.add "AvailabilityZones", AvailabilityZones
  add(formData_612811, "KmsKeyId", newJString(KmsKeyId))
  add(formData_612811, "Engine", newJString(Engine))
  add(formData_612811, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if EnableCloudwatchLogsExports != nil:
    formData_612811.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_612810, "Action", newJString(Action))
  if Tags != nil:
    formData_612811.add "Tags", Tags
  add(formData_612811, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612810, "Version", newJString(Version))
  add(formData_612811, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_612811, "DeletionProtection", newJBool(DeletionProtection))
  result = call_612809.call(nil, query_612810, nil, formData_612811, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_612784(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_612785, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_612786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_612757 = ref object of OpenApiRestCall_610642
proc url_GetRestoreDBClusterFromSnapshot_612759(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBClusterFromSnapshot_612758(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the cluster to create from the snapshot or cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new cluster.
  ##   Action: JString (required)
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new cluster will belong to.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_612760 = query.getOrDefault("DeletionProtection")
  valid_612760 = validateParameter(valid_612760, JBool, required = false, default = nil)
  if valid_612760 != nil:
    section.add "DeletionProtection", valid_612760
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_612761 = query.getOrDefault("Engine")
  valid_612761 = validateParameter(valid_612761, JString, required = true,
                                 default = nil)
  if valid_612761 != nil:
    section.add "Engine", valid_612761
  var valid_612762 = query.getOrDefault("SnapshotIdentifier")
  valid_612762 = validateParameter(valid_612762, JString, required = true,
                                 default = nil)
  if valid_612762 != nil:
    section.add "SnapshotIdentifier", valid_612762
  var valid_612763 = query.getOrDefault("Tags")
  valid_612763 = validateParameter(valid_612763, JArray, required = false,
                                 default = nil)
  if valid_612763 != nil:
    section.add "Tags", valid_612763
  var valid_612764 = query.getOrDefault("KmsKeyId")
  valid_612764 = validateParameter(valid_612764, JString, required = false,
                                 default = nil)
  if valid_612764 != nil:
    section.add "KmsKeyId", valid_612764
  var valid_612765 = query.getOrDefault("DBClusterIdentifier")
  valid_612765 = validateParameter(valid_612765, JString, required = true,
                                 default = nil)
  if valid_612765 != nil:
    section.add "DBClusterIdentifier", valid_612765
  var valid_612766 = query.getOrDefault("AvailabilityZones")
  valid_612766 = validateParameter(valid_612766, JArray, required = false,
                                 default = nil)
  if valid_612766 != nil:
    section.add "AvailabilityZones", valid_612766
  var valid_612767 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_612767 = validateParameter(valid_612767, JArray, required = false,
                                 default = nil)
  if valid_612767 != nil:
    section.add "EnableCloudwatchLogsExports", valid_612767
  var valid_612768 = query.getOrDefault("EngineVersion")
  valid_612768 = validateParameter(valid_612768, JString, required = false,
                                 default = nil)
  if valid_612768 != nil:
    section.add "EngineVersion", valid_612768
  var valid_612769 = query.getOrDefault("Action")
  valid_612769 = validateParameter(valid_612769, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_612769 != nil:
    section.add "Action", valid_612769
  var valid_612770 = query.getOrDefault("Port")
  valid_612770 = validateParameter(valid_612770, JInt, required = false, default = nil)
  if valid_612770 != nil:
    section.add "Port", valid_612770
  var valid_612771 = query.getOrDefault("VpcSecurityGroupIds")
  valid_612771 = validateParameter(valid_612771, JArray, required = false,
                                 default = nil)
  if valid_612771 != nil:
    section.add "VpcSecurityGroupIds", valid_612771
  var valid_612772 = query.getOrDefault("DBSubnetGroupName")
  valid_612772 = validateParameter(valid_612772, JString, required = false,
                                 default = nil)
  if valid_612772 != nil:
    section.add "DBSubnetGroupName", valid_612772
  var valid_612773 = query.getOrDefault("Version")
  valid_612773 = validateParameter(valid_612773, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612773 != nil:
    section.add "Version", valid_612773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612774 = header.getOrDefault("X-Amz-Signature")
  valid_612774 = validateParameter(valid_612774, JString, required = false,
                                 default = nil)
  if valid_612774 != nil:
    section.add "X-Amz-Signature", valid_612774
  var valid_612775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612775 = validateParameter(valid_612775, JString, required = false,
                                 default = nil)
  if valid_612775 != nil:
    section.add "X-Amz-Content-Sha256", valid_612775
  var valid_612776 = header.getOrDefault("X-Amz-Date")
  valid_612776 = validateParameter(valid_612776, JString, required = false,
                                 default = nil)
  if valid_612776 != nil:
    section.add "X-Amz-Date", valid_612776
  var valid_612777 = header.getOrDefault("X-Amz-Credential")
  valid_612777 = validateParameter(valid_612777, JString, required = false,
                                 default = nil)
  if valid_612777 != nil:
    section.add "X-Amz-Credential", valid_612777
  var valid_612778 = header.getOrDefault("X-Amz-Security-Token")
  valid_612778 = validateParameter(valid_612778, JString, required = false,
                                 default = nil)
  if valid_612778 != nil:
    section.add "X-Amz-Security-Token", valid_612778
  var valid_612779 = header.getOrDefault("X-Amz-Algorithm")
  valid_612779 = validateParameter(valid_612779, JString, required = false,
                                 default = nil)
  if valid_612779 != nil:
    section.add "X-Amz-Algorithm", valid_612779
  var valid_612780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612780 = validateParameter(valid_612780, JString, required = false,
                                 default = nil)
  if valid_612780 != nil:
    section.add "X-Amz-SignedHeaders", valid_612780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612781: Call_GetRestoreDBClusterFromSnapshot_612757;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  let valid = call_612781.validator(path, query, header, formData, body)
  let scheme = call_612781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612781.url(scheme.get, call_612781.host, call_612781.base,
                         call_612781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612781, url, valid)

proc call*(call_612782: Call_GetRestoreDBClusterFromSnapshot_612757;
          Engine: string; SnapshotIdentifier: string; DBClusterIdentifier: string;
          DeletionProtection: bool = false; Tags: JsonNode = nil; KmsKeyId: string = "";
          AvailabilityZones: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; EngineVersion: string = "";
          Action: string = "RestoreDBClusterFromSnapshot"; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; DBSubnetGroupName: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterFromSnapshot
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the cluster to create from the snapshot or cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new cluster.
  ##   Action: string (required)
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new cluster will belong to.
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_612783 = newJObject()
  add(query_612783, "DeletionProtection", newJBool(DeletionProtection))
  add(query_612783, "Engine", newJString(Engine))
  add(query_612783, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if Tags != nil:
    query_612783.add "Tags", Tags
  add(query_612783, "KmsKeyId", newJString(KmsKeyId))
  add(query_612783, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if AvailabilityZones != nil:
    query_612783.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    query_612783.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_612783, "EngineVersion", newJString(EngineVersion))
  add(query_612783, "Action", newJString(Action))
  add(query_612783, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_612783.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_612783, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612783, "Version", newJString(Version))
  result = call_612782.call(nil, query_612783, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_612757(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_612758, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_612759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_612838 = ref object of OpenApiRestCall_610642
proc url_PostRestoreDBClusterToPointInTime_612840(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBClusterToPointInTime_612839(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612841 = query.getOrDefault("Action")
  valid_612841 = validateParameter(valid_612841, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_612841 != nil:
    section.add "Action", valid_612841
  var valid_612842 = query.getOrDefault("Version")
  valid_612842 = validateParameter(valid_612842, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612842 != nil:
    section.add "Version", valid_612842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612843 = header.getOrDefault("X-Amz-Signature")
  valid_612843 = validateParameter(valid_612843, JString, required = false,
                                 default = nil)
  if valid_612843 != nil:
    section.add "X-Amz-Signature", valid_612843
  var valid_612844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612844 = validateParameter(valid_612844, JString, required = false,
                                 default = nil)
  if valid_612844 != nil:
    section.add "X-Amz-Content-Sha256", valid_612844
  var valid_612845 = header.getOrDefault("X-Amz-Date")
  valid_612845 = validateParameter(valid_612845, JString, required = false,
                                 default = nil)
  if valid_612845 != nil:
    section.add "X-Amz-Date", valid_612845
  var valid_612846 = header.getOrDefault("X-Amz-Credential")
  valid_612846 = validateParameter(valid_612846, JString, required = false,
                                 default = nil)
  if valid_612846 != nil:
    section.add "X-Amz-Credential", valid_612846
  var valid_612847 = header.getOrDefault("X-Amz-Security-Token")
  valid_612847 = validateParameter(valid_612847, JString, required = false,
                                 default = nil)
  if valid_612847 != nil:
    section.add "X-Amz-Security-Token", valid_612847
  var valid_612848 = header.getOrDefault("X-Amz-Algorithm")
  valid_612848 = validateParameter(valid_612848, JString, required = false,
                                 default = nil)
  if valid_612848 != nil:
    section.add "X-Amz-Algorithm", valid_612848
  var valid_612849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612849 = validateParameter(valid_612849, JString, required = false,
                                 default = nil)
  if valid_612849 != nil:
    section.add "X-Amz-SignedHeaders", valid_612849
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new cluster belongs to.
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  section = newJObject()
  var valid_612850 = formData.getOrDefault("Port")
  valid_612850 = validateParameter(valid_612850, JInt, required = false, default = nil)
  if valid_612850 != nil:
    section.add "Port", valid_612850
  var valid_612851 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_612851 = validateParameter(valid_612851, JArray, required = false,
                                 default = nil)
  if valid_612851 != nil:
    section.add "VpcSecurityGroupIds", valid_612851
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterIdentifier` field"
  var valid_612852 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_612852 = validateParameter(valid_612852, JString, required = true,
                                 default = nil)
  if valid_612852 != nil:
    section.add "SourceDBClusterIdentifier", valid_612852
  var valid_612853 = formData.getOrDefault("KmsKeyId")
  valid_612853 = validateParameter(valid_612853, JString, required = false,
                                 default = nil)
  if valid_612853 != nil:
    section.add "KmsKeyId", valid_612853
  var valid_612854 = formData.getOrDefault("UseLatestRestorableTime")
  valid_612854 = validateParameter(valid_612854, JBool, required = false, default = nil)
  if valid_612854 != nil:
    section.add "UseLatestRestorableTime", valid_612854
  var valid_612855 = formData.getOrDefault("RestoreToTime")
  valid_612855 = validateParameter(valid_612855, JString, required = false,
                                 default = nil)
  if valid_612855 != nil:
    section.add "RestoreToTime", valid_612855
  var valid_612856 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_612856 = validateParameter(valid_612856, JArray, required = false,
                                 default = nil)
  if valid_612856 != nil:
    section.add "EnableCloudwatchLogsExports", valid_612856
  var valid_612857 = formData.getOrDefault("Tags")
  valid_612857 = validateParameter(valid_612857, JArray, required = false,
                                 default = nil)
  if valid_612857 != nil:
    section.add "Tags", valid_612857
  var valid_612858 = formData.getOrDefault("DBSubnetGroupName")
  valid_612858 = validateParameter(valid_612858, JString, required = false,
                                 default = nil)
  if valid_612858 != nil:
    section.add "DBSubnetGroupName", valid_612858
  var valid_612859 = formData.getOrDefault("DBClusterIdentifier")
  valid_612859 = validateParameter(valid_612859, JString, required = true,
                                 default = nil)
  if valid_612859 != nil:
    section.add "DBClusterIdentifier", valid_612859
  var valid_612860 = formData.getOrDefault("DeletionProtection")
  valid_612860 = validateParameter(valid_612860, JBool, required = false, default = nil)
  if valid_612860 != nil:
    section.add "DeletionProtection", valid_612860
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612861: Call_PostRestoreDBClusterToPointInTime_612838;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ## 
  let valid = call_612861.validator(path, query, header, formData, body)
  let scheme = call_612861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612861.url(scheme.get, call_612861.host, call_612861.base,
                         call_612861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612861, url, valid)

proc call*(call_612862: Call_PostRestoreDBClusterToPointInTime_612838;
          SourceDBClusterIdentifier: string; DBClusterIdentifier: string;
          Port: int = 0; VpcSecurityGroupIds: JsonNode = nil; KmsKeyId: string = "";
          UseLatestRestorableTime: bool = false; RestoreToTime: string = "";
          EnableCloudwatchLogsExports: JsonNode = nil;
          Action: string = "RestoreDBClusterToPointInTime"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; Version: string = "2014-10-31";
          DeletionProtection: bool = false): Recallable =
  ## postRestoreDBClusterToPointInTime
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new cluster belongs to.
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DBSubnetGroupName: string
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  var query_612863 = newJObject()
  var formData_612864 = newJObject()
  add(formData_612864, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_612864.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_612864, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_612864, "KmsKeyId", newJString(KmsKeyId))
  add(formData_612864, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_612864, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    formData_612864.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_612863, "Action", newJString(Action))
  if Tags != nil:
    formData_612864.add "Tags", Tags
  add(formData_612864, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612863, "Version", newJString(Version))
  add(formData_612864, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_612864, "DeletionProtection", newJBool(DeletionProtection))
  result = call_612862.call(nil, query_612863, nil, formData_612864, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_612838(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_612839, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_612840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_612812 = ref object of OpenApiRestCall_610642
proc url_GetRestoreDBClusterToPointInTime_612814(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBClusterToPointInTime_612813(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: JString (required)
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new cluster belongs to.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_612815 = query.getOrDefault("DeletionProtection")
  valid_612815 = validateParameter(valid_612815, JBool, required = false, default = nil)
  if valid_612815 != nil:
    section.add "DeletionProtection", valid_612815
  var valid_612816 = query.getOrDefault("UseLatestRestorableTime")
  valid_612816 = validateParameter(valid_612816, JBool, required = false, default = nil)
  if valid_612816 != nil:
    section.add "UseLatestRestorableTime", valid_612816
  var valid_612817 = query.getOrDefault("Tags")
  valid_612817 = validateParameter(valid_612817, JArray, required = false,
                                 default = nil)
  if valid_612817 != nil:
    section.add "Tags", valid_612817
  var valid_612818 = query.getOrDefault("KmsKeyId")
  valid_612818 = validateParameter(valid_612818, JString, required = false,
                                 default = nil)
  if valid_612818 != nil:
    section.add "KmsKeyId", valid_612818
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_612819 = query.getOrDefault("DBClusterIdentifier")
  valid_612819 = validateParameter(valid_612819, JString, required = true,
                                 default = nil)
  if valid_612819 != nil:
    section.add "DBClusterIdentifier", valid_612819
  var valid_612820 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_612820 = validateParameter(valid_612820, JString, required = true,
                                 default = nil)
  if valid_612820 != nil:
    section.add "SourceDBClusterIdentifier", valid_612820
  var valid_612821 = query.getOrDefault("RestoreToTime")
  valid_612821 = validateParameter(valid_612821, JString, required = false,
                                 default = nil)
  if valid_612821 != nil:
    section.add "RestoreToTime", valid_612821
  var valid_612822 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_612822 = validateParameter(valid_612822, JArray, required = false,
                                 default = nil)
  if valid_612822 != nil:
    section.add "EnableCloudwatchLogsExports", valid_612822
  var valid_612823 = query.getOrDefault("Action")
  valid_612823 = validateParameter(valid_612823, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_612823 != nil:
    section.add "Action", valid_612823
  var valid_612824 = query.getOrDefault("Port")
  valid_612824 = validateParameter(valid_612824, JInt, required = false, default = nil)
  if valid_612824 != nil:
    section.add "Port", valid_612824
  var valid_612825 = query.getOrDefault("VpcSecurityGroupIds")
  valid_612825 = validateParameter(valid_612825, JArray, required = false,
                                 default = nil)
  if valid_612825 != nil:
    section.add "VpcSecurityGroupIds", valid_612825
  var valid_612826 = query.getOrDefault("DBSubnetGroupName")
  valid_612826 = validateParameter(valid_612826, JString, required = false,
                                 default = nil)
  if valid_612826 != nil:
    section.add "DBSubnetGroupName", valid_612826
  var valid_612827 = query.getOrDefault("Version")
  valid_612827 = validateParameter(valid_612827, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612827 != nil:
    section.add "Version", valid_612827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612828 = header.getOrDefault("X-Amz-Signature")
  valid_612828 = validateParameter(valid_612828, JString, required = false,
                                 default = nil)
  if valid_612828 != nil:
    section.add "X-Amz-Signature", valid_612828
  var valid_612829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612829 = validateParameter(valid_612829, JString, required = false,
                                 default = nil)
  if valid_612829 != nil:
    section.add "X-Amz-Content-Sha256", valid_612829
  var valid_612830 = header.getOrDefault("X-Amz-Date")
  valid_612830 = validateParameter(valid_612830, JString, required = false,
                                 default = nil)
  if valid_612830 != nil:
    section.add "X-Amz-Date", valid_612830
  var valid_612831 = header.getOrDefault("X-Amz-Credential")
  valid_612831 = validateParameter(valid_612831, JString, required = false,
                                 default = nil)
  if valid_612831 != nil:
    section.add "X-Amz-Credential", valid_612831
  var valid_612832 = header.getOrDefault("X-Amz-Security-Token")
  valid_612832 = validateParameter(valid_612832, JString, required = false,
                                 default = nil)
  if valid_612832 != nil:
    section.add "X-Amz-Security-Token", valid_612832
  var valid_612833 = header.getOrDefault("X-Amz-Algorithm")
  valid_612833 = validateParameter(valid_612833, JString, required = false,
                                 default = nil)
  if valid_612833 != nil:
    section.add "X-Amz-Algorithm", valid_612833
  var valid_612834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612834 = validateParameter(valid_612834, JString, required = false,
                                 default = nil)
  if valid_612834 != nil:
    section.add "X-Amz-SignedHeaders", valid_612834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612835: Call_GetRestoreDBClusterToPointInTime_612812;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ## 
  let valid = call_612835.validator(path, query, header, formData, body)
  let scheme = call_612835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612835.url(scheme.get, call_612835.host, call_612835.base,
                         call_612835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612835, url, valid)

proc call*(call_612836: Call_GetRestoreDBClusterToPointInTime_612812;
          DBClusterIdentifier: string; SourceDBClusterIdentifier: string;
          DeletionProtection: bool = false; UseLatestRestorableTime: bool = false;
          Tags: JsonNode = nil; KmsKeyId: string = ""; RestoreToTime: string = "";
          EnableCloudwatchLogsExports: JsonNode = nil;
          Action: string = "RestoreDBClusterToPointInTime"; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; DBSubnetGroupName: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterToPointInTime
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Action: string (required)
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new cluster belongs to.
  ##   DBSubnetGroupName: string
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_612837 = newJObject()
  add(query_612837, "DeletionProtection", newJBool(DeletionProtection))
  add(query_612837, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_612837.add "Tags", Tags
  add(query_612837, "KmsKeyId", newJString(KmsKeyId))
  add(query_612837, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_612837, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_612837, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    query_612837.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_612837, "Action", newJString(Action))
  add(query_612837, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_612837.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_612837, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612837, "Version", newJString(Version))
  result = call_612836.call(nil, query_612837, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_612812(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_612813, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_612814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_612881 = ref object of OpenApiRestCall_610642
proc url_PostStartDBCluster_612883(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostStartDBCluster_612882(path: JsonNode; query: JsonNode;
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
  var valid_612884 = query.getOrDefault("Action")
  valid_612884 = validateParameter(valid_612884, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_612884 != nil:
    section.add "Action", valid_612884
  var valid_612885 = query.getOrDefault("Version")
  valid_612885 = validateParameter(valid_612885, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612885 != nil:
    section.add "Version", valid_612885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612886 = header.getOrDefault("X-Amz-Signature")
  valid_612886 = validateParameter(valid_612886, JString, required = false,
                                 default = nil)
  if valid_612886 != nil:
    section.add "X-Amz-Signature", valid_612886
  var valid_612887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612887 = validateParameter(valid_612887, JString, required = false,
                                 default = nil)
  if valid_612887 != nil:
    section.add "X-Amz-Content-Sha256", valid_612887
  var valid_612888 = header.getOrDefault("X-Amz-Date")
  valid_612888 = validateParameter(valid_612888, JString, required = false,
                                 default = nil)
  if valid_612888 != nil:
    section.add "X-Amz-Date", valid_612888
  var valid_612889 = header.getOrDefault("X-Amz-Credential")
  valid_612889 = validateParameter(valid_612889, JString, required = false,
                                 default = nil)
  if valid_612889 != nil:
    section.add "X-Amz-Credential", valid_612889
  var valid_612890 = header.getOrDefault("X-Amz-Security-Token")
  valid_612890 = validateParameter(valid_612890, JString, required = false,
                                 default = nil)
  if valid_612890 != nil:
    section.add "X-Amz-Security-Token", valid_612890
  var valid_612891 = header.getOrDefault("X-Amz-Algorithm")
  valid_612891 = validateParameter(valid_612891, JString, required = false,
                                 default = nil)
  if valid_612891 != nil:
    section.add "X-Amz-Algorithm", valid_612891
  var valid_612892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612892 = validateParameter(valid_612892, JString, required = false,
                                 default = nil)
  if valid_612892 != nil:
    section.add "X-Amz-SignedHeaders", valid_612892
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_612893 = formData.getOrDefault("DBClusterIdentifier")
  valid_612893 = validateParameter(valid_612893, JString, required = true,
                                 default = nil)
  if valid_612893 != nil:
    section.add "DBClusterIdentifier", valid_612893
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612894: Call_PostStartDBCluster_612881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_612894.validator(path, query, header, formData, body)
  let scheme = call_612894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612894.url(scheme.get, call_612894.host, call_612894.base,
                         call_612894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612894, url, valid)

proc call*(call_612895: Call_PostStartDBCluster_612881;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_612896 = newJObject()
  var formData_612897 = newJObject()
  add(query_612896, "Action", newJString(Action))
  add(query_612896, "Version", newJString(Version))
  add(formData_612897, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_612895.call(nil, query_612896, nil, formData_612897, nil)

var postStartDBCluster* = Call_PostStartDBCluster_612881(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_612882, base: "/",
    url: url_PostStartDBCluster_612883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_612865 = ref object of OpenApiRestCall_610642
proc url_GetStartDBCluster_612867(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStartDBCluster_612866(path: JsonNode; query: JsonNode;
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
  var valid_612868 = query.getOrDefault("DBClusterIdentifier")
  valid_612868 = validateParameter(valid_612868, JString, required = true,
                                 default = nil)
  if valid_612868 != nil:
    section.add "DBClusterIdentifier", valid_612868
  var valid_612869 = query.getOrDefault("Action")
  valid_612869 = validateParameter(valid_612869, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_612869 != nil:
    section.add "Action", valid_612869
  var valid_612870 = query.getOrDefault("Version")
  valid_612870 = validateParameter(valid_612870, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612870 != nil:
    section.add "Version", valid_612870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612871 = header.getOrDefault("X-Amz-Signature")
  valid_612871 = validateParameter(valid_612871, JString, required = false,
                                 default = nil)
  if valid_612871 != nil:
    section.add "X-Amz-Signature", valid_612871
  var valid_612872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612872 = validateParameter(valid_612872, JString, required = false,
                                 default = nil)
  if valid_612872 != nil:
    section.add "X-Amz-Content-Sha256", valid_612872
  var valid_612873 = header.getOrDefault("X-Amz-Date")
  valid_612873 = validateParameter(valid_612873, JString, required = false,
                                 default = nil)
  if valid_612873 != nil:
    section.add "X-Amz-Date", valid_612873
  var valid_612874 = header.getOrDefault("X-Amz-Credential")
  valid_612874 = validateParameter(valid_612874, JString, required = false,
                                 default = nil)
  if valid_612874 != nil:
    section.add "X-Amz-Credential", valid_612874
  var valid_612875 = header.getOrDefault("X-Amz-Security-Token")
  valid_612875 = validateParameter(valid_612875, JString, required = false,
                                 default = nil)
  if valid_612875 != nil:
    section.add "X-Amz-Security-Token", valid_612875
  var valid_612876 = header.getOrDefault("X-Amz-Algorithm")
  valid_612876 = validateParameter(valid_612876, JString, required = false,
                                 default = nil)
  if valid_612876 != nil:
    section.add "X-Amz-Algorithm", valid_612876
  var valid_612877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612877 = validateParameter(valid_612877, JString, required = false,
                                 default = nil)
  if valid_612877 != nil:
    section.add "X-Amz-SignedHeaders", valid_612877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612878: Call_GetStartDBCluster_612865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_612878.validator(path, query, header, formData, body)
  let scheme = call_612878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612878.url(scheme.get, call_612878.host, call_612878.base,
                         call_612878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612878, url, valid)

proc call*(call_612879: Call_GetStartDBCluster_612865; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612880 = newJObject()
  add(query_612880, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_612880, "Action", newJString(Action))
  add(query_612880, "Version", newJString(Version))
  result = call_612879.call(nil, query_612880, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_612865(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_612866,
    base: "/", url: url_GetStartDBCluster_612867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_612914 = ref object of OpenApiRestCall_610642
proc url_PostStopDBCluster_612916(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostStopDBCluster_612915(path: JsonNode; query: JsonNode;
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
  var valid_612917 = query.getOrDefault("Action")
  valid_612917 = validateParameter(valid_612917, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_612917 != nil:
    section.add "Action", valid_612917
  var valid_612918 = query.getOrDefault("Version")
  valid_612918 = validateParameter(valid_612918, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612918 != nil:
    section.add "Version", valid_612918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612919 = header.getOrDefault("X-Amz-Signature")
  valid_612919 = validateParameter(valid_612919, JString, required = false,
                                 default = nil)
  if valid_612919 != nil:
    section.add "X-Amz-Signature", valid_612919
  var valid_612920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612920 = validateParameter(valid_612920, JString, required = false,
                                 default = nil)
  if valid_612920 != nil:
    section.add "X-Amz-Content-Sha256", valid_612920
  var valid_612921 = header.getOrDefault("X-Amz-Date")
  valid_612921 = validateParameter(valid_612921, JString, required = false,
                                 default = nil)
  if valid_612921 != nil:
    section.add "X-Amz-Date", valid_612921
  var valid_612922 = header.getOrDefault("X-Amz-Credential")
  valid_612922 = validateParameter(valid_612922, JString, required = false,
                                 default = nil)
  if valid_612922 != nil:
    section.add "X-Amz-Credential", valid_612922
  var valid_612923 = header.getOrDefault("X-Amz-Security-Token")
  valid_612923 = validateParameter(valid_612923, JString, required = false,
                                 default = nil)
  if valid_612923 != nil:
    section.add "X-Amz-Security-Token", valid_612923
  var valid_612924 = header.getOrDefault("X-Amz-Algorithm")
  valid_612924 = validateParameter(valid_612924, JString, required = false,
                                 default = nil)
  if valid_612924 != nil:
    section.add "X-Amz-Algorithm", valid_612924
  var valid_612925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612925 = validateParameter(valid_612925, JString, required = false,
                                 default = nil)
  if valid_612925 != nil:
    section.add "X-Amz-SignedHeaders", valid_612925
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_612926 = formData.getOrDefault("DBClusterIdentifier")
  valid_612926 = validateParameter(valid_612926, JString, required = true,
                                 default = nil)
  if valid_612926 != nil:
    section.add "DBClusterIdentifier", valid_612926
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612927: Call_PostStopDBCluster_612914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_612927.validator(path, query, header, formData, body)
  let scheme = call_612927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612927.url(scheme.get, call_612927.host, call_612927.base,
                         call_612927.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612927, url, valid)

proc call*(call_612928: Call_PostStopDBCluster_612914; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_612929 = newJObject()
  var formData_612930 = newJObject()
  add(query_612929, "Action", newJString(Action))
  add(query_612929, "Version", newJString(Version))
  add(formData_612930, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_612928.call(nil, query_612929, nil, formData_612930, nil)

var postStopDBCluster* = Call_PostStopDBCluster_612914(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_612915,
    base: "/", url: url_PostStopDBCluster_612916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_612898 = ref object of OpenApiRestCall_610642
proc url_GetStopDBCluster_612900(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStopDBCluster_612899(path: JsonNode; query: JsonNode;
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
  var valid_612901 = query.getOrDefault("DBClusterIdentifier")
  valid_612901 = validateParameter(valid_612901, JString, required = true,
                                 default = nil)
  if valid_612901 != nil:
    section.add "DBClusterIdentifier", valid_612901
  var valid_612902 = query.getOrDefault("Action")
  valid_612902 = validateParameter(valid_612902, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_612902 != nil:
    section.add "Action", valid_612902
  var valid_612903 = query.getOrDefault("Version")
  valid_612903 = validateParameter(valid_612903, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_612903 != nil:
    section.add "Version", valid_612903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612904 = header.getOrDefault("X-Amz-Signature")
  valid_612904 = validateParameter(valid_612904, JString, required = false,
                                 default = nil)
  if valid_612904 != nil:
    section.add "X-Amz-Signature", valid_612904
  var valid_612905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612905 = validateParameter(valid_612905, JString, required = false,
                                 default = nil)
  if valid_612905 != nil:
    section.add "X-Amz-Content-Sha256", valid_612905
  var valid_612906 = header.getOrDefault("X-Amz-Date")
  valid_612906 = validateParameter(valid_612906, JString, required = false,
                                 default = nil)
  if valid_612906 != nil:
    section.add "X-Amz-Date", valid_612906
  var valid_612907 = header.getOrDefault("X-Amz-Credential")
  valid_612907 = validateParameter(valid_612907, JString, required = false,
                                 default = nil)
  if valid_612907 != nil:
    section.add "X-Amz-Credential", valid_612907
  var valid_612908 = header.getOrDefault("X-Amz-Security-Token")
  valid_612908 = validateParameter(valid_612908, JString, required = false,
                                 default = nil)
  if valid_612908 != nil:
    section.add "X-Amz-Security-Token", valid_612908
  var valid_612909 = header.getOrDefault("X-Amz-Algorithm")
  valid_612909 = validateParameter(valid_612909, JString, required = false,
                                 default = nil)
  if valid_612909 != nil:
    section.add "X-Amz-Algorithm", valid_612909
  var valid_612910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612910 = validateParameter(valid_612910, JString, required = false,
                                 default = nil)
  if valid_612910 != nil:
    section.add "X-Amz-SignedHeaders", valid_612910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612911: Call_GetStopDBCluster_612898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_612911.validator(path, query, header, formData, body)
  let scheme = call_612911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612911.url(scheme.get, call_612911.host, call_612911.base,
                         call_612911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612911, url, valid)

proc call*(call_612912: Call_GetStopDBCluster_612898; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612913 = newJObject()
  add(query_612913, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_612913, "Action", newJString(Action))
  add(query_612913, "Version", newJString(Version))
  result = call_612912.call(nil, query_612913, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_612898(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_612899,
    base: "/", url: url_GetStopDBCluster_612900,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

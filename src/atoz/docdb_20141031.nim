
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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
  Call_PostAddTagsToResource_613252 = ref object of OpenApiRestCall_612642
proc url_PostAddTagsToResource_613254(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTagsToResource_613253(path: JsonNode; query: JsonNode;
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
  var valid_613255 = query.getOrDefault("Action")
  valid_613255 = validateParameter(valid_613255, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_613255 != nil:
    section.add "Action", valid_613255
  var valid_613256 = query.getOrDefault("Version")
  valid_613256 = validateParameter(valid_613256, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613256 != nil:
    section.add "Version", valid_613256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613257 = header.getOrDefault("X-Amz-Signature")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Signature", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Content-Sha256", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Date")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Date", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Credential")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Credential", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Security-Token")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Security-Token", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Algorithm")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Algorithm", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-SignedHeaders", valid_613263
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_613264 = formData.getOrDefault("Tags")
  valid_613264 = validateParameter(valid_613264, JArray, required = true, default = nil)
  if valid_613264 != nil:
    section.add "Tags", valid_613264
  var valid_613265 = formData.getOrDefault("ResourceName")
  valid_613265 = validateParameter(valid_613265, JString, required = true,
                                 default = nil)
  if valid_613265 != nil:
    section.add "ResourceName", valid_613265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613266: Call_PostAddTagsToResource_613252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_613266.validator(path, query, header, formData, body)
  let scheme = call_613266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613266.url(scheme.get, call_613266.host, call_613266.base,
                         call_613266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613266, url, valid)

proc call*(call_613267: Call_PostAddTagsToResource_613252; Tags: JsonNode;
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
  var query_613268 = newJObject()
  var formData_613269 = newJObject()
  add(query_613268, "Action", newJString(Action))
  if Tags != nil:
    formData_613269.add "Tags", Tags
  add(query_613268, "Version", newJString(Version))
  add(formData_613269, "ResourceName", newJString(ResourceName))
  result = call_613267.call(nil, query_613268, nil, formData_613269, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_613252(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_613253, base: "/",
    url: url_PostAddTagsToResource_613254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_612980 = ref object of OpenApiRestCall_612642
proc url_GetAddTagsToResource_612982(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddTagsToResource_612981(path: JsonNode; query: JsonNode;
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
  var valid_613094 = query.getOrDefault("Tags")
  valid_613094 = validateParameter(valid_613094, JArray, required = true, default = nil)
  if valid_613094 != nil:
    section.add "Tags", valid_613094
  var valid_613095 = query.getOrDefault("ResourceName")
  valid_613095 = validateParameter(valid_613095, JString, required = true,
                                 default = nil)
  if valid_613095 != nil:
    section.add "ResourceName", valid_613095
  var valid_613109 = query.getOrDefault("Action")
  valid_613109 = validateParameter(valid_613109, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_613109 != nil:
    section.add "Action", valid_613109
  var valid_613110 = query.getOrDefault("Version")
  valid_613110 = validateParameter(valid_613110, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613110 != nil:
    section.add "Version", valid_613110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613111 = header.getOrDefault("X-Amz-Signature")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Signature", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Content-Sha256", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Date")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Date", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Credential")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Credential", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Security-Token")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Security-Token", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Algorithm")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Algorithm", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-SignedHeaders", valid_613117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613140: Call_GetAddTagsToResource_612980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_613140.validator(path, query, header, formData, body)
  let scheme = call_613140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613140.url(scheme.get, call_613140.host, call_613140.base,
                         call_613140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613140, url, valid)

proc call*(call_613211: Call_GetAddTagsToResource_612980; Tags: JsonNode;
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
  var query_613212 = newJObject()
  if Tags != nil:
    query_613212.add "Tags", Tags
  add(query_613212, "ResourceName", newJString(ResourceName))
  add(query_613212, "Action", newJString(Action))
  add(query_613212, "Version", newJString(Version))
  result = call_613211.call(nil, query_613212, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_612980(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_612981, base: "/",
    url: url_GetAddTagsToResource_612982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_613288 = ref object of OpenApiRestCall_612642
proc url_PostApplyPendingMaintenanceAction_613290(protocol: Scheme; host: string;
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

proc validate_PostApplyPendingMaintenanceAction_613289(path: JsonNode;
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
  var valid_613291 = query.getOrDefault("Action")
  valid_613291 = validateParameter(valid_613291, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_613291 != nil:
    section.add "Action", valid_613291
  var valid_613292 = query.getOrDefault("Version")
  valid_613292 = validateParameter(valid_613292, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613292 != nil:
    section.add "Version", valid_613292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613293 = header.getOrDefault("X-Amz-Signature")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Signature", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Content-Sha256", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Date")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Date", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Credential")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Credential", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Security-Token")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Security-Token", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Algorithm")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Algorithm", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-SignedHeaders", valid_613299
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
  var valid_613300 = formData.getOrDefault("ResourceIdentifier")
  valid_613300 = validateParameter(valid_613300, JString, required = true,
                                 default = nil)
  if valid_613300 != nil:
    section.add "ResourceIdentifier", valid_613300
  var valid_613301 = formData.getOrDefault("ApplyAction")
  valid_613301 = validateParameter(valid_613301, JString, required = true,
                                 default = nil)
  if valid_613301 != nil:
    section.add "ApplyAction", valid_613301
  var valid_613302 = formData.getOrDefault("OptInType")
  valid_613302 = validateParameter(valid_613302, JString, required = true,
                                 default = nil)
  if valid_613302 != nil:
    section.add "OptInType", valid_613302
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613303: Call_PostApplyPendingMaintenanceAction_613288;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_613303.validator(path, query, header, formData, body)
  let scheme = call_613303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613303.url(scheme.get, call_613303.host, call_613303.base,
                         call_613303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613303, url, valid)

proc call*(call_613304: Call_PostApplyPendingMaintenanceAction_613288;
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
  var query_613305 = newJObject()
  var formData_613306 = newJObject()
  add(formData_613306, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_613306, "ApplyAction", newJString(ApplyAction))
  add(query_613305, "Action", newJString(Action))
  add(formData_613306, "OptInType", newJString(OptInType))
  add(query_613305, "Version", newJString(Version))
  result = call_613304.call(nil, query_613305, nil, formData_613306, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_613288(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_613289, base: "/",
    url: url_PostApplyPendingMaintenanceAction_613290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_613270 = ref object of OpenApiRestCall_612642
proc url_GetApplyPendingMaintenanceAction_613272(protocol: Scheme; host: string;
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

proc validate_GetApplyPendingMaintenanceAction_613271(path: JsonNode;
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
  var valid_613273 = query.getOrDefault("ResourceIdentifier")
  valid_613273 = validateParameter(valid_613273, JString, required = true,
                                 default = nil)
  if valid_613273 != nil:
    section.add "ResourceIdentifier", valid_613273
  var valid_613274 = query.getOrDefault("ApplyAction")
  valid_613274 = validateParameter(valid_613274, JString, required = true,
                                 default = nil)
  if valid_613274 != nil:
    section.add "ApplyAction", valid_613274
  var valid_613275 = query.getOrDefault("Action")
  valid_613275 = validateParameter(valid_613275, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_613275 != nil:
    section.add "Action", valid_613275
  var valid_613276 = query.getOrDefault("OptInType")
  valid_613276 = validateParameter(valid_613276, JString, required = true,
                                 default = nil)
  if valid_613276 != nil:
    section.add "OptInType", valid_613276
  var valid_613277 = query.getOrDefault("Version")
  valid_613277 = validateParameter(valid_613277, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613277 != nil:
    section.add "Version", valid_613277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613278 = header.getOrDefault("X-Amz-Signature")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Signature", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Content-Sha256", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Date")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Date", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Credential")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Credential", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Security-Token")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Security-Token", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Algorithm")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Algorithm", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-SignedHeaders", valid_613284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613285: Call_GetApplyPendingMaintenanceAction_613270;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_613285.validator(path, query, header, formData, body)
  let scheme = call_613285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613285.url(scheme.get, call_613285.host, call_613285.base,
                         call_613285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613285, url, valid)

proc call*(call_613286: Call_GetApplyPendingMaintenanceAction_613270;
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
  var query_613287 = newJObject()
  add(query_613287, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_613287, "ApplyAction", newJString(ApplyAction))
  add(query_613287, "Action", newJString(Action))
  add(query_613287, "OptInType", newJString(OptInType))
  add(query_613287, "Version", newJString(Version))
  result = call_613286.call(nil, query_613287, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_613270(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_613271, base: "/",
    url: url_GetApplyPendingMaintenanceAction_613272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_613326 = ref object of OpenApiRestCall_612642
proc url_PostCopyDBClusterParameterGroup_613328(protocol: Scheme; host: string;
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

proc validate_PostCopyDBClusterParameterGroup_613327(path: JsonNode;
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
  var valid_613329 = query.getOrDefault("Action")
  valid_613329 = validateParameter(valid_613329, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_613329 != nil:
    section.add "Action", valid_613329
  var valid_613330 = query.getOrDefault("Version")
  valid_613330 = validateParameter(valid_613330, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613330 != nil:
    section.add "Version", valid_613330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613331 = header.getOrDefault("X-Amz-Signature")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Signature", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Content-Sha256", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Date")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Date", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Credential")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Credential", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Security-Token")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Security-Token", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Algorithm")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Algorithm", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-SignedHeaders", valid_613337
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
  var valid_613338 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_613338 = validateParameter(valid_613338, JString, required = true,
                                 default = nil)
  if valid_613338 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_613338
  var valid_613339 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_613339 = validateParameter(valid_613339, JString, required = true,
                                 default = nil)
  if valid_613339 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_613339
  var valid_613340 = formData.getOrDefault("Tags")
  valid_613340 = validateParameter(valid_613340, JArray, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "Tags", valid_613340
  var valid_613341 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_613341 = validateParameter(valid_613341, JString, required = true,
                                 default = nil)
  if valid_613341 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_613341
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613342: Call_PostCopyDBClusterParameterGroup_613326;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_613342.validator(path, query, header, formData, body)
  let scheme = call_613342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613342.url(scheme.get, call_613342.host, call_613342.base,
                         call_613342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613342, url, valid)

proc call*(call_613343: Call_PostCopyDBClusterParameterGroup_613326;
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
  var query_613344 = newJObject()
  var formData_613345 = newJObject()
  add(formData_613345, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(formData_613345, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_613344, "Action", newJString(Action))
  if Tags != nil:
    formData_613345.add "Tags", Tags
  add(query_613344, "Version", newJString(Version))
  add(formData_613345, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  result = call_613343.call(nil, query_613344, nil, formData_613345, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_613326(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_613327, base: "/",
    url: url_PostCopyDBClusterParameterGroup_613328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_613307 = ref object of OpenApiRestCall_612642
proc url_GetCopyDBClusterParameterGroup_613309(protocol: Scheme; host: string;
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

proc validate_GetCopyDBClusterParameterGroup_613308(path: JsonNode;
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
  var valid_613310 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_613310 = validateParameter(valid_613310, JString, required = true,
                                 default = nil)
  if valid_613310 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_613310
  var valid_613311 = query.getOrDefault("Tags")
  valid_613311 = validateParameter(valid_613311, JArray, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "Tags", valid_613311
  var valid_613312 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_613312 = validateParameter(valid_613312, JString, required = true,
                                 default = nil)
  if valid_613312 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_613312
  var valid_613313 = query.getOrDefault("Action")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_613313 != nil:
    section.add "Action", valid_613313
  var valid_613314 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_613314 = validateParameter(valid_613314, JString, required = true,
                                 default = nil)
  if valid_613314 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_613314
  var valid_613315 = query.getOrDefault("Version")
  valid_613315 = validateParameter(valid_613315, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613315 != nil:
    section.add "Version", valid_613315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613316 = header.getOrDefault("X-Amz-Signature")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Signature", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Content-Sha256", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Date")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Date", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Credential")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Credential", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Security-Token")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Security-Token", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Algorithm")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Algorithm", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-SignedHeaders", valid_613322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613323: Call_GetCopyDBClusterParameterGroup_613307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_613323.validator(path, query, header, formData, body)
  let scheme = call_613323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613323.url(scheme.get, call_613323.host, call_613323.base,
                         call_613323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613323, url, valid)

proc call*(call_613324: Call_GetCopyDBClusterParameterGroup_613307;
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
  var query_613325 = newJObject()
  add(query_613325, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    query_613325.add "Tags", Tags
  add(query_613325, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_613325, "Action", newJString(Action))
  add(query_613325, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_613325, "Version", newJString(Version))
  result = call_613324.call(nil, query_613325, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_613307(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_613308, base: "/",
    url: url_GetCopyDBClusterParameterGroup_613309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_613367 = ref object of OpenApiRestCall_612642
proc url_PostCopyDBClusterSnapshot_613369(protocol: Scheme; host: string;
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

proc validate_PostCopyDBClusterSnapshot_613368(path: JsonNode; query: JsonNode;
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
  var valid_613370 = query.getOrDefault("Action")
  valid_613370 = validateParameter(valid_613370, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_613370 != nil:
    section.add "Action", valid_613370
  var valid_613371 = query.getOrDefault("Version")
  valid_613371 = validateParameter(valid_613371, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613371 != nil:
    section.add "Version", valid_613371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613372 = header.getOrDefault("X-Amz-Signature")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Signature", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Content-Sha256", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Date")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Date", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Credential")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Credential", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Security-Token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Security-Token", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Algorithm")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Algorithm", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-SignedHeaders", valid_613378
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
  var valid_613379 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_613379 = validateParameter(valid_613379, JString, required = true,
                                 default = nil)
  if valid_613379 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_613379
  var valid_613380 = formData.getOrDefault("KmsKeyId")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "KmsKeyId", valid_613380
  var valid_613381 = formData.getOrDefault("PreSignedUrl")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "PreSignedUrl", valid_613381
  var valid_613382 = formData.getOrDefault("CopyTags")
  valid_613382 = validateParameter(valid_613382, JBool, required = false, default = nil)
  if valid_613382 != nil:
    section.add "CopyTags", valid_613382
  var valid_613383 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_613383 = validateParameter(valid_613383, JString, required = true,
                                 default = nil)
  if valid_613383 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_613383
  var valid_613384 = formData.getOrDefault("Tags")
  valid_613384 = validateParameter(valid_613384, JArray, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "Tags", valid_613384
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613385: Call_PostCopyDBClusterSnapshot_613367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_613385.validator(path, query, header, formData, body)
  let scheme = call_613385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613385.url(scheme.get, call_613385.host, call_613385.base,
                         call_613385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613385, url, valid)

proc call*(call_613386: Call_PostCopyDBClusterSnapshot_613367;
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
  var query_613387 = newJObject()
  var formData_613388 = newJObject()
  add(formData_613388, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_613388, "KmsKeyId", newJString(KmsKeyId))
  add(formData_613388, "PreSignedUrl", newJString(PreSignedUrl))
  add(formData_613388, "CopyTags", newJBool(CopyTags))
  add(formData_613388, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_613387, "Action", newJString(Action))
  if Tags != nil:
    formData_613388.add "Tags", Tags
  add(query_613387, "Version", newJString(Version))
  result = call_613386.call(nil, query_613387, nil, formData_613388, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_613367(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_613368, base: "/",
    url: url_PostCopyDBClusterSnapshot_613369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_613346 = ref object of OpenApiRestCall_612642
proc url_GetCopyDBClusterSnapshot_613348(protocol: Scheme; host: string;
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

proc validate_GetCopyDBClusterSnapshot_613347(path: JsonNode; query: JsonNode;
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
  var valid_613349 = query.getOrDefault("Tags")
  valid_613349 = validateParameter(valid_613349, JArray, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "Tags", valid_613349
  var valid_613350 = query.getOrDefault("KmsKeyId")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "KmsKeyId", valid_613350
  var valid_613351 = query.getOrDefault("PreSignedUrl")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "PreSignedUrl", valid_613351
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_613352 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = nil)
  if valid_613352 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_613352
  var valid_613353 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_613353 = validateParameter(valid_613353, JString, required = true,
                                 default = nil)
  if valid_613353 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_613353
  var valid_613354 = query.getOrDefault("Action")
  valid_613354 = validateParameter(valid_613354, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_613354 != nil:
    section.add "Action", valid_613354
  var valid_613355 = query.getOrDefault("CopyTags")
  valid_613355 = validateParameter(valid_613355, JBool, required = false, default = nil)
  if valid_613355 != nil:
    section.add "CopyTags", valid_613355
  var valid_613356 = query.getOrDefault("Version")
  valid_613356 = validateParameter(valid_613356, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613356 != nil:
    section.add "Version", valid_613356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613357 = header.getOrDefault("X-Amz-Signature")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Signature", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Content-Sha256", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Date")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Date", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Credential")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Credential", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Security-Token")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Security-Token", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Algorithm")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Algorithm", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-SignedHeaders", valid_613363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613364: Call_GetCopyDBClusterSnapshot_613346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_613364.validator(path, query, header, formData, body)
  let scheme = call_613364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613364.url(scheme.get, call_613364.host, call_613364.base,
                         call_613364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613364, url, valid)

proc call*(call_613365: Call_GetCopyDBClusterSnapshot_613346;
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
  var query_613366 = newJObject()
  if Tags != nil:
    query_613366.add "Tags", Tags
  add(query_613366, "KmsKeyId", newJString(KmsKeyId))
  add(query_613366, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_613366, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_613366, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_613366, "Action", newJString(Action))
  add(query_613366, "CopyTags", newJBool(CopyTags))
  add(query_613366, "Version", newJString(Version))
  result = call_613365.call(nil, query_613366, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_613346(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_613347, base: "/",
    url: url_GetCopyDBClusterSnapshot_613348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_613422 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBCluster_613424(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBCluster_613423(path: JsonNode; query: JsonNode;
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
  var valid_613425 = query.getOrDefault("Action")
  valid_613425 = validateParameter(valid_613425, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_613425 != nil:
    section.add "Action", valid_613425
  var valid_613426 = query.getOrDefault("Version")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613426 != nil:
    section.add "Version", valid_613426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613427 = header.getOrDefault("X-Amz-Signature")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Signature", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Content-Sha256", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Date")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Date", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Credential")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Credential", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Security-Token")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Security-Token", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Algorithm")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Algorithm", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-SignedHeaders", valid_613433
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
  var valid_613434 = formData.getOrDefault("Port")
  valid_613434 = validateParameter(valid_613434, JInt, required = false, default = nil)
  if valid_613434 != nil:
    section.add "Port", valid_613434
  var valid_613435 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "PreferredMaintenanceWindow", valid_613435
  var valid_613436 = formData.getOrDefault("PreferredBackupWindow")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "PreferredBackupWindow", valid_613436
  assert formData != nil, "formData argument is necessary due to required `MasterUserPassword` field"
  var valid_613437 = formData.getOrDefault("MasterUserPassword")
  valid_613437 = validateParameter(valid_613437, JString, required = true,
                                 default = nil)
  if valid_613437 != nil:
    section.add "MasterUserPassword", valid_613437
  var valid_613438 = formData.getOrDefault("MasterUsername")
  valid_613438 = validateParameter(valid_613438, JString, required = true,
                                 default = nil)
  if valid_613438 != nil:
    section.add "MasterUsername", valid_613438
  var valid_613439 = formData.getOrDefault("EngineVersion")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "EngineVersion", valid_613439
  var valid_613440 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_613440 = validateParameter(valid_613440, JArray, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "VpcSecurityGroupIds", valid_613440
  var valid_613441 = formData.getOrDefault("AvailabilityZones")
  valid_613441 = validateParameter(valid_613441, JArray, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "AvailabilityZones", valid_613441
  var valid_613442 = formData.getOrDefault("BackupRetentionPeriod")
  valid_613442 = validateParameter(valid_613442, JInt, required = false, default = nil)
  if valid_613442 != nil:
    section.add "BackupRetentionPeriod", valid_613442
  var valid_613443 = formData.getOrDefault("Engine")
  valid_613443 = validateParameter(valid_613443, JString, required = true,
                                 default = nil)
  if valid_613443 != nil:
    section.add "Engine", valid_613443
  var valid_613444 = formData.getOrDefault("KmsKeyId")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "KmsKeyId", valid_613444
  var valid_613445 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_613445 = validateParameter(valid_613445, JArray, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "EnableCloudwatchLogsExports", valid_613445
  var valid_613446 = formData.getOrDefault("Tags")
  valid_613446 = validateParameter(valid_613446, JArray, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "Tags", valid_613446
  var valid_613447 = formData.getOrDefault("DBSubnetGroupName")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "DBSubnetGroupName", valid_613447
  var valid_613448 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "DBClusterParameterGroupName", valid_613448
  var valid_613449 = formData.getOrDefault("StorageEncrypted")
  valid_613449 = validateParameter(valid_613449, JBool, required = false, default = nil)
  if valid_613449 != nil:
    section.add "StorageEncrypted", valid_613449
  var valid_613450 = formData.getOrDefault("DBClusterIdentifier")
  valid_613450 = validateParameter(valid_613450, JString, required = true,
                                 default = nil)
  if valid_613450 != nil:
    section.add "DBClusterIdentifier", valid_613450
  var valid_613451 = formData.getOrDefault("DeletionProtection")
  valid_613451 = validateParameter(valid_613451, JBool, required = false, default = nil)
  if valid_613451 != nil:
    section.add "DeletionProtection", valid_613451
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613452: Call_PostCreateDBCluster_613422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_613452.validator(path, query, header, formData, body)
  let scheme = call_613452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613452.url(scheme.get, call_613452.host, call_613452.base,
                         call_613452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613452, url, valid)

proc call*(call_613453: Call_PostCreateDBCluster_613422;
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
  var query_613454 = newJObject()
  var formData_613455 = newJObject()
  add(formData_613455, "Port", newJInt(Port))
  add(formData_613455, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_613455, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_613455, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_613455, "MasterUsername", newJString(MasterUsername))
  add(formData_613455, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_613455.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_613455.add "AvailabilityZones", AvailabilityZones
  add(formData_613455, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_613455, "Engine", newJString(Engine))
  add(formData_613455, "KmsKeyId", newJString(KmsKeyId))
  if EnableCloudwatchLogsExports != nil:
    formData_613455.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_613454, "Action", newJString(Action))
  if Tags != nil:
    formData_613455.add "Tags", Tags
  add(formData_613455, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613455, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_613454, "Version", newJString(Version))
  add(formData_613455, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_613455, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_613455, "DeletionProtection", newJBool(DeletionProtection))
  result = call_613453.call(nil, query_613454, nil, formData_613455, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_613422(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_613423, base: "/",
    url: url_PostCreateDBCluster_613424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_613389 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBCluster_613391(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBCluster_613390(path: JsonNode; query: JsonNode;
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
  var valid_613392 = query.getOrDefault("StorageEncrypted")
  valid_613392 = validateParameter(valid_613392, JBool, required = false, default = nil)
  if valid_613392 != nil:
    section.add "StorageEncrypted", valid_613392
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_613393 = query.getOrDefault("Engine")
  valid_613393 = validateParameter(valid_613393, JString, required = true,
                                 default = nil)
  if valid_613393 != nil:
    section.add "Engine", valid_613393
  var valid_613394 = query.getOrDefault("DeletionProtection")
  valid_613394 = validateParameter(valid_613394, JBool, required = false, default = nil)
  if valid_613394 != nil:
    section.add "DeletionProtection", valid_613394
  var valid_613395 = query.getOrDefault("Tags")
  valid_613395 = validateParameter(valid_613395, JArray, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "Tags", valid_613395
  var valid_613396 = query.getOrDefault("KmsKeyId")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "KmsKeyId", valid_613396
  var valid_613397 = query.getOrDefault("DBClusterIdentifier")
  valid_613397 = validateParameter(valid_613397, JString, required = true,
                                 default = nil)
  if valid_613397 != nil:
    section.add "DBClusterIdentifier", valid_613397
  var valid_613398 = query.getOrDefault("DBClusterParameterGroupName")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "DBClusterParameterGroupName", valid_613398
  var valid_613399 = query.getOrDefault("AvailabilityZones")
  valid_613399 = validateParameter(valid_613399, JArray, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "AvailabilityZones", valid_613399
  var valid_613400 = query.getOrDefault("MasterUsername")
  valid_613400 = validateParameter(valid_613400, JString, required = true,
                                 default = nil)
  if valid_613400 != nil:
    section.add "MasterUsername", valid_613400
  var valid_613401 = query.getOrDefault("BackupRetentionPeriod")
  valid_613401 = validateParameter(valid_613401, JInt, required = false, default = nil)
  if valid_613401 != nil:
    section.add "BackupRetentionPeriod", valid_613401
  var valid_613402 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_613402 = validateParameter(valid_613402, JArray, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "EnableCloudwatchLogsExports", valid_613402
  var valid_613403 = query.getOrDefault("EngineVersion")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "EngineVersion", valid_613403
  var valid_613404 = query.getOrDefault("Action")
  valid_613404 = validateParameter(valid_613404, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_613404 != nil:
    section.add "Action", valid_613404
  var valid_613405 = query.getOrDefault("Port")
  valid_613405 = validateParameter(valid_613405, JInt, required = false, default = nil)
  if valid_613405 != nil:
    section.add "Port", valid_613405
  var valid_613406 = query.getOrDefault("VpcSecurityGroupIds")
  valid_613406 = validateParameter(valid_613406, JArray, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "VpcSecurityGroupIds", valid_613406
  var valid_613407 = query.getOrDefault("MasterUserPassword")
  valid_613407 = validateParameter(valid_613407, JString, required = true,
                                 default = nil)
  if valid_613407 != nil:
    section.add "MasterUserPassword", valid_613407
  var valid_613408 = query.getOrDefault("DBSubnetGroupName")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "DBSubnetGroupName", valid_613408
  var valid_613409 = query.getOrDefault("PreferredBackupWindow")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "PreferredBackupWindow", valid_613409
  var valid_613410 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "PreferredMaintenanceWindow", valid_613410
  var valid_613411 = query.getOrDefault("Version")
  valid_613411 = validateParameter(valid_613411, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613411 != nil:
    section.add "Version", valid_613411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613412 = header.getOrDefault("X-Amz-Signature")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Signature", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Content-Sha256", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Date")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Date", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Credential")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Credential", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Security-Token")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Security-Token", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Algorithm")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Algorithm", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-SignedHeaders", valid_613418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613419: Call_GetCreateDBCluster_613389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_613419.validator(path, query, header, formData, body)
  let scheme = call_613419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613419.url(scheme.get, call_613419.host, call_613419.base,
                         call_613419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613419, url, valid)

proc call*(call_613420: Call_GetCreateDBCluster_613389; Engine: string;
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
  var query_613421 = newJObject()
  add(query_613421, "StorageEncrypted", newJBool(StorageEncrypted))
  add(query_613421, "Engine", newJString(Engine))
  add(query_613421, "DeletionProtection", newJBool(DeletionProtection))
  if Tags != nil:
    query_613421.add "Tags", Tags
  add(query_613421, "KmsKeyId", newJString(KmsKeyId))
  add(query_613421, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_613421, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if AvailabilityZones != nil:
    query_613421.add "AvailabilityZones", AvailabilityZones
  add(query_613421, "MasterUsername", newJString(MasterUsername))
  add(query_613421, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if EnableCloudwatchLogsExports != nil:
    query_613421.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_613421, "EngineVersion", newJString(EngineVersion))
  add(query_613421, "Action", newJString(Action))
  add(query_613421, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_613421.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_613421, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_613421, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613421, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_613421, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_613421, "Version", newJString(Version))
  result = call_613420.call(nil, query_613421, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_613389(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_613390,
    base: "/", url: url_GetCreateDBCluster_613391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_613475 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBClusterParameterGroup_613477(protocol: Scheme; host: string;
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

proc validate_PostCreateDBClusterParameterGroup_613476(path: JsonNode;
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
  var valid_613478 = query.getOrDefault("Action")
  valid_613478 = validateParameter(valid_613478, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_613478 != nil:
    section.add "Action", valid_613478
  var valid_613479 = query.getOrDefault("Version")
  valid_613479 = validateParameter(valid_613479, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613479 != nil:
    section.add "Version", valid_613479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613480 = header.getOrDefault("X-Amz-Signature")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Signature", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Content-Sha256", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Date")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Date", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Credential")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Credential", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Security-Token")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Security-Token", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Algorithm")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Algorithm", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-SignedHeaders", valid_613486
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
  var valid_613487 = formData.getOrDefault("Description")
  valid_613487 = validateParameter(valid_613487, JString, required = true,
                                 default = nil)
  if valid_613487 != nil:
    section.add "Description", valid_613487
  var valid_613488 = formData.getOrDefault("Tags")
  valid_613488 = validateParameter(valid_613488, JArray, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "Tags", valid_613488
  var valid_613489 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_613489 = validateParameter(valid_613489, JString, required = true,
                                 default = nil)
  if valid_613489 != nil:
    section.add "DBClusterParameterGroupName", valid_613489
  var valid_613490 = formData.getOrDefault("DBParameterGroupFamily")
  valid_613490 = validateParameter(valid_613490, JString, required = true,
                                 default = nil)
  if valid_613490 != nil:
    section.add "DBParameterGroupFamily", valid_613490
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613491: Call_PostCreateDBClusterParameterGroup_613475;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_613491.validator(path, query, header, formData, body)
  let scheme = call_613491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613491.url(scheme.get, call_613491.host, call_613491.base,
                         call_613491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613491, url, valid)

proc call*(call_613492: Call_PostCreateDBClusterParameterGroup_613475;
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
  var query_613493 = newJObject()
  var formData_613494 = newJObject()
  add(formData_613494, "Description", newJString(Description))
  add(query_613493, "Action", newJString(Action))
  if Tags != nil:
    formData_613494.add "Tags", Tags
  add(formData_613494, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_613493, "Version", newJString(Version))
  add(formData_613494, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_613492.call(nil, query_613493, nil, formData_613494, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_613475(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_613476, base: "/",
    url: url_PostCreateDBClusterParameterGroup_613477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_613456 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBClusterParameterGroup_613458(protocol: Scheme; host: string;
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

proc validate_GetCreateDBClusterParameterGroup_613457(path: JsonNode;
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
  var valid_613459 = query.getOrDefault("DBParameterGroupFamily")
  valid_613459 = validateParameter(valid_613459, JString, required = true,
                                 default = nil)
  if valid_613459 != nil:
    section.add "DBParameterGroupFamily", valid_613459
  var valid_613460 = query.getOrDefault("Tags")
  valid_613460 = validateParameter(valid_613460, JArray, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "Tags", valid_613460
  var valid_613461 = query.getOrDefault("DBClusterParameterGroupName")
  valid_613461 = validateParameter(valid_613461, JString, required = true,
                                 default = nil)
  if valid_613461 != nil:
    section.add "DBClusterParameterGroupName", valid_613461
  var valid_613462 = query.getOrDefault("Action")
  valid_613462 = validateParameter(valid_613462, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_613462 != nil:
    section.add "Action", valid_613462
  var valid_613463 = query.getOrDefault("Description")
  valid_613463 = validateParameter(valid_613463, JString, required = true,
                                 default = nil)
  if valid_613463 != nil:
    section.add "Description", valid_613463
  var valid_613464 = query.getOrDefault("Version")
  valid_613464 = validateParameter(valid_613464, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613464 != nil:
    section.add "Version", valid_613464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613465 = header.getOrDefault("X-Amz-Signature")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Signature", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Content-Sha256", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Date")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Date", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Credential")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Credential", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Security-Token")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Security-Token", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Algorithm")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Algorithm", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-SignedHeaders", valid_613471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_GetCreateDBClusterParameterGroup_613456;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_GetCreateDBClusterParameterGroup_613456;
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
  var query_613474 = newJObject()
  add(query_613474, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_613474.add "Tags", Tags
  add(query_613474, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_613474, "Action", newJString(Action))
  add(query_613474, "Description", newJString(Description))
  add(query_613474, "Version", newJString(Version))
  result = call_613473.call(nil, query_613474, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_613456(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_613457, base: "/",
    url: url_GetCreateDBClusterParameterGroup_613458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_613513 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBClusterSnapshot_613515(protocol: Scheme; host: string;
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

proc validate_PostCreateDBClusterSnapshot_613514(path: JsonNode; query: JsonNode;
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
  var valid_613516 = query.getOrDefault("Action")
  valid_613516 = validateParameter(valid_613516, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_613516 != nil:
    section.add "Action", valid_613516
  var valid_613517 = query.getOrDefault("Version")
  valid_613517 = validateParameter(valid_613517, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613517 != nil:
    section.add "Version", valid_613517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613518 = header.getOrDefault("X-Amz-Signature")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Signature", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Content-Sha256", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Date")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Date", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Credential")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Credential", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Security-Token")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Security-Token", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Algorithm")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Algorithm", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-SignedHeaders", valid_613524
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
  var valid_613525 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_613525 = validateParameter(valid_613525, JString, required = true,
                                 default = nil)
  if valid_613525 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_613525
  var valid_613526 = formData.getOrDefault("Tags")
  valid_613526 = validateParameter(valid_613526, JArray, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "Tags", valid_613526
  var valid_613527 = formData.getOrDefault("DBClusterIdentifier")
  valid_613527 = validateParameter(valid_613527, JString, required = true,
                                 default = nil)
  if valid_613527 != nil:
    section.add "DBClusterIdentifier", valid_613527
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613528: Call_PostCreateDBClusterSnapshot_613513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_613528.validator(path, query, header, formData, body)
  let scheme = call_613528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613528.url(scheme.get, call_613528.host, call_613528.base,
                         call_613528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613528, url, valid)

proc call*(call_613529: Call_PostCreateDBClusterSnapshot_613513;
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
  var query_613530 = newJObject()
  var formData_613531 = newJObject()
  add(formData_613531, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_613530, "Action", newJString(Action))
  if Tags != nil:
    formData_613531.add "Tags", Tags
  add(query_613530, "Version", newJString(Version))
  add(formData_613531, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_613529.call(nil, query_613530, nil, formData_613531, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_613513(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_613514, base: "/",
    url: url_PostCreateDBClusterSnapshot_613515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_613495 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBClusterSnapshot_613497(protocol: Scheme; host: string;
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

proc validate_GetCreateDBClusterSnapshot_613496(path: JsonNode; query: JsonNode;
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
  var valid_613498 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_613498 = validateParameter(valid_613498, JString, required = true,
                                 default = nil)
  if valid_613498 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_613498
  var valid_613499 = query.getOrDefault("Tags")
  valid_613499 = validateParameter(valid_613499, JArray, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "Tags", valid_613499
  var valid_613500 = query.getOrDefault("DBClusterIdentifier")
  valid_613500 = validateParameter(valid_613500, JString, required = true,
                                 default = nil)
  if valid_613500 != nil:
    section.add "DBClusterIdentifier", valid_613500
  var valid_613501 = query.getOrDefault("Action")
  valid_613501 = validateParameter(valid_613501, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_613501 != nil:
    section.add "Action", valid_613501
  var valid_613502 = query.getOrDefault("Version")
  valid_613502 = validateParameter(valid_613502, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613502 != nil:
    section.add "Version", valid_613502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613503 = header.getOrDefault("X-Amz-Signature")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Signature", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Content-Sha256", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Date")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Date", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Credential")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Credential", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Security-Token")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Security-Token", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Algorithm")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Algorithm", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-SignedHeaders", valid_613509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613510: Call_GetCreateDBClusterSnapshot_613495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_613510.validator(path, query, header, formData, body)
  let scheme = call_613510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613510.url(scheme.get, call_613510.host, call_613510.base,
                         call_613510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613510, url, valid)

proc call*(call_613511: Call_GetCreateDBClusterSnapshot_613495;
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
  var query_613512 = newJObject()
  add(query_613512, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_613512.add "Tags", Tags
  add(query_613512, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_613512, "Action", newJString(Action))
  add(query_613512, "Version", newJString(Version))
  result = call_613511.call(nil, query_613512, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_613495(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_613496, base: "/",
    url: url_GetCreateDBClusterSnapshot_613497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_613556 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBInstance_613558(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_613557(path: JsonNode; query: JsonNode;
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
  var valid_613559 = query.getOrDefault("Action")
  valid_613559 = validateParameter(valid_613559, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_613559 != nil:
    section.add "Action", valid_613559
  var valid_613560 = query.getOrDefault("Version")
  valid_613560 = validateParameter(valid_613560, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613560 != nil:
    section.add "Version", valid_613560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613561 = header.getOrDefault("X-Amz-Signature")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Signature", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Content-Sha256", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Date")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Date", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Credential")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Credential", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Security-Token")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Security-Token", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Algorithm")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Algorithm", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-SignedHeaders", valid_613567
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
  var valid_613568 = formData.getOrDefault("PromotionTier")
  valid_613568 = validateParameter(valid_613568, JInt, required = false, default = nil)
  if valid_613568 != nil:
    section.add "PromotionTier", valid_613568
  var valid_613569 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "PreferredMaintenanceWindow", valid_613569
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_613570 = formData.getOrDefault("DBInstanceClass")
  valid_613570 = validateParameter(valid_613570, JString, required = true,
                                 default = nil)
  if valid_613570 != nil:
    section.add "DBInstanceClass", valid_613570
  var valid_613571 = formData.getOrDefault("AvailabilityZone")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "AvailabilityZone", valid_613571
  var valid_613572 = formData.getOrDefault("Engine")
  valid_613572 = validateParameter(valid_613572, JString, required = true,
                                 default = nil)
  if valid_613572 != nil:
    section.add "Engine", valid_613572
  var valid_613573 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613573 = validateParameter(valid_613573, JBool, required = false, default = nil)
  if valid_613573 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613573
  var valid_613574 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613574 = validateParameter(valid_613574, JString, required = true,
                                 default = nil)
  if valid_613574 != nil:
    section.add "DBInstanceIdentifier", valid_613574
  var valid_613575 = formData.getOrDefault("Tags")
  valid_613575 = validateParameter(valid_613575, JArray, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "Tags", valid_613575
  var valid_613576 = formData.getOrDefault("DBClusterIdentifier")
  valid_613576 = validateParameter(valid_613576, JString, required = true,
                                 default = nil)
  if valid_613576 != nil:
    section.add "DBClusterIdentifier", valid_613576
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_PostCreateDBInstance_613556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_PostCreateDBInstance_613556; DBInstanceClass: string;
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
  var query_613579 = newJObject()
  var formData_613580 = newJObject()
  add(formData_613580, "PromotionTier", newJInt(PromotionTier))
  add(formData_613580, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_613580, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613580, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613580, "Engine", newJString(Engine))
  add(formData_613580, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613580, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613579, "Action", newJString(Action))
  if Tags != nil:
    formData_613580.add "Tags", Tags
  add(query_613579, "Version", newJString(Version))
  add(formData_613580, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_613578.call(nil, query_613579, nil, formData_613580, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_613556(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_613557, base: "/",
    url: url_PostCreateDBInstance_613558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_613532 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBInstance_613534(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_613533(path: JsonNode; query: JsonNode;
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
  var valid_613535 = query.getOrDefault("Engine")
  valid_613535 = validateParameter(valid_613535, JString, required = true,
                                 default = nil)
  if valid_613535 != nil:
    section.add "Engine", valid_613535
  var valid_613536 = query.getOrDefault("Tags")
  valid_613536 = validateParameter(valid_613536, JArray, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "Tags", valid_613536
  var valid_613537 = query.getOrDefault("DBClusterIdentifier")
  valid_613537 = validateParameter(valid_613537, JString, required = true,
                                 default = nil)
  if valid_613537 != nil:
    section.add "DBClusterIdentifier", valid_613537
  var valid_613538 = query.getOrDefault("DBInstanceIdentifier")
  valid_613538 = validateParameter(valid_613538, JString, required = true,
                                 default = nil)
  if valid_613538 != nil:
    section.add "DBInstanceIdentifier", valid_613538
  var valid_613539 = query.getOrDefault("PromotionTier")
  valid_613539 = validateParameter(valid_613539, JInt, required = false, default = nil)
  if valid_613539 != nil:
    section.add "PromotionTier", valid_613539
  var valid_613540 = query.getOrDefault("Action")
  valid_613540 = validateParameter(valid_613540, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_613540 != nil:
    section.add "Action", valid_613540
  var valid_613541 = query.getOrDefault("AvailabilityZone")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "AvailabilityZone", valid_613541
  var valid_613542 = query.getOrDefault("Version")
  valid_613542 = validateParameter(valid_613542, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613542 != nil:
    section.add "Version", valid_613542
  var valid_613543 = query.getOrDefault("DBInstanceClass")
  valid_613543 = validateParameter(valid_613543, JString, required = true,
                                 default = nil)
  if valid_613543 != nil:
    section.add "DBInstanceClass", valid_613543
  var valid_613544 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "PreferredMaintenanceWindow", valid_613544
  var valid_613545 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613545 = validateParameter(valid_613545, JBool, required = false, default = nil)
  if valid_613545 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613545
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613546 = header.getOrDefault("X-Amz-Signature")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Signature", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Content-Sha256", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Date")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Date", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Credential")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Credential", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Security-Token")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Security-Token", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Algorithm")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Algorithm", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-SignedHeaders", valid_613552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613553: Call_GetCreateDBInstance_613532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_613553.validator(path, query, header, formData, body)
  let scheme = call_613553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613553.url(scheme.get, call_613553.host, call_613553.base,
                         call_613553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613553, url, valid)

proc call*(call_613554: Call_GetCreateDBInstance_613532; Engine: string;
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
  var query_613555 = newJObject()
  add(query_613555, "Engine", newJString(Engine))
  if Tags != nil:
    query_613555.add "Tags", Tags
  add(query_613555, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_613555, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613555, "PromotionTier", newJInt(PromotionTier))
  add(query_613555, "Action", newJString(Action))
  add(query_613555, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613555, "Version", newJString(Version))
  add(query_613555, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613555, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_613555, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_613554.call(nil, query_613555, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_613532(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_613533, base: "/",
    url: url_GetCreateDBInstance_613534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_613600 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSubnetGroup_613602(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_613601(path: JsonNode; query: JsonNode;
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
  var valid_613603 = query.getOrDefault("Action")
  valid_613603 = validateParameter(valid_613603, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_613603 != nil:
    section.add "Action", valid_613603
  var valid_613604 = query.getOrDefault("Version")
  valid_613604 = validateParameter(valid_613604, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613604 != nil:
    section.add "Version", valid_613604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613605 = header.getOrDefault("X-Amz-Signature")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Signature", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Content-Sha256", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Date")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Date", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Credential")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Credential", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Security-Token")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Security-Token", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Algorithm")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Algorithm", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-SignedHeaders", valid_613611
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
  var valid_613612 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_613612 = validateParameter(valid_613612, JString, required = true,
                                 default = nil)
  if valid_613612 != nil:
    section.add "DBSubnetGroupDescription", valid_613612
  var valid_613613 = formData.getOrDefault("Tags")
  valid_613613 = validateParameter(valid_613613, JArray, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "Tags", valid_613613
  var valid_613614 = formData.getOrDefault("DBSubnetGroupName")
  valid_613614 = validateParameter(valid_613614, JString, required = true,
                                 default = nil)
  if valid_613614 != nil:
    section.add "DBSubnetGroupName", valid_613614
  var valid_613615 = formData.getOrDefault("SubnetIds")
  valid_613615 = validateParameter(valid_613615, JArray, required = true, default = nil)
  if valid_613615 != nil:
    section.add "SubnetIds", valid_613615
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613616: Call_PostCreateDBSubnetGroup_613600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_613616.validator(path, query, header, formData, body)
  let scheme = call_613616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613616.url(scheme.get, call_613616.host, call_613616.base,
                         call_613616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613616, url, valid)

proc call*(call_613617: Call_PostCreateDBSubnetGroup_613600;
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
  var query_613618 = newJObject()
  var formData_613619 = newJObject()
  add(formData_613619, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613618, "Action", newJString(Action))
  if Tags != nil:
    formData_613619.add "Tags", Tags
  add(formData_613619, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613618, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_613619.add "SubnetIds", SubnetIds
  result = call_613617.call(nil, query_613618, nil, formData_613619, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_613600(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_613601, base: "/",
    url: url_PostCreateDBSubnetGroup_613602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_613581 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSubnetGroup_613583(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_613582(path: JsonNode; query: JsonNode;
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
  var valid_613584 = query.getOrDefault("Tags")
  valid_613584 = validateParameter(valid_613584, JArray, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "Tags", valid_613584
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_613585 = query.getOrDefault("SubnetIds")
  valid_613585 = validateParameter(valid_613585, JArray, required = true, default = nil)
  if valid_613585 != nil:
    section.add "SubnetIds", valid_613585
  var valid_613586 = query.getOrDefault("Action")
  valid_613586 = validateParameter(valid_613586, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_613586 != nil:
    section.add "Action", valid_613586
  var valid_613587 = query.getOrDefault("DBSubnetGroupDescription")
  valid_613587 = validateParameter(valid_613587, JString, required = true,
                                 default = nil)
  if valid_613587 != nil:
    section.add "DBSubnetGroupDescription", valid_613587
  var valid_613588 = query.getOrDefault("DBSubnetGroupName")
  valid_613588 = validateParameter(valid_613588, JString, required = true,
                                 default = nil)
  if valid_613588 != nil:
    section.add "DBSubnetGroupName", valid_613588
  var valid_613589 = query.getOrDefault("Version")
  valid_613589 = validateParameter(valid_613589, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613589 != nil:
    section.add "Version", valid_613589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613590 = header.getOrDefault("X-Amz-Signature")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Signature", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Content-Sha256", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Date")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Date", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Credential")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Credential", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Security-Token")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Security-Token", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Algorithm")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Algorithm", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-SignedHeaders", valid_613596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613597: Call_GetCreateDBSubnetGroup_613581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_613597.validator(path, query, header, formData, body)
  let scheme = call_613597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613597.url(scheme.get, call_613597.host, call_613597.base,
                         call_613597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613597, url, valid)

proc call*(call_613598: Call_GetCreateDBSubnetGroup_613581; SubnetIds: JsonNode;
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
  var query_613599 = newJObject()
  if Tags != nil:
    query_613599.add "Tags", Tags
  if SubnetIds != nil:
    query_613599.add "SubnetIds", SubnetIds
  add(query_613599, "Action", newJString(Action))
  add(query_613599, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613599, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613599, "Version", newJString(Version))
  result = call_613598.call(nil, query_613599, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_613581(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_613582, base: "/",
    url: url_GetCreateDBSubnetGroup_613583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_613638 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBCluster_613640(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBCluster_613639(path: JsonNode; query: JsonNode;
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
  var valid_613641 = query.getOrDefault("Action")
  valid_613641 = validateParameter(valid_613641, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_613641 != nil:
    section.add "Action", valid_613641
  var valid_613642 = query.getOrDefault("Version")
  valid_613642 = validateParameter(valid_613642, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613642 != nil:
    section.add "Version", valid_613642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613643 = header.getOrDefault("X-Amz-Signature")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Signature", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Content-Sha256", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Date")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Date", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Credential")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Credential", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Security-Token")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Security-Token", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Algorithm")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Algorithm", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-SignedHeaders", valid_613649
  result.add "header", section
  ## parameters in `formData` object:
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_613650 = formData.getOrDefault("SkipFinalSnapshot")
  valid_613650 = validateParameter(valid_613650, JBool, required = false, default = nil)
  if valid_613650 != nil:
    section.add "SkipFinalSnapshot", valid_613650
  var valid_613651 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_613651
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_613652 = formData.getOrDefault("DBClusterIdentifier")
  valid_613652 = validateParameter(valid_613652, JString, required = true,
                                 default = nil)
  if valid_613652 != nil:
    section.add "DBClusterIdentifier", valid_613652
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613653: Call_PostDeleteDBCluster_613638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_613653.validator(path, query, header, formData, body)
  let scheme = call_613653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613653.url(scheme.get, call_613653.host, call_613653.base,
                         call_613653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613653, url, valid)

proc call*(call_613654: Call_PostDeleteDBCluster_613638;
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
  var query_613655 = newJObject()
  var formData_613656 = newJObject()
  add(query_613655, "Action", newJString(Action))
  add(formData_613656, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_613656, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_613655, "Version", newJString(Version))
  add(formData_613656, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_613654.call(nil, query_613655, nil, formData_613656, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_613638(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_613639, base: "/",
    url: url_PostDeleteDBCluster_613640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_613620 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBCluster_613622(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBCluster_613621(path: JsonNode; query: JsonNode;
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
  var valid_613623 = query.getOrDefault("DBClusterIdentifier")
  valid_613623 = validateParameter(valid_613623, JString, required = true,
                                 default = nil)
  if valid_613623 != nil:
    section.add "DBClusterIdentifier", valid_613623
  var valid_613624 = query.getOrDefault("SkipFinalSnapshot")
  valid_613624 = validateParameter(valid_613624, JBool, required = false, default = nil)
  if valid_613624 != nil:
    section.add "SkipFinalSnapshot", valid_613624
  var valid_613625 = query.getOrDefault("Action")
  valid_613625 = validateParameter(valid_613625, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_613625 != nil:
    section.add "Action", valid_613625
  var valid_613626 = query.getOrDefault("Version")
  valid_613626 = validateParameter(valid_613626, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613626 != nil:
    section.add "Version", valid_613626
  var valid_613627 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_613627
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613628 = header.getOrDefault("X-Amz-Signature")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Signature", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Content-Sha256", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Date")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Date", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Credential")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Credential", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Security-Token")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Security-Token", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Algorithm")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Algorithm", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-SignedHeaders", valid_613634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613635: Call_GetDeleteDBCluster_613620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_613635.validator(path, query, header, formData, body)
  let scheme = call_613635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613635.url(scheme.get, call_613635.host, call_613635.base,
                         call_613635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613635, url, valid)

proc call*(call_613636: Call_GetDeleteDBCluster_613620;
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
  var query_613637 = newJObject()
  add(query_613637, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_613637, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_613637, "Action", newJString(Action))
  add(query_613637, "Version", newJString(Version))
  add(query_613637, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_613636.call(nil, query_613637, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_613620(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_613621,
    base: "/", url: url_GetDeleteDBCluster_613622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_613673 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBClusterParameterGroup_613675(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBClusterParameterGroup_613674(path: JsonNode;
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
  var valid_613676 = query.getOrDefault("Action")
  valid_613676 = validateParameter(valid_613676, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_613676 != nil:
    section.add "Action", valid_613676
  var valid_613677 = query.getOrDefault("Version")
  valid_613677 = validateParameter(valid_613677, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613677 != nil:
    section.add "Version", valid_613677
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613678 = header.getOrDefault("X-Amz-Signature")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Signature", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Content-Sha256", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Date")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Date", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Credential")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Credential", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Security-Token")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Security-Token", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Algorithm")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Algorithm", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-SignedHeaders", valid_613684
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_613685 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_613685 = validateParameter(valid_613685, JString, required = true,
                                 default = nil)
  if valid_613685 != nil:
    section.add "DBClusterParameterGroupName", valid_613685
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613686: Call_PostDeleteDBClusterParameterGroup_613673;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_613686.validator(path, query, header, formData, body)
  let scheme = call_613686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613686.url(scheme.get, call_613686.host, call_613686.base,
                         call_613686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613686, url, valid)

proc call*(call_613687: Call_PostDeleteDBClusterParameterGroup_613673;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_613688 = newJObject()
  var formData_613689 = newJObject()
  add(query_613688, "Action", newJString(Action))
  add(formData_613689, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_613688, "Version", newJString(Version))
  result = call_613687.call(nil, query_613688, nil, formData_613689, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_613673(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_613674, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_613675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_613657 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBClusterParameterGroup_613659(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBClusterParameterGroup_613658(path: JsonNode;
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
  var valid_613660 = query.getOrDefault("DBClusterParameterGroupName")
  valid_613660 = validateParameter(valid_613660, JString, required = true,
                                 default = nil)
  if valid_613660 != nil:
    section.add "DBClusterParameterGroupName", valid_613660
  var valid_613661 = query.getOrDefault("Action")
  valid_613661 = validateParameter(valid_613661, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_613661 != nil:
    section.add "Action", valid_613661
  var valid_613662 = query.getOrDefault("Version")
  valid_613662 = validateParameter(valid_613662, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613662 != nil:
    section.add "Version", valid_613662
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613663 = header.getOrDefault("X-Amz-Signature")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Signature", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Content-Sha256", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Date")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Date", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Credential")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Credential", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Security-Token")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Security-Token", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Algorithm")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Algorithm", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-SignedHeaders", valid_613669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613670: Call_GetDeleteDBClusterParameterGroup_613657;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_613670.validator(path, query, header, formData, body)
  let scheme = call_613670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613670.url(scheme.get, call_613670.host, call_613670.base,
                         call_613670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613670, url, valid)

proc call*(call_613671: Call_GetDeleteDBClusterParameterGroup_613657;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613672 = newJObject()
  add(query_613672, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_613672, "Action", newJString(Action))
  add(query_613672, "Version", newJString(Version))
  result = call_613671.call(nil, query_613672, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_613657(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_613658, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_613659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_613706 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBClusterSnapshot_613708(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBClusterSnapshot_613707(path: JsonNode; query: JsonNode;
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
  var valid_613709 = query.getOrDefault("Action")
  valid_613709 = validateParameter(valid_613709, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_613709 != nil:
    section.add "Action", valid_613709
  var valid_613710 = query.getOrDefault("Version")
  valid_613710 = validateParameter(valid_613710, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613710 != nil:
    section.add "Version", valid_613710
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613711 = header.getOrDefault("X-Amz-Signature")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Signature", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Content-Sha256", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Date")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Date", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Credential")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Credential", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Security-Token")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Security-Token", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-Algorithm")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Algorithm", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-SignedHeaders", valid_613717
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_613718 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_613718 = validateParameter(valid_613718, JString, required = true,
                                 default = nil)
  if valid_613718 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_613718
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613719: Call_PostDeleteDBClusterSnapshot_613706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_613719.validator(path, query, header, formData, body)
  let scheme = call_613719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613719.url(scheme.get, call_613719.host, call_613719.base,
                         call_613719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613719, url, valid)

proc call*(call_613720: Call_PostDeleteDBClusterSnapshot_613706;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613721 = newJObject()
  var formData_613722 = newJObject()
  add(formData_613722, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_613721, "Action", newJString(Action))
  add(query_613721, "Version", newJString(Version))
  result = call_613720.call(nil, query_613721, nil, formData_613722, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_613706(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_613707, base: "/",
    url: url_PostDeleteDBClusterSnapshot_613708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_613690 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBClusterSnapshot_613692(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBClusterSnapshot_613691(path: JsonNode; query: JsonNode;
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
  var valid_613693 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_613693 = validateParameter(valid_613693, JString, required = true,
                                 default = nil)
  if valid_613693 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_613693
  var valid_613694 = query.getOrDefault("Action")
  valid_613694 = validateParameter(valid_613694, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_613694 != nil:
    section.add "Action", valid_613694
  var valid_613695 = query.getOrDefault("Version")
  valid_613695 = validateParameter(valid_613695, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613695 != nil:
    section.add "Version", valid_613695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613696 = header.getOrDefault("X-Amz-Signature")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Signature", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Content-Sha256", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Date")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Date", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Credential")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Credential", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Security-Token")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Security-Token", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Algorithm")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Algorithm", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-SignedHeaders", valid_613702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613703: Call_GetDeleteDBClusterSnapshot_613690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_613703.validator(path, query, header, formData, body)
  let scheme = call_613703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613703.url(scheme.get, call_613703.host, call_613703.base,
                         call_613703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613703, url, valid)

proc call*(call_613704: Call_GetDeleteDBClusterSnapshot_613690;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613705 = newJObject()
  add(query_613705, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_613705, "Action", newJString(Action))
  add(query_613705, "Version", newJString(Version))
  result = call_613704.call(nil, query_613705, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_613690(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_613691, base: "/",
    url: url_GetDeleteDBClusterSnapshot_613692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_613739 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBInstance_613741(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_613740(path: JsonNode; query: JsonNode;
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
  var valid_613742 = query.getOrDefault("Action")
  valid_613742 = validateParameter(valid_613742, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_613742 != nil:
    section.add "Action", valid_613742
  var valid_613743 = query.getOrDefault("Version")
  valid_613743 = validateParameter(valid_613743, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613743 != nil:
    section.add "Version", valid_613743
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613744 = header.getOrDefault("X-Amz-Signature")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Signature", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Content-Sha256", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Date")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Date", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Credential")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Credential", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Security-Token")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Security-Token", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Algorithm")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Algorithm", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-SignedHeaders", valid_613750
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613751 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613751 = validateParameter(valid_613751, JString, required = true,
                                 default = nil)
  if valid_613751 != nil:
    section.add "DBInstanceIdentifier", valid_613751
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613752: Call_PostDeleteDBInstance_613739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_613752.validator(path, query, header, formData, body)
  let scheme = call_613752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613752.url(scheme.get, call_613752.host, call_613752.base,
                         call_613752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613752, url, valid)

proc call*(call_613753: Call_PostDeleteDBInstance_613739;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613754 = newJObject()
  var formData_613755 = newJObject()
  add(formData_613755, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613754, "Action", newJString(Action))
  add(query_613754, "Version", newJString(Version))
  result = call_613753.call(nil, query_613754, nil, formData_613755, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_613739(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_613740, base: "/",
    url: url_PostDeleteDBInstance_613741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_613723 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBInstance_613725(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_613724(path: JsonNode; query: JsonNode;
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
  var valid_613726 = query.getOrDefault("DBInstanceIdentifier")
  valid_613726 = validateParameter(valid_613726, JString, required = true,
                                 default = nil)
  if valid_613726 != nil:
    section.add "DBInstanceIdentifier", valid_613726
  var valid_613727 = query.getOrDefault("Action")
  valid_613727 = validateParameter(valid_613727, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_613727 != nil:
    section.add "Action", valid_613727
  var valid_613728 = query.getOrDefault("Version")
  valid_613728 = validateParameter(valid_613728, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613728 != nil:
    section.add "Version", valid_613728
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613729 = header.getOrDefault("X-Amz-Signature")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Signature", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Content-Sha256", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-Date")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Date", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Credential")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Credential", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Security-Token")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Security-Token", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Algorithm")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Algorithm", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-SignedHeaders", valid_613735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613736: Call_GetDeleteDBInstance_613723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_613736.validator(path, query, header, formData, body)
  let scheme = call_613736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613736.url(scheme.get, call_613736.host, call_613736.base,
                         call_613736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613736, url, valid)

proc call*(call_613737: Call_GetDeleteDBInstance_613723;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613738 = newJObject()
  add(query_613738, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613738, "Action", newJString(Action))
  add(query_613738, "Version", newJString(Version))
  result = call_613737.call(nil, query_613738, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_613723(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_613724, base: "/",
    url: url_GetDeleteDBInstance_613725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_613772 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSubnetGroup_613774(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_613773(path: JsonNode; query: JsonNode;
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
  var valid_613775 = query.getOrDefault("Action")
  valid_613775 = validateParameter(valid_613775, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_613775 != nil:
    section.add "Action", valid_613775
  var valid_613776 = query.getOrDefault("Version")
  valid_613776 = validateParameter(valid_613776, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613776 != nil:
    section.add "Version", valid_613776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613777 = header.getOrDefault("X-Amz-Signature")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Signature", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Content-Sha256", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Date")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Date", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Credential")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Credential", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Security-Token")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Security-Token", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Algorithm")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Algorithm", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-SignedHeaders", valid_613783
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_613784 = formData.getOrDefault("DBSubnetGroupName")
  valid_613784 = validateParameter(valid_613784, JString, required = true,
                                 default = nil)
  if valid_613784 != nil:
    section.add "DBSubnetGroupName", valid_613784
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613785: Call_PostDeleteDBSubnetGroup_613772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_613785.validator(path, query, header, formData, body)
  let scheme = call_613785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613785.url(scheme.get, call_613785.host, call_613785.base,
                         call_613785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613785, url, valid)

proc call*(call_613786: Call_PostDeleteDBSubnetGroup_613772;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_613787 = newJObject()
  var formData_613788 = newJObject()
  add(query_613787, "Action", newJString(Action))
  add(formData_613788, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613787, "Version", newJString(Version))
  result = call_613786.call(nil, query_613787, nil, formData_613788, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_613772(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_613773, base: "/",
    url: url_PostDeleteDBSubnetGroup_613774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_613756 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSubnetGroup_613758(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_613757(path: JsonNode; query: JsonNode;
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
  var valid_613759 = query.getOrDefault("Action")
  valid_613759 = validateParameter(valid_613759, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_613759 != nil:
    section.add "Action", valid_613759
  var valid_613760 = query.getOrDefault("DBSubnetGroupName")
  valid_613760 = validateParameter(valid_613760, JString, required = true,
                                 default = nil)
  if valid_613760 != nil:
    section.add "DBSubnetGroupName", valid_613760
  var valid_613761 = query.getOrDefault("Version")
  valid_613761 = validateParameter(valid_613761, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613761 != nil:
    section.add "Version", valid_613761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613762 = header.getOrDefault("X-Amz-Signature")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Signature", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Content-Sha256", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Date")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Date", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Credential")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Credential", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Security-Token")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Security-Token", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Algorithm")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Algorithm", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-SignedHeaders", valid_613768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613769: Call_GetDeleteDBSubnetGroup_613756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_613769.validator(path, query, header, formData, body)
  let scheme = call_613769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613769.url(scheme.get, call_613769.host, call_613769.base,
                         call_613769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613769, url, valid)

proc call*(call_613770: Call_GetDeleteDBSubnetGroup_613756;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_613771 = newJObject()
  add(query_613771, "Action", newJString(Action))
  add(query_613771, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613771, "Version", newJString(Version))
  result = call_613770.call(nil, query_613771, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_613756(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_613757, base: "/",
    url: url_GetDeleteDBSubnetGroup_613758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeCertificates_613808 = ref object of OpenApiRestCall_612642
proc url_PostDescribeCertificates_613810(protocol: Scheme; host: string;
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

proc validate_PostDescribeCertificates_613809(path: JsonNode; query: JsonNode;
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
  var valid_613811 = query.getOrDefault("Action")
  valid_613811 = validateParameter(valid_613811, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_613811 != nil:
    section.add "Action", valid_613811
  var valid_613812 = query.getOrDefault("Version")
  valid_613812 = validateParameter(valid_613812, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613812 != nil:
    section.add "Version", valid_613812
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613813 = header.getOrDefault("X-Amz-Signature")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Signature", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Content-Sha256", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Date")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Date", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Credential")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Credential", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Security-Token")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Security-Token", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Algorithm")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Algorithm", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-SignedHeaders", valid_613819
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
  var valid_613820 = formData.getOrDefault("MaxRecords")
  valid_613820 = validateParameter(valid_613820, JInt, required = false, default = nil)
  if valid_613820 != nil:
    section.add "MaxRecords", valid_613820
  var valid_613821 = formData.getOrDefault("Marker")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "Marker", valid_613821
  var valid_613822 = formData.getOrDefault("CertificateIdentifier")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "CertificateIdentifier", valid_613822
  var valid_613823 = formData.getOrDefault("Filters")
  valid_613823 = validateParameter(valid_613823, JArray, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "Filters", valid_613823
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613824: Call_PostDescribeCertificates_613808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_613824.validator(path, query, header, formData, body)
  let scheme = call_613824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613824.url(scheme.get, call_613824.host, call_613824.base,
                         call_613824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613824, url, valid)

proc call*(call_613825: Call_PostDescribeCertificates_613808; MaxRecords: int = 0;
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
  var query_613826 = newJObject()
  var formData_613827 = newJObject()
  add(formData_613827, "MaxRecords", newJInt(MaxRecords))
  add(formData_613827, "Marker", newJString(Marker))
  add(formData_613827, "CertificateIdentifier", newJString(CertificateIdentifier))
  add(query_613826, "Action", newJString(Action))
  if Filters != nil:
    formData_613827.add "Filters", Filters
  add(query_613826, "Version", newJString(Version))
  result = call_613825.call(nil, query_613826, nil, formData_613827, nil)

var postDescribeCertificates* = Call_PostDescribeCertificates_613808(
    name: "postDescribeCertificates", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_PostDescribeCertificates_613809, base: "/",
    url: url_PostDescribeCertificates_613810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeCertificates_613789 = ref object of OpenApiRestCall_612642
proc url_GetDescribeCertificates_613791(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeCertificates_613790(path: JsonNode; query: JsonNode;
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
  var valid_613792 = query.getOrDefault("Marker")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "Marker", valid_613792
  var valid_613793 = query.getOrDefault("Action")
  valid_613793 = validateParameter(valid_613793, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_613793 != nil:
    section.add "Action", valid_613793
  var valid_613794 = query.getOrDefault("Version")
  valid_613794 = validateParameter(valid_613794, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613794 != nil:
    section.add "Version", valid_613794
  var valid_613795 = query.getOrDefault("CertificateIdentifier")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "CertificateIdentifier", valid_613795
  var valid_613796 = query.getOrDefault("Filters")
  valid_613796 = validateParameter(valid_613796, JArray, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "Filters", valid_613796
  var valid_613797 = query.getOrDefault("MaxRecords")
  valid_613797 = validateParameter(valid_613797, JInt, required = false, default = nil)
  if valid_613797 != nil:
    section.add "MaxRecords", valid_613797
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613798 = header.getOrDefault("X-Amz-Signature")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Signature", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Content-Sha256", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Date")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Date", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Credential")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Credential", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Security-Token")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Security-Token", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Algorithm")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Algorithm", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-SignedHeaders", valid_613804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613805: Call_GetDescribeCertificates_613789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_613805.validator(path, query, header, formData, body)
  let scheme = call_613805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613805.url(scheme.get, call_613805.host, call_613805.base,
                         call_613805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613805, url, valid)

proc call*(call_613806: Call_GetDescribeCertificates_613789; Marker: string = "";
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
  var query_613807 = newJObject()
  add(query_613807, "Marker", newJString(Marker))
  add(query_613807, "Action", newJString(Action))
  add(query_613807, "Version", newJString(Version))
  add(query_613807, "CertificateIdentifier", newJString(CertificateIdentifier))
  if Filters != nil:
    query_613807.add "Filters", Filters
  add(query_613807, "MaxRecords", newJInt(MaxRecords))
  result = call_613806.call(nil, query_613807, nil, nil, nil)

var getDescribeCertificates* = Call_GetDescribeCertificates_613789(
    name: "getDescribeCertificates", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_GetDescribeCertificates_613790, base: "/",
    url: url_GetDescribeCertificates_613791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_613847 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBClusterParameterGroups_613849(protocol: Scheme;
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

proc validate_PostDescribeDBClusterParameterGroups_613848(path: JsonNode;
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
  var valid_613850 = query.getOrDefault("Action")
  valid_613850 = validateParameter(valid_613850, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_613850 != nil:
    section.add "Action", valid_613850
  var valid_613851 = query.getOrDefault("Version")
  valid_613851 = validateParameter(valid_613851, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613851 != nil:
    section.add "Version", valid_613851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613852 = header.getOrDefault("X-Amz-Signature")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Signature", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-Content-Sha256", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Date")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Date", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Credential")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Credential", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Security-Token")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Security-Token", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Algorithm")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Algorithm", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-SignedHeaders", valid_613858
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
  var valid_613859 = formData.getOrDefault("MaxRecords")
  valid_613859 = validateParameter(valid_613859, JInt, required = false, default = nil)
  if valid_613859 != nil:
    section.add "MaxRecords", valid_613859
  var valid_613860 = formData.getOrDefault("Marker")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "Marker", valid_613860
  var valid_613861 = formData.getOrDefault("Filters")
  valid_613861 = validateParameter(valid_613861, JArray, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "Filters", valid_613861
  var valid_613862 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "DBClusterParameterGroupName", valid_613862
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613863: Call_PostDescribeDBClusterParameterGroups_613847;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_613863.validator(path, query, header, formData, body)
  let scheme = call_613863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613863.url(scheme.get, call_613863.host, call_613863.base,
                         call_613863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613863, url, valid)

proc call*(call_613864: Call_PostDescribeDBClusterParameterGroups_613847;
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
  var query_613865 = newJObject()
  var formData_613866 = newJObject()
  add(formData_613866, "MaxRecords", newJInt(MaxRecords))
  add(formData_613866, "Marker", newJString(Marker))
  add(query_613865, "Action", newJString(Action))
  if Filters != nil:
    formData_613866.add "Filters", Filters
  add(formData_613866, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_613865, "Version", newJString(Version))
  result = call_613864.call(nil, query_613865, nil, formData_613866, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_613847(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_613848, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_613849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_613828 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBClusterParameterGroups_613830(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBClusterParameterGroups_613829(path: JsonNode;
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
  var valid_613831 = query.getOrDefault("Marker")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "Marker", valid_613831
  var valid_613832 = query.getOrDefault("DBClusterParameterGroupName")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "DBClusterParameterGroupName", valid_613832
  var valid_613833 = query.getOrDefault("Action")
  valid_613833 = validateParameter(valid_613833, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_613833 != nil:
    section.add "Action", valid_613833
  var valid_613834 = query.getOrDefault("Version")
  valid_613834 = validateParameter(valid_613834, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613834 != nil:
    section.add "Version", valid_613834
  var valid_613835 = query.getOrDefault("Filters")
  valid_613835 = validateParameter(valid_613835, JArray, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "Filters", valid_613835
  var valid_613836 = query.getOrDefault("MaxRecords")
  valid_613836 = validateParameter(valid_613836, JInt, required = false, default = nil)
  if valid_613836 != nil:
    section.add "MaxRecords", valid_613836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613837 = header.getOrDefault("X-Amz-Signature")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Signature", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-Content-Sha256", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-Date")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-Date", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-Credential")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Credential", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-Security-Token")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Security-Token", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Algorithm")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Algorithm", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-SignedHeaders", valid_613843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613844: Call_GetDescribeDBClusterParameterGroups_613828;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_613844.validator(path, query, header, formData, body)
  let scheme = call_613844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613844.url(scheme.get, call_613844.host, call_613844.base,
                         call_613844.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613844, url, valid)

proc call*(call_613845: Call_GetDescribeDBClusterParameterGroups_613828;
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
  var query_613846 = newJObject()
  add(query_613846, "Marker", newJString(Marker))
  add(query_613846, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_613846, "Action", newJString(Action))
  add(query_613846, "Version", newJString(Version))
  if Filters != nil:
    query_613846.add "Filters", Filters
  add(query_613846, "MaxRecords", newJInt(MaxRecords))
  result = call_613845.call(nil, query_613846, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_613828(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_613829, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_613830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_613887 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBClusterParameters_613889(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBClusterParameters_613888(path: JsonNode;
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
  var valid_613890 = query.getOrDefault("Action")
  valid_613890 = validateParameter(valid_613890, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_613890 != nil:
    section.add "Action", valid_613890
  var valid_613891 = query.getOrDefault("Version")
  valid_613891 = validateParameter(valid_613891, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613891 != nil:
    section.add "Version", valid_613891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613892 = header.getOrDefault("X-Amz-Signature")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Signature", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Content-Sha256", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Date")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Date", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Credential")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Credential", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Security-Token")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Security-Token", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Algorithm")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Algorithm", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-SignedHeaders", valid_613898
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
  var valid_613899 = formData.getOrDefault("Source")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "Source", valid_613899
  var valid_613900 = formData.getOrDefault("MaxRecords")
  valid_613900 = validateParameter(valid_613900, JInt, required = false, default = nil)
  if valid_613900 != nil:
    section.add "MaxRecords", valid_613900
  var valid_613901 = formData.getOrDefault("Marker")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "Marker", valid_613901
  var valid_613902 = formData.getOrDefault("Filters")
  valid_613902 = validateParameter(valid_613902, JArray, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "Filters", valid_613902
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_613903 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_613903 = validateParameter(valid_613903, JString, required = true,
                                 default = nil)
  if valid_613903 != nil:
    section.add "DBClusterParameterGroupName", valid_613903
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613904: Call_PostDescribeDBClusterParameters_613887;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_613904.validator(path, query, header, formData, body)
  let scheme = call_613904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613904.url(scheme.get, call_613904.host, call_613904.base,
                         call_613904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613904, url, valid)

proc call*(call_613905: Call_PostDescribeDBClusterParameters_613887;
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
  var query_613906 = newJObject()
  var formData_613907 = newJObject()
  add(formData_613907, "Source", newJString(Source))
  add(formData_613907, "MaxRecords", newJInt(MaxRecords))
  add(formData_613907, "Marker", newJString(Marker))
  add(query_613906, "Action", newJString(Action))
  if Filters != nil:
    formData_613907.add "Filters", Filters
  add(formData_613907, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_613906, "Version", newJString(Version))
  result = call_613905.call(nil, query_613906, nil, formData_613907, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_613887(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_613888, base: "/",
    url: url_PostDescribeDBClusterParameters_613889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_613867 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBClusterParameters_613869(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBClusterParameters_613868(path: JsonNode;
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
  var valid_613870 = query.getOrDefault("Marker")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "Marker", valid_613870
  var valid_613871 = query.getOrDefault("Source")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "Source", valid_613871
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_613872 = query.getOrDefault("DBClusterParameterGroupName")
  valid_613872 = validateParameter(valid_613872, JString, required = true,
                                 default = nil)
  if valid_613872 != nil:
    section.add "DBClusterParameterGroupName", valid_613872
  var valid_613873 = query.getOrDefault("Action")
  valid_613873 = validateParameter(valid_613873, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_613873 != nil:
    section.add "Action", valid_613873
  var valid_613874 = query.getOrDefault("Version")
  valid_613874 = validateParameter(valid_613874, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613874 != nil:
    section.add "Version", valid_613874
  var valid_613875 = query.getOrDefault("Filters")
  valid_613875 = validateParameter(valid_613875, JArray, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "Filters", valid_613875
  var valid_613876 = query.getOrDefault("MaxRecords")
  valid_613876 = validateParameter(valid_613876, JInt, required = false, default = nil)
  if valid_613876 != nil:
    section.add "MaxRecords", valid_613876
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613877 = header.getOrDefault("X-Amz-Signature")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Signature", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Content-Sha256", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Date")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Date", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Credential")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Credential", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Security-Token")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Security-Token", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Algorithm")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Algorithm", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-SignedHeaders", valid_613883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613884: Call_GetDescribeDBClusterParameters_613867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_613884.validator(path, query, header, formData, body)
  let scheme = call_613884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613884.url(scheme.get, call_613884.host, call_613884.base,
                         call_613884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613884, url, valid)

proc call*(call_613885: Call_GetDescribeDBClusterParameters_613867;
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
  var query_613886 = newJObject()
  add(query_613886, "Marker", newJString(Marker))
  add(query_613886, "Source", newJString(Source))
  add(query_613886, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_613886, "Action", newJString(Action))
  add(query_613886, "Version", newJString(Version))
  if Filters != nil:
    query_613886.add "Filters", Filters
  add(query_613886, "MaxRecords", newJInt(MaxRecords))
  result = call_613885.call(nil, query_613886, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_613867(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_613868, base: "/",
    url: url_GetDescribeDBClusterParameters_613869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_613924 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBClusterSnapshotAttributes_613926(protocol: Scheme;
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

proc validate_PostDescribeDBClusterSnapshotAttributes_613925(path: JsonNode;
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
  var valid_613927 = query.getOrDefault("Action")
  valid_613927 = validateParameter(valid_613927, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_613927 != nil:
    section.add "Action", valid_613927
  var valid_613928 = query.getOrDefault("Version")
  valid_613928 = validateParameter(valid_613928, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613928 != nil:
    section.add "Version", valid_613928
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613929 = header.getOrDefault("X-Amz-Signature")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Signature", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Content-Sha256", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Date")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Date", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Credential")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Credential", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Security-Token")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Security-Token", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Algorithm")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Algorithm", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-SignedHeaders", valid_613935
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_613936 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_613936 = validateParameter(valid_613936, JString, required = true,
                                 default = nil)
  if valid_613936 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_613936
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613937: Call_PostDescribeDBClusterSnapshotAttributes_613924;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_613937.validator(path, query, header, formData, body)
  let scheme = call_613937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613937.url(scheme.get, call_613937.host, call_613937.base,
                         call_613937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613937, url, valid)

proc call*(call_613938: Call_PostDescribeDBClusterSnapshotAttributes_613924;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613939 = newJObject()
  var formData_613940 = newJObject()
  add(formData_613940, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_613939, "Action", newJString(Action))
  add(query_613939, "Version", newJString(Version))
  result = call_613938.call(nil, query_613939, nil, formData_613940, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_613924(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_613925, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_613926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_613908 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBClusterSnapshotAttributes_613910(protocol: Scheme;
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

proc validate_GetDescribeDBClusterSnapshotAttributes_613909(path: JsonNode;
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
  var valid_613911 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_613911 = validateParameter(valid_613911, JString, required = true,
                                 default = nil)
  if valid_613911 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_613911
  var valid_613912 = query.getOrDefault("Action")
  valid_613912 = validateParameter(valid_613912, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_613912 != nil:
    section.add "Action", valid_613912
  var valid_613913 = query.getOrDefault("Version")
  valid_613913 = validateParameter(valid_613913, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613913 != nil:
    section.add "Version", valid_613913
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613914 = header.getOrDefault("X-Amz-Signature")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Signature", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Content-Sha256", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Date")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Date", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Credential")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Credential", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Security-Token")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Security-Token", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Algorithm")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Algorithm", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-SignedHeaders", valid_613920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613921: Call_GetDescribeDBClusterSnapshotAttributes_613908;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_613921.validator(path, query, header, formData, body)
  let scheme = call_613921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613921.url(scheme.get, call_613921.host, call_613921.base,
                         call_613921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613921, url, valid)

proc call*(call_613922: Call_GetDescribeDBClusterSnapshotAttributes_613908;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613923 = newJObject()
  add(query_613923, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_613923, "Action", newJString(Action))
  add(query_613923, "Version", newJString(Version))
  result = call_613922.call(nil, query_613923, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_613908(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_613909, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_613910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_613964 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBClusterSnapshots_613966(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBClusterSnapshots_613965(path: JsonNode;
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
  var valid_613967 = query.getOrDefault("Action")
  valid_613967 = validateParameter(valid_613967, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_613967 != nil:
    section.add "Action", valid_613967
  var valid_613968 = query.getOrDefault("Version")
  valid_613968 = validateParameter(valid_613968, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613968 != nil:
    section.add "Version", valid_613968
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613969 = header.getOrDefault("X-Amz-Signature")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Signature", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Content-Sha256", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-Date")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-Date", valid_613971
  var valid_613972 = header.getOrDefault("X-Amz-Credential")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "X-Amz-Credential", valid_613972
  var valid_613973 = header.getOrDefault("X-Amz-Security-Token")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-Security-Token", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-Algorithm")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Algorithm", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-SignedHeaders", valid_613975
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
  var valid_613976 = formData.getOrDefault("SnapshotType")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "SnapshotType", valid_613976
  var valid_613977 = formData.getOrDefault("MaxRecords")
  valid_613977 = validateParameter(valid_613977, JInt, required = false, default = nil)
  if valid_613977 != nil:
    section.add "MaxRecords", valid_613977
  var valid_613978 = formData.getOrDefault("IncludePublic")
  valid_613978 = validateParameter(valid_613978, JBool, required = false, default = nil)
  if valid_613978 != nil:
    section.add "IncludePublic", valid_613978
  var valid_613979 = formData.getOrDefault("Marker")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "Marker", valid_613979
  var valid_613980 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_613980
  var valid_613981 = formData.getOrDefault("IncludeShared")
  valid_613981 = validateParameter(valid_613981, JBool, required = false, default = nil)
  if valid_613981 != nil:
    section.add "IncludeShared", valid_613981
  var valid_613982 = formData.getOrDefault("Filters")
  valid_613982 = validateParameter(valid_613982, JArray, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "Filters", valid_613982
  var valid_613983 = formData.getOrDefault("DBClusterIdentifier")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "DBClusterIdentifier", valid_613983
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613984: Call_PostDescribeDBClusterSnapshots_613964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_613984.validator(path, query, header, formData, body)
  let scheme = call_613984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613984.url(scheme.get, call_613984.host, call_613984.base,
                         call_613984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613984, url, valid)

proc call*(call_613985: Call_PostDescribeDBClusterSnapshots_613964;
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
  var query_613986 = newJObject()
  var formData_613987 = newJObject()
  add(formData_613987, "SnapshotType", newJString(SnapshotType))
  add(formData_613987, "MaxRecords", newJInt(MaxRecords))
  add(formData_613987, "IncludePublic", newJBool(IncludePublic))
  add(formData_613987, "Marker", newJString(Marker))
  add(formData_613987, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_613987, "IncludeShared", newJBool(IncludeShared))
  add(query_613986, "Action", newJString(Action))
  if Filters != nil:
    formData_613987.add "Filters", Filters
  add(query_613986, "Version", newJString(Version))
  add(formData_613987, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_613985.call(nil, query_613986, nil, formData_613987, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_613964(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_613965, base: "/",
    url: url_PostDescribeDBClusterSnapshots_613966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_613941 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBClusterSnapshots_613943(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBClusterSnapshots_613942(path: JsonNode; query: JsonNode;
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
  var valid_613944 = query.getOrDefault("Marker")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "Marker", valid_613944
  var valid_613945 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_613945
  var valid_613946 = query.getOrDefault("DBClusterIdentifier")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "DBClusterIdentifier", valid_613946
  var valid_613947 = query.getOrDefault("SnapshotType")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "SnapshotType", valid_613947
  var valid_613948 = query.getOrDefault("IncludePublic")
  valid_613948 = validateParameter(valid_613948, JBool, required = false, default = nil)
  if valid_613948 != nil:
    section.add "IncludePublic", valid_613948
  var valid_613949 = query.getOrDefault("Action")
  valid_613949 = validateParameter(valid_613949, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_613949 != nil:
    section.add "Action", valid_613949
  var valid_613950 = query.getOrDefault("IncludeShared")
  valid_613950 = validateParameter(valid_613950, JBool, required = false, default = nil)
  if valid_613950 != nil:
    section.add "IncludeShared", valid_613950
  var valid_613951 = query.getOrDefault("Version")
  valid_613951 = validateParameter(valid_613951, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613951 != nil:
    section.add "Version", valid_613951
  var valid_613952 = query.getOrDefault("Filters")
  valid_613952 = validateParameter(valid_613952, JArray, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "Filters", valid_613952
  var valid_613953 = query.getOrDefault("MaxRecords")
  valid_613953 = validateParameter(valid_613953, JInt, required = false, default = nil)
  if valid_613953 != nil:
    section.add "MaxRecords", valid_613953
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613954 = header.getOrDefault("X-Amz-Signature")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Signature", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Content-Sha256", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-Date")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-Date", valid_613956
  var valid_613957 = header.getOrDefault("X-Amz-Credential")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Credential", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-Security-Token")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-Security-Token", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Algorithm")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Algorithm", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-SignedHeaders", valid_613960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613961: Call_GetDescribeDBClusterSnapshots_613941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_613961.validator(path, query, header, formData, body)
  let scheme = call_613961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613961.url(scheme.get, call_613961.host, call_613961.base,
                         call_613961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613961, url, valid)

proc call*(call_613962: Call_GetDescribeDBClusterSnapshots_613941;
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
  var query_613963 = newJObject()
  add(query_613963, "Marker", newJString(Marker))
  add(query_613963, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_613963, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_613963, "SnapshotType", newJString(SnapshotType))
  add(query_613963, "IncludePublic", newJBool(IncludePublic))
  add(query_613963, "Action", newJString(Action))
  add(query_613963, "IncludeShared", newJBool(IncludeShared))
  add(query_613963, "Version", newJString(Version))
  if Filters != nil:
    query_613963.add "Filters", Filters
  add(query_613963, "MaxRecords", newJInt(MaxRecords))
  result = call_613962.call(nil, query_613963, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_613941(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_613942, base: "/",
    url: url_GetDescribeDBClusterSnapshots_613943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_614007 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBClusters_614009(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBClusters_614008(path: JsonNode; query: JsonNode;
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
  var valid_614010 = query.getOrDefault("Action")
  valid_614010 = validateParameter(valid_614010, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_614010 != nil:
    section.add "Action", valid_614010
  var valid_614011 = query.getOrDefault("Version")
  valid_614011 = validateParameter(valid_614011, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614011 != nil:
    section.add "Version", valid_614011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614012 = header.getOrDefault("X-Amz-Signature")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-Signature", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Content-Sha256", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Date")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Date", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Credential")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Credential", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-Security-Token")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Security-Token", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-Algorithm")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-Algorithm", valid_614017
  var valid_614018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-SignedHeaders", valid_614018
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
  var valid_614019 = formData.getOrDefault("MaxRecords")
  valid_614019 = validateParameter(valid_614019, JInt, required = false, default = nil)
  if valid_614019 != nil:
    section.add "MaxRecords", valid_614019
  var valid_614020 = formData.getOrDefault("Marker")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "Marker", valid_614020
  var valid_614021 = formData.getOrDefault("Filters")
  valid_614021 = validateParameter(valid_614021, JArray, required = false,
                                 default = nil)
  if valid_614021 != nil:
    section.add "Filters", valid_614021
  var valid_614022 = formData.getOrDefault("DBClusterIdentifier")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "DBClusterIdentifier", valid_614022
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614023: Call_PostDescribeDBClusters_614007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_614023.validator(path, query, header, formData, body)
  let scheme = call_614023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614023.url(scheme.get, call_614023.host, call_614023.base,
                         call_614023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614023, url, valid)

proc call*(call_614024: Call_PostDescribeDBClusters_614007; MaxRecords: int = 0;
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
  var query_614025 = newJObject()
  var formData_614026 = newJObject()
  add(formData_614026, "MaxRecords", newJInt(MaxRecords))
  add(formData_614026, "Marker", newJString(Marker))
  add(query_614025, "Action", newJString(Action))
  if Filters != nil:
    formData_614026.add "Filters", Filters
  add(query_614025, "Version", newJString(Version))
  add(formData_614026, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_614024.call(nil, query_614025, nil, formData_614026, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_614007(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_614008, base: "/",
    url: url_PostDescribeDBClusters_614009, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_613988 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBClusters_613990(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBClusters_613989(path: JsonNode; query: JsonNode;
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
  var valid_613991 = query.getOrDefault("Marker")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "Marker", valid_613991
  var valid_613992 = query.getOrDefault("DBClusterIdentifier")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "DBClusterIdentifier", valid_613992
  var valid_613993 = query.getOrDefault("Action")
  valid_613993 = validateParameter(valid_613993, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_613993 != nil:
    section.add "Action", valid_613993
  var valid_613994 = query.getOrDefault("Version")
  valid_613994 = validateParameter(valid_613994, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_613994 != nil:
    section.add "Version", valid_613994
  var valid_613995 = query.getOrDefault("Filters")
  valid_613995 = validateParameter(valid_613995, JArray, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "Filters", valid_613995
  var valid_613996 = query.getOrDefault("MaxRecords")
  valid_613996 = validateParameter(valid_613996, JInt, required = false, default = nil)
  if valid_613996 != nil:
    section.add "MaxRecords", valid_613996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613997 = header.getOrDefault("X-Amz-Signature")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Signature", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Content-Sha256", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-Date")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-Date", valid_613999
  var valid_614000 = header.getOrDefault("X-Amz-Credential")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-Credential", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-Security-Token")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-Security-Token", valid_614001
  var valid_614002 = header.getOrDefault("X-Amz-Algorithm")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "X-Amz-Algorithm", valid_614002
  var valid_614003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614003 = validateParameter(valid_614003, JString, required = false,
                                 default = nil)
  if valid_614003 != nil:
    section.add "X-Amz-SignedHeaders", valid_614003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614004: Call_GetDescribeDBClusters_613988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_614004.validator(path, query, header, formData, body)
  let scheme = call_614004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614004.url(scheme.get, call_614004.host, call_614004.base,
                         call_614004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614004, url, valid)

proc call*(call_614005: Call_GetDescribeDBClusters_613988; Marker: string = "";
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
  var query_614006 = newJObject()
  add(query_614006, "Marker", newJString(Marker))
  add(query_614006, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_614006, "Action", newJString(Action))
  add(query_614006, "Version", newJString(Version))
  if Filters != nil:
    query_614006.add "Filters", Filters
  add(query_614006, "MaxRecords", newJInt(MaxRecords))
  result = call_614005.call(nil, query_614006, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_613988(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_613989, base: "/",
    url: url_GetDescribeDBClusters_613990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_614051 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBEngineVersions_614053(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_614052(path: JsonNode; query: JsonNode;
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
  var valid_614054 = query.getOrDefault("Action")
  valid_614054 = validateParameter(valid_614054, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_614054 != nil:
    section.add "Action", valid_614054
  var valid_614055 = query.getOrDefault("Version")
  valid_614055 = validateParameter(valid_614055, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614055 != nil:
    section.add "Version", valid_614055
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614056 = header.getOrDefault("X-Amz-Signature")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Signature", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-Content-Sha256", valid_614057
  var valid_614058 = header.getOrDefault("X-Amz-Date")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-Date", valid_614058
  var valid_614059 = header.getOrDefault("X-Amz-Credential")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "X-Amz-Credential", valid_614059
  var valid_614060 = header.getOrDefault("X-Amz-Security-Token")
  valid_614060 = validateParameter(valid_614060, JString, required = false,
                                 default = nil)
  if valid_614060 != nil:
    section.add "X-Amz-Security-Token", valid_614060
  var valid_614061 = header.getOrDefault("X-Amz-Algorithm")
  valid_614061 = validateParameter(valid_614061, JString, required = false,
                                 default = nil)
  if valid_614061 != nil:
    section.add "X-Amz-Algorithm", valid_614061
  var valid_614062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614062 = validateParameter(valid_614062, JString, required = false,
                                 default = nil)
  if valid_614062 != nil:
    section.add "X-Amz-SignedHeaders", valid_614062
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
  var valid_614063 = formData.getOrDefault("DefaultOnly")
  valid_614063 = validateParameter(valid_614063, JBool, required = false, default = nil)
  if valid_614063 != nil:
    section.add "DefaultOnly", valid_614063
  var valid_614064 = formData.getOrDefault("MaxRecords")
  valid_614064 = validateParameter(valid_614064, JInt, required = false, default = nil)
  if valid_614064 != nil:
    section.add "MaxRecords", valid_614064
  var valid_614065 = formData.getOrDefault("EngineVersion")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "EngineVersion", valid_614065
  var valid_614066 = formData.getOrDefault("Marker")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "Marker", valid_614066
  var valid_614067 = formData.getOrDefault("Engine")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "Engine", valid_614067
  var valid_614068 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_614068 = validateParameter(valid_614068, JBool, required = false, default = nil)
  if valid_614068 != nil:
    section.add "ListSupportedCharacterSets", valid_614068
  var valid_614069 = formData.getOrDefault("ListSupportedTimezones")
  valid_614069 = validateParameter(valid_614069, JBool, required = false, default = nil)
  if valid_614069 != nil:
    section.add "ListSupportedTimezones", valid_614069
  var valid_614070 = formData.getOrDefault("Filters")
  valid_614070 = validateParameter(valid_614070, JArray, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "Filters", valid_614070
  var valid_614071 = formData.getOrDefault("DBParameterGroupFamily")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "DBParameterGroupFamily", valid_614071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614072: Call_PostDescribeDBEngineVersions_614051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_614072.validator(path, query, header, formData, body)
  let scheme = call_614072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614072.url(scheme.get, call_614072.host, call_614072.base,
                         call_614072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614072, url, valid)

proc call*(call_614073: Call_PostDescribeDBEngineVersions_614051;
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
  var query_614074 = newJObject()
  var formData_614075 = newJObject()
  add(formData_614075, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_614075, "MaxRecords", newJInt(MaxRecords))
  add(formData_614075, "EngineVersion", newJString(EngineVersion))
  add(formData_614075, "Marker", newJString(Marker))
  add(formData_614075, "Engine", newJString(Engine))
  add(formData_614075, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_614074, "Action", newJString(Action))
  add(formData_614075, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  if Filters != nil:
    formData_614075.add "Filters", Filters
  add(query_614074, "Version", newJString(Version))
  add(formData_614075, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_614073.call(nil, query_614074, nil, formData_614075, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_614051(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_614052, base: "/",
    url: url_PostDescribeDBEngineVersions_614053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_614027 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBEngineVersions_614029(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_614028(path: JsonNode; query: JsonNode;
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
  var valid_614030 = query.getOrDefault("Marker")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "Marker", valid_614030
  var valid_614031 = query.getOrDefault("ListSupportedTimezones")
  valid_614031 = validateParameter(valid_614031, JBool, required = false, default = nil)
  if valid_614031 != nil:
    section.add "ListSupportedTimezones", valid_614031
  var valid_614032 = query.getOrDefault("DBParameterGroupFamily")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "DBParameterGroupFamily", valid_614032
  var valid_614033 = query.getOrDefault("Engine")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "Engine", valid_614033
  var valid_614034 = query.getOrDefault("EngineVersion")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "EngineVersion", valid_614034
  var valid_614035 = query.getOrDefault("Action")
  valid_614035 = validateParameter(valid_614035, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_614035 != nil:
    section.add "Action", valid_614035
  var valid_614036 = query.getOrDefault("ListSupportedCharacterSets")
  valid_614036 = validateParameter(valid_614036, JBool, required = false, default = nil)
  if valid_614036 != nil:
    section.add "ListSupportedCharacterSets", valid_614036
  var valid_614037 = query.getOrDefault("Version")
  valid_614037 = validateParameter(valid_614037, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614037 != nil:
    section.add "Version", valid_614037
  var valid_614038 = query.getOrDefault("Filters")
  valid_614038 = validateParameter(valid_614038, JArray, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "Filters", valid_614038
  var valid_614039 = query.getOrDefault("MaxRecords")
  valid_614039 = validateParameter(valid_614039, JInt, required = false, default = nil)
  if valid_614039 != nil:
    section.add "MaxRecords", valid_614039
  var valid_614040 = query.getOrDefault("DefaultOnly")
  valid_614040 = validateParameter(valid_614040, JBool, required = false, default = nil)
  if valid_614040 != nil:
    section.add "DefaultOnly", valid_614040
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614041 = header.getOrDefault("X-Amz-Signature")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Signature", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Content-Sha256", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Date")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Date", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-Credential")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-Credential", valid_614044
  var valid_614045 = header.getOrDefault("X-Amz-Security-Token")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "X-Amz-Security-Token", valid_614045
  var valid_614046 = header.getOrDefault("X-Amz-Algorithm")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "X-Amz-Algorithm", valid_614046
  var valid_614047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "X-Amz-SignedHeaders", valid_614047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614048: Call_GetDescribeDBEngineVersions_614027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_614048.validator(path, query, header, formData, body)
  let scheme = call_614048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614048.url(scheme.get, call_614048.host, call_614048.base,
                         call_614048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614048, url, valid)

proc call*(call_614049: Call_GetDescribeDBEngineVersions_614027;
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
  var query_614050 = newJObject()
  add(query_614050, "Marker", newJString(Marker))
  add(query_614050, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_614050, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_614050, "Engine", newJString(Engine))
  add(query_614050, "EngineVersion", newJString(EngineVersion))
  add(query_614050, "Action", newJString(Action))
  add(query_614050, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_614050, "Version", newJString(Version))
  if Filters != nil:
    query_614050.add "Filters", Filters
  add(query_614050, "MaxRecords", newJInt(MaxRecords))
  add(query_614050, "DefaultOnly", newJBool(DefaultOnly))
  result = call_614049.call(nil, query_614050, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_614027(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_614028, base: "/",
    url: url_GetDescribeDBEngineVersions_614029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_614095 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBInstances_614097(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_614096(path: JsonNode; query: JsonNode;
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
  var valid_614098 = query.getOrDefault("Action")
  valid_614098 = validateParameter(valid_614098, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_614098 != nil:
    section.add "Action", valid_614098
  var valid_614099 = query.getOrDefault("Version")
  valid_614099 = validateParameter(valid_614099, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614099 != nil:
    section.add "Version", valid_614099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614100 = header.getOrDefault("X-Amz-Signature")
  valid_614100 = validateParameter(valid_614100, JString, required = false,
                                 default = nil)
  if valid_614100 != nil:
    section.add "X-Amz-Signature", valid_614100
  var valid_614101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614101 = validateParameter(valid_614101, JString, required = false,
                                 default = nil)
  if valid_614101 != nil:
    section.add "X-Amz-Content-Sha256", valid_614101
  var valid_614102 = header.getOrDefault("X-Amz-Date")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Date", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-Credential")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Credential", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Security-Token")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Security-Token", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Algorithm")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Algorithm", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-SignedHeaders", valid_614106
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
  var valid_614107 = formData.getOrDefault("MaxRecords")
  valid_614107 = validateParameter(valid_614107, JInt, required = false, default = nil)
  if valid_614107 != nil:
    section.add "MaxRecords", valid_614107
  var valid_614108 = formData.getOrDefault("Marker")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "Marker", valid_614108
  var valid_614109 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "DBInstanceIdentifier", valid_614109
  var valid_614110 = formData.getOrDefault("Filters")
  valid_614110 = validateParameter(valid_614110, JArray, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "Filters", valid_614110
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614111: Call_PostDescribeDBInstances_614095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_614111.validator(path, query, header, formData, body)
  let scheme = call_614111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614111.url(scheme.get, call_614111.host, call_614111.base,
                         call_614111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614111, url, valid)

proc call*(call_614112: Call_PostDescribeDBInstances_614095; MaxRecords: int = 0;
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
  var query_614113 = newJObject()
  var formData_614114 = newJObject()
  add(formData_614114, "MaxRecords", newJInt(MaxRecords))
  add(formData_614114, "Marker", newJString(Marker))
  add(formData_614114, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614113, "Action", newJString(Action))
  if Filters != nil:
    formData_614114.add "Filters", Filters
  add(query_614113, "Version", newJString(Version))
  result = call_614112.call(nil, query_614113, nil, formData_614114, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_614095(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_614096, base: "/",
    url: url_PostDescribeDBInstances_614097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_614076 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBInstances_614078(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_614077(path: JsonNode; query: JsonNode;
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
  var valid_614079 = query.getOrDefault("Marker")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "Marker", valid_614079
  var valid_614080 = query.getOrDefault("DBInstanceIdentifier")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "DBInstanceIdentifier", valid_614080
  var valid_614081 = query.getOrDefault("Action")
  valid_614081 = validateParameter(valid_614081, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_614081 != nil:
    section.add "Action", valid_614081
  var valid_614082 = query.getOrDefault("Version")
  valid_614082 = validateParameter(valid_614082, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614082 != nil:
    section.add "Version", valid_614082
  var valid_614083 = query.getOrDefault("Filters")
  valid_614083 = validateParameter(valid_614083, JArray, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "Filters", valid_614083
  var valid_614084 = query.getOrDefault("MaxRecords")
  valid_614084 = validateParameter(valid_614084, JInt, required = false, default = nil)
  if valid_614084 != nil:
    section.add "MaxRecords", valid_614084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614085 = header.getOrDefault("X-Amz-Signature")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "X-Amz-Signature", valid_614085
  var valid_614086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614086 = validateParameter(valid_614086, JString, required = false,
                                 default = nil)
  if valid_614086 != nil:
    section.add "X-Amz-Content-Sha256", valid_614086
  var valid_614087 = header.getOrDefault("X-Amz-Date")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "X-Amz-Date", valid_614087
  var valid_614088 = header.getOrDefault("X-Amz-Credential")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Credential", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Security-Token")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Security-Token", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Algorithm")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Algorithm", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-SignedHeaders", valid_614091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614092: Call_GetDescribeDBInstances_614076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_614092.validator(path, query, header, formData, body)
  let scheme = call_614092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614092.url(scheme.get, call_614092.host, call_614092.base,
                         call_614092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614092, url, valid)

proc call*(call_614093: Call_GetDescribeDBInstances_614076; Marker: string = "";
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
  var query_614094 = newJObject()
  add(query_614094, "Marker", newJString(Marker))
  add(query_614094, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614094, "Action", newJString(Action))
  add(query_614094, "Version", newJString(Version))
  if Filters != nil:
    query_614094.add "Filters", Filters
  add(query_614094, "MaxRecords", newJInt(MaxRecords))
  result = call_614093.call(nil, query_614094, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_614076(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_614077, base: "/",
    url: url_GetDescribeDBInstances_614078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_614134 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSubnetGroups_614136(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_614135(path: JsonNode; query: JsonNode;
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
  var valid_614137 = query.getOrDefault("Action")
  valid_614137 = validateParameter(valid_614137, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_614137 != nil:
    section.add "Action", valid_614137
  var valid_614138 = query.getOrDefault("Version")
  valid_614138 = validateParameter(valid_614138, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614138 != nil:
    section.add "Version", valid_614138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614139 = header.getOrDefault("X-Amz-Signature")
  valid_614139 = validateParameter(valid_614139, JString, required = false,
                                 default = nil)
  if valid_614139 != nil:
    section.add "X-Amz-Signature", valid_614139
  var valid_614140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614140 = validateParameter(valid_614140, JString, required = false,
                                 default = nil)
  if valid_614140 != nil:
    section.add "X-Amz-Content-Sha256", valid_614140
  var valid_614141 = header.getOrDefault("X-Amz-Date")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Date", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Credential")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Credential", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Security-Token")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Security-Token", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Algorithm")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Algorithm", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-SignedHeaders", valid_614145
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
  var valid_614146 = formData.getOrDefault("MaxRecords")
  valid_614146 = validateParameter(valid_614146, JInt, required = false, default = nil)
  if valid_614146 != nil:
    section.add "MaxRecords", valid_614146
  var valid_614147 = formData.getOrDefault("Marker")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "Marker", valid_614147
  var valid_614148 = formData.getOrDefault("DBSubnetGroupName")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "DBSubnetGroupName", valid_614148
  var valid_614149 = formData.getOrDefault("Filters")
  valid_614149 = validateParameter(valid_614149, JArray, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "Filters", valid_614149
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614150: Call_PostDescribeDBSubnetGroups_614134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_614150.validator(path, query, header, formData, body)
  let scheme = call_614150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614150.url(scheme.get, call_614150.host, call_614150.base,
                         call_614150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614150, url, valid)

proc call*(call_614151: Call_PostDescribeDBSubnetGroups_614134;
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
  var query_614152 = newJObject()
  var formData_614153 = newJObject()
  add(formData_614153, "MaxRecords", newJInt(MaxRecords))
  add(formData_614153, "Marker", newJString(Marker))
  add(query_614152, "Action", newJString(Action))
  add(formData_614153, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_614153.add "Filters", Filters
  add(query_614152, "Version", newJString(Version))
  result = call_614151.call(nil, query_614152, nil, formData_614153, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_614134(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_614135, base: "/",
    url: url_PostDescribeDBSubnetGroups_614136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_614115 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSubnetGroups_614117(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_614116(path: JsonNode; query: JsonNode;
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
  var valid_614118 = query.getOrDefault("Marker")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "Marker", valid_614118
  var valid_614119 = query.getOrDefault("Action")
  valid_614119 = validateParameter(valid_614119, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_614119 != nil:
    section.add "Action", valid_614119
  var valid_614120 = query.getOrDefault("DBSubnetGroupName")
  valid_614120 = validateParameter(valid_614120, JString, required = false,
                                 default = nil)
  if valid_614120 != nil:
    section.add "DBSubnetGroupName", valid_614120
  var valid_614121 = query.getOrDefault("Version")
  valid_614121 = validateParameter(valid_614121, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614121 != nil:
    section.add "Version", valid_614121
  var valid_614122 = query.getOrDefault("Filters")
  valid_614122 = validateParameter(valid_614122, JArray, required = false,
                                 default = nil)
  if valid_614122 != nil:
    section.add "Filters", valid_614122
  var valid_614123 = query.getOrDefault("MaxRecords")
  valid_614123 = validateParameter(valid_614123, JInt, required = false, default = nil)
  if valid_614123 != nil:
    section.add "MaxRecords", valid_614123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614124 = header.getOrDefault("X-Amz-Signature")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "X-Amz-Signature", valid_614124
  var valid_614125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "X-Amz-Content-Sha256", valid_614125
  var valid_614126 = header.getOrDefault("X-Amz-Date")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "X-Amz-Date", valid_614126
  var valid_614127 = header.getOrDefault("X-Amz-Credential")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "X-Amz-Credential", valid_614127
  var valid_614128 = header.getOrDefault("X-Amz-Security-Token")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Security-Token", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Algorithm")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Algorithm", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-SignedHeaders", valid_614130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614131: Call_GetDescribeDBSubnetGroups_614115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_614131.validator(path, query, header, formData, body)
  let scheme = call_614131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614131.url(scheme.get, call_614131.host, call_614131.base,
                         call_614131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614131, url, valid)

proc call*(call_614132: Call_GetDescribeDBSubnetGroups_614115; Marker: string = "";
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
  var query_614133 = newJObject()
  add(query_614133, "Marker", newJString(Marker))
  add(query_614133, "Action", newJString(Action))
  add(query_614133, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614133, "Version", newJString(Version))
  if Filters != nil:
    query_614133.add "Filters", Filters
  add(query_614133, "MaxRecords", newJInt(MaxRecords))
  result = call_614132.call(nil, query_614133, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_614115(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_614116, base: "/",
    url: url_GetDescribeDBSubnetGroups_614117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_614173 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEngineDefaultClusterParameters_614175(protocol: Scheme;
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

proc validate_PostDescribeEngineDefaultClusterParameters_614174(path: JsonNode;
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
  var valid_614176 = query.getOrDefault("Action")
  valid_614176 = validateParameter(valid_614176, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_614176 != nil:
    section.add "Action", valid_614176
  var valid_614177 = query.getOrDefault("Version")
  valid_614177 = validateParameter(valid_614177, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614177 != nil:
    section.add "Version", valid_614177
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614178 = header.getOrDefault("X-Amz-Signature")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Signature", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Content-Sha256", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Date")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Date", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Credential")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Credential", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Security-Token")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Security-Token", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Algorithm")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Algorithm", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-SignedHeaders", valid_614184
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
  var valid_614185 = formData.getOrDefault("MaxRecords")
  valid_614185 = validateParameter(valid_614185, JInt, required = false, default = nil)
  if valid_614185 != nil:
    section.add "MaxRecords", valid_614185
  var valid_614186 = formData.getOrDefault("Marker")
  valid_614186 = validateParameter(valid_614186, JString, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "Marker", valid_614186
  var valid_614187 = formData.getOrDefault("Filters")
  valid_614187 = validateParameter(valid_614187, JArray, required = false,
                                 default = nil)
  if valid_614187 != nil:
    section.add "Filters", valid_614187
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_614188 = formData.getOrDefault("DBParameterGroupFamily")
  valid_614188 = validateParameter(valid_614188, JString, required = true,
                                 default = nil)
  if valid_614188 != nil:
    section.add "DBParameterGroupFamily", valid_614188
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614189: Call_PostDescribeEngineDefaultClusterParameters_614173;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_614189.validator(path, query, header, formData, body)
  let scheme = call_614189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614189.url(scheme.get, call_614189.host, call_614189.base,
                         call_614189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614189, url, valid)

proc call*(call_614190: Call_PostDescribeEngineDefaultClusterParameters_614173;
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
  var query_614191 = newJObject()
  var formData_614192 = newJObject()
  add(formData_614192, "MaxRecords", newJInt(MaxRecords))
  add(formData_614192, "Marker", newJString(Marker))
  add(query_614191, "Action", newJString(Action))
  if Filters != nil:
    formData_614192.add "Filters", Filters
  add(query_614191, "Version", newJString(Version))
  add(formData_614192, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_614190.call(nil, query_614191, nil, formData_614192, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_614173(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_614174,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_614175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_614154 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEngineDefaultClusterParameters_614156(protocol: Scheme;
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

proc validate_GetDescribeEngineDefaultClusterParameters_614155(path: JsonNode;
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
  var valid_614157 = query.getOrDefault("Marker")
  valid_614157 = validateParameter(valid_614157, JString, required = false,
                                 default = nil)
  if valid_614157 != nil:
    section.add "Marker", valid_614157
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_614158 = query.getOrDefault("DBParameterGroupFamily")
  valid_614158 = validateParameter(valid_614158, JString, required = true,
                                 default = nil)
  if valid_614158 != nil:
    section.add "DBParameterGroupFamily", valid_614158
  var valid_614159 = query.getOrDefault("Action")
  valid_614159 = validateParameter(valid_614159, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_614159 != nil:
    section.add "Action", valid_614159
  var valid_614160 = query.getOrDefault("Version")
  valid_614160 = validateParameter(valid_614160, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614160 != nil:
    section.add "Version", valid_614160
  var valid_614161 = query.getOrDefault("Filters")
  valid_614161 = validateParameter(valid_614161, JArray, required = false,
                                 default = nil)
  if valid_614161 != nil:
    section.add "Filters", valid_614161
  var valid_614162 = query.getOrDefault("MaxRecords")
  valid_614162 = validateParameter(valid_614162, JInt, required = false, default = nil)
  if valid_614162 != nil:
    section.add "MaxRecords", valid_614162
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614163 = header.getOrDefault("X-Amz-Signature")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Signature", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Content-Sha256", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Date")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Date", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Credential")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Credential", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Security-Token")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Security-Token", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-Algorithm")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-Algorithm", valid_614168
  var valid_614169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "X-Amz-SignedHeaders", valid_614169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614170: Call_GetDescribeEngineDefaultClusterParameters_614154;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_614170.validator(path, query, header, formData, body)
  let scheme = call_614170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614170.url(scheme.get, call_614170.host, call_614170.base,
                         call_614170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614170, url, valid)

proc call*(call_614171: Call_GetDescribeEngineDefaultClusterParameters_614154;
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
  var query_614172 = newJObject()
  add(query_614172, "Marker", newJString(Marker))
  add(query_614172, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_614172, "Action", newJString(Action))
  add(query_614172, "Version", newJString(Version))
  if Filters != nil:
    query_614172.add "Filters", Filters
  add(query_614172, "MaxRecords", newJInt(MaxRecords))
  result = call_614171.call(nil, query_614172, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_614154(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_614155,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_614156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_614210 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEventCategories_614212(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_614211(path: JsonNode; query: JsonNode;
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
  var valid_614213 = query.getOrDefault("Action")
  valid_614213 = validateParameter(valid_614213, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_614213 != nil:
    section.add "Action", valid_614213
  var valid_614214 = query.getOrDefault("Version")
  valid_614214 = validateParameter(valid_614214, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614214 != nil:
    section.add "Version", valid_614214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614215 = header.getOrDefault("X-Amz-Signature")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-Signature", valid_614215
  var valid_614216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-Content-Sha256", valid_614216
  var valid_614217 = header.getOrDefault("X-Amz-Date")
  valid_614217 = validateParameter(valid_614217, JString, required = false,
                                 default = nil)
  if valid_614217 != nil:
    section.add "X-Amz-Date", valid_614217
  var valid_614218 = header.getOrDefault("X-Amz-Credential")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "X-Amz-Credential", valid_614218
  var valid_614219 = header.getOrDefault("X-Amz-Security-Token")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "X-Amz-Security-Token", valid_614219
  var valid_614220 = header.getOrDefault("X-Amz-Algorithm")
  valid_614220 = validateParameter(valid_614220, JString, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "X-Amz-Algorithm", valid_614220
  var valid_614221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "X-Amz-SignedHeaders", valid_614221
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_614222 = formData.getOrDefault("SourceType")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "SourceType", valid_614222
  var valid_614223 = formData.getOrDefault("Filters")
  valid_614223 = validateParameter(valid_614223, JArray, required = false,
                                 default = nil)
  if valid_614223 != nil:
    section.add "Filters", valid_614223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614224: Call_PostDescribeEventCategories_614210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_614224.validator(path, query, header, formData, body)
  let scheme = call_614224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614224.url(scheme.get, call_614224.host, call_614224.base,
                         call_614224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614224, url, valid)

proc call*(call_614225: Call_PostDescribeEventCategories_614210;
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
  var query_614226 = newJObject()
  var formData_614227 = newJObject()
  add(formData_614227, "SourceType", newJString(SourceType))
  add(query_614226, "Action", newJString(Action))
  if Filters != nil:
    formData_614227.add "Filters", Filters
  add(query_614226, "Version", newJString(Version))
  result = call_614225.call(nil, query_614226, nil, formData_614227, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_614210(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_614211, base: "/",
    url: url_PostDescribeEventCategories_614212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_614193 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEventCategories_614195(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_614194(path: JsonNode; query: JsonNode;
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
  var valid_614196 = query.getOrDefault("SourceType")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "SourceType", valid_614196
  var valid_614197 = query.getOrDefault("Action")
  valid_614197 = validateParameter(valid_614197, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_614197 != nil:
    section.add "Action", valid_614197
  var valid_614198 = query.getOrDefault("Version")
  valid_614198 = validateParameter(valid_614198, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614198 != nil:
    section.add "Version", valid_614198
  var valid_614199 = query.getOrDefault("Filters")
  valid_614199 = validateParameter(valid_614199, JArray, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "Filters", valid_614199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614200 = header.getOrDefault("X-Amz-Signature")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-Signature", valid_614200
  var valid_614201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "X-Amz-Content-Sha256", valid_614201
  var valid_614202 = header.getOrDefault("X-Amz-Date")
  valid_614202 = validateParameter(valid_614202, JString, required = false,
                                 default = nil)
  if valid_614202 != nil:
    section.add "X-Amz-Date", valid_614202
  var valid_614203 = header.getOrDefault("X-Amz-Credential")
  valid_614203 = validateParameter(valid_614203, JString, required = false,
                                 default = nil)
  if valid_614203 != nil:
    section.add "X-Amz-Credential", valid_614203
  var valid_614204 = header.getOrDefault("X-Amz-Security-Token")
  valid_614204 = validateParameter(valid_614204, JString, required = false,
                                 default = nil)
  if valid_614204 != nil:
    section.add "X-Amz-Security-Token", valid_614204
  var valid_614205 = header.getOrDefault("X-Amz-Algorithm")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "X-Amz-Algorithm", valid_614205
  var valid_614206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614206 = validateParameter(valid_614206, JString, required = false,
                                 default = nil)
  if valid_614206 != nil:
    section.add "X-Amz-SignedHeaders", valid_614206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614207: Call_GetDescribeEventCategories_614193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_614207.validator(path, query, header, formData, body)
  let scheme = call_614207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614207.url(scheme.get, call_614207.host, call_614207.base,
                         call_614207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614207, url, valid)

proc call*(call_614208: Call_GetDescribeEventCategories_614193;
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
  var query_614209 = newJObject()
  add(query_614209, "SourceType", newJString(SourceType))
  add(query_614209, "Action", newJString(Action))
  add(query_614209, "Version", newJString(Version))
  if Filters != nil:
    query_614209.add "Filters", Filters
  result = call_614208.call(nil, query_614209, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_614193(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_614194, base: "/",
    url: url_GetDescribeEventCategories_614195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_614252 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEvents_614254(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_614253(path: JsonNode; query: JsonNode;
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
  var valid_614255 = query.getOrDefault("Action")
  valid_614255 = validateParameter(valid_614255, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614255 != nil:
    section.add "Action", valid_614255
  var valid_614256 = query.getOrDefault("Version")
  valid_614256 = validateParameter(valid_614256, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614256 != nil:
    section.add "Version", valid_614256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614257 = header.getOrDefault("X-Amz-Signature")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-Signature", valid_614257
  var valid_614258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614258 = validateParameter(valid_614258, JString, required = false,
                                 default = nil)
  if valid_614258 != nil:
    section.add "X-Amz-Content-Sha256", valid_614258
  var valid_614259 = header.getOrDefault("X-Amz-Date")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "X-Amz-Date", valid_614259
  var valid_614260 = header.getOrDefault("X-Amz-Credential")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-Credential", valid_614260
  var valid_614261 = header.getOrDefault("X-Amz-Security-Token")
  valid_614261 = validateParameter(valid_614261, JString, required = false,
                                 default = nil)
  if valid_614261 != nil:
    section.add "X-Amz-Security-Token", valid_614261
  var valid_614262 = header.getOrDefault("X-Amz-Algorithm")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "X-Amz-Algorithm", valid_614262
  var valid_614263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614263 = validateParameter(valid_614263, JString, required = false,
                                 default = nil)
  if valid_614263 != nil:
    section.add "X-Amz-SignedHeaders", valid_614263
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
  var valid_614264 = formData.getOrDefault("MaxRecords")
  valid_614264 = validateParameter(valid_614264, JInt, required = false, default = nil)
  if valid_614264 != nil:
    section.add "MaxRecords", valid_614264
  var valid_614265 = formData.getOrDefault("Marker")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "Marker", valid_614265
  var valid_614266 = formData.getOrDefault("SourceIdentifier")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "SourceIdentifier", valid_614266
  var valid_614267 = formData.getOrDefault("SourceType")
  valid_614267 = validateParameter(valid_614267, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_614267 != nil:
    section.add "SourceType", valid_614267
  var valid_614268 = formData.getOrDefault("Duration")
  valid_614268 = validateParameter(valid_614268, JInt, required = false, default = nil)
  if valid_614268 != nil:
    section.add "Duration", valid_614268
  var valid_614269 = formData.getOrDefault("EndTime")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "EndTime", valid_614269
  var valid_614270 = formData.getOrDefault("StartTime")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "StartTime", valid_614270
  var valid_614271 = formData.getOrDefault("EventCategories")
  valid_614271 = validateParameter(valid_614271, JArray, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "EventCategories", valid_614271
  var valid_614272 = formData.getOrDefault("Filters")
  valid_614272 = validateParameter(valid_614272, JArray, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "Filters", valid_614272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614273: Call_PostDescribeEvents_614252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_614273.validator(path, query, header, formData, body)
  let scheme = call_614273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614273.url(scheme.get, call_614273.host, call_614273.base,
                         call_614273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614273, url, valid)

proc call*(call_614274: Call_PostDescribeEvents_614252; MaxRecords: int = 0;
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
  var query_614275 = newJObject()
  var formData_614276 = newJObject()
  add(formData_614276, "MaxRecords", newJInt(MaxRecords))
  add(formData_614276, "Marker", newJString(Marker))
  add(formData_614276, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_614276, "SourceType", newJString(SourceType))
  add(formData_614276, "Duration", newJInt(Duration))
  add(formData_614276, "EndTime", newJString(EndTime))
  add(formData_614276, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_614276.add "EventCategories", EventCategories
  add(query_614275, "Action", newJString(Action))
  if Filters != nil:
    formData_614276.add "Filters", Filters
  add(query_614275, "Version", newJString(Version))
  result = call_614274.call(nil, query_614275, nil, formData_614276, nil)

var postDescribeEvents* = Call_PostDescribeEvents_614252(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_614253, base: "/",
    url: url_PostDescribeEvents_614254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_614228 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEvents_614230(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_614229(path: JsonNode; query: JsonNode;
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
  var valid_614231 = query.getOrDefault("Marker")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "Marker", valid_614231
  var valid_614232 = query.getOrDefault("SourceType")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_614232 != nil:
    section.add "SourceType", valid_614232
  var valid_614233 = query.getOrDefault("SourceIdentifier")
  valid_614233 = validateParameter(valid_614233, JString, required = false,
                                 default = nil)
  if valid_614233 != nil:
    section.add "SourceIdentifier", valid_614233
  var valid_614234 = query.getOrDefault("EventCategories")
  valid_614234 = validateParameter(valid_614234, JArray, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "EventCategories", valid_614234
  var valid_614235 = query.getOrDefault("Action")
  valid_614235 = validateParameter(valid_614235, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614235 != nil:
    section.add "Action", valid_614235
  var valid_614236 = query.getOrDefault("StartTime")
  valid_614236 = validateParameter(valid_614236, JString, required = false,
                                 default = nil)
  if valid_614236 != nil:
    section.add "StartTime", valid_614236
  var valid_614237 = query.getOrDefault("Duration")
  valid_614237 = validateParameter(valid_614237, JInt, required = false, default = nil)
  if valid_614237 != nil:
    section.add "Duration", valid_614237
  var valid_614238 = query.getOrDefault("EndTime")
  valid_614238 = validateParameter(valid_614238, JString, required = false,
                                 default = nil)
  if valid_614238 != nil:
    section.add "EndTime", valid_614238
  var valid_614239 = query.getOrDefault("Version")
  valid_614239 = validateParameter(valid_614239, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614239 != nil:
    section.add "Version", valid_614239
  var valid_614240 = query.getOrDefault("Filters")
  valid_614240 = validateParameter(valid_614240, JArray, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "Filters", valid_614240
  var valid_614241 = query.getOrDefault("MaxRecords")
  valid_614241 = validateParameter(valid_614241, JInt, required = false, default = nil)
  if valid_614241 != nil:
    section.add "MaxRecords", valid_614241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614242 = header.getOrDefault("X-Amz-Signature")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "X-Amz-Signature", valid_614242
  var valid_614243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "X-Amz-Content-Sha256", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-Date")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Date", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-Credential")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-Credential", valid_614245
  var valid_614246 = header.getOrDefault("X-Amz-Security-Token")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "X-Amz-Security-Token", valid_614246
  var valid_614247 = header.getOrDefault("X-Amz-Algorithm")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "X-Amz-Algorithm", valid_614247
  var valid_614248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614248 = validateParameter(valid_614248, JString, required = false,
                                 default = nil)
  if valid_614248 != nil:
    section.add "X-Amz-SignedHeaders", valid_614248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614249: Call_GetDescribeEvents_614228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_614249.validator(path, query, header, formData, body)
  let scheme = call_614249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614249.url(scheme.get, call_614249.host, call_614249.base,
                         call_614249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614249, url, valid)

proc call*(call_614250: Call_GetDescribeEvents_614228; Marker: string = "";
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
  var query_614251 = newJObject()
  add(query_614251, "Marker", newJString(Marker))
  add(query_614251, "SourceType", newJString(SourceType))
  add(query_614251, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_614251.add "EventCategories", EventCategories
  add(query_614251, "Action", newJString(Action))
  add(query_614251, "StartTime", newJString(StartTime))
  add(query_614251, "Duration", newJInt(Duration))
  add(query_614251, "EndTime", newJString(EndTime))
  add(query_614251, "Version", newJString(Version))
  if Filters != nil:
    query_614251.add "Filters", Filters
  add(query_614251, "MaxRecords", newJInt(MaxRecords))
  result = call_614250.call(nil, query_614251, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_614228(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_614229,
    base: "/", url: url_GetDescribeEvents_614230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_614300 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOrderableDBInstanceOptions_614302(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_614301(path: JsonNode;
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
  var valid_614303 = query.getOrDefault("Action")
  valid_614303 = validateParameter(valid_614303, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_614303 != nil:
    section.add "Action", valid_614303
  var valid_614304 = query.getOrDefault("Version")
  valid_614304 = validateParameter(valid_614304, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614304 != nil:
    section.add "Version", valid_614304
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614305 = header.getOrDefault("X-Amz-Signature")
  valid_614305 = validateParameter(valid_614305, JString, required = false,
                                 default = nil)
  if valid_614305 != nil:
    section.add "X-Amz-Signature", valid_614305
  var valid_614306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614306 = validateParameter(valid_614306, JString, required = false,
                                 default = nil)
  if valid_614306 != nil:
    section.add "X-Amz-Content-Sha256", valid_614306
  var valid_614307 = header.getOrDefault("X-Amz-Date")
  valid_614307 = validateParameter(valid_614307, JString, required = false,
                                 default = nil)
  if valid_614307 != nil:
    section.add "X-Amz-Date", valid_614307
  var valid_614308 = header.getOrDefault("X-Amz-Credential")
  valid_614308 = validateParameter(valid_614308, JString, required = false,
                                 default = nil)
  if valid_614308 != nil:
    section.add "X-Amz-Credential", valid_614308
  var valid_614309 = header.getOrDefault("X-Amz-Security-Token")
  valid_614309 = validateParameter(valid_614309, JString, required = false,
                                 default = nil)
  if valid_614309 != nil:
    section.add "X-Amz-Security-Token", valid_614309
  var valid_614310 = header.getOrDefault("X-Amz-Algorithm")
  valid_614310 = validateParameter(valid_614310, JString, required = false,
                                 default = nil)
  if valid_614310 != nil:
    section.add "X-Amz-Algorithm", valid_614310
  var valid_614311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614311 = validateParameter(valid_614311, JString, required = false,
                                 default = nil)
  if valid_614311 != nil:
    section.add "X-Amz-SignedHeaders", valid_614311
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
  var valid_614312 = formData.getOrDefault("DBInstanceClass")
  valid_614312 = validateParameter(valid_614312, JString, required = false,
                                 default = nil)
  if valid_614312 != nil:
    section.add "DBInstanceClass", valid_614312
  var valid_614313 = formData.getOrDefault("MaxRecords")
  valid_614313 = validateParameter(valid_614313, JInt, required = false, default = nil)
  if valid_614313 != nil:
    section.add "MaxRecords", valid_614313
  var valid_614314 = formData.getOrDefault("EngineVersion")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "EngineVersion", valid_614314
  var valid_614315 = formData.getOrDefault("Marker")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "Marker", valid_614315
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_614316 = formData.getOrDefault("Engine")
  valid_614316 = validateParameter(valid_614316, JString, required = true,
                                 default = nil)
  if valid_614316 != nil:
    section.add "Engine", valid_614316
  var valid_614317 = formData.getOrDefault("Vpc")
  valid_614317 = validateParameter(valid_614317, JBool, required = false, default = nil)
  if valid_614317 != nil:
    section.add "Vpc", valid_614317
  var valid_614318 = formData.getOrDefault("LicenseModel")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "LicenseModel", valid_614318
  var valid_614319 = formData.getOrDefault("Filters")
  valid_614319 = validateParameter(valid_614319, JArray, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "Filters", valid_614319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614320: Call_PostDescribeOrderableDBInstanceOptions_614300;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_614320.validator(path, query, header, formData, body)
  let scheme = call_614320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614320.url(scheme.get, call_614320.host, call_614320.base,
                         call_614320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614320, url, valid)

proc call*(call_614321: Call_PostDescribeOrderableDBInstanceOptions_614300;
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
  var query_614322 = newJObject()
  var formData_614323 = newJObject()
  add(formData_614323, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614323, "MaxRecords", newJInt(MaxRecords))
  add(formData_614323, "EngineVersion", newJString(EngineVersion))
  add(formData_614323, "Marker", newJString(Marker))
  add(formData_614323, "Engine", newJString(Engine))
  add(formData_614323, "Vpc", newJBool(Vpc))
  add(query_614322, "Action", newJString(Action))
  add(formData_614323, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_614323.add "Filters", Filters
  add(query_614322, "Version", newJString(Version))
  result = call_614321.call(nil, query_614322, nil, formData_614323, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_614300(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_614301, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_614302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_614277 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOrderableDBInstanceOptions_614279(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_614278(path: JsonNode;
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
  var valid_614280 = query.getOrDefault("Marker")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "Marker", valid_614280
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_614281 = query.getOrDefault("Engine")
  valid_614281 = validateParameter(valid_614281, JString, required = true,
                                 default = nil)
  if valid_614281 != nil:
    section.add "Engine", valid_614281
  var valid_614282 = query.getOrDefault("LicenseModel")
  valid_614282 = validateParameter(valid_614282, JString, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "LicenseModel", valid_614282
  var valid_614283 = query.getOrDefault("Vpc")
  valid_614283 = validateParameter(valid_614283, JBool, required = false, default = nil)
  if valid_614283 != nil:
    section.add "Vpc", valid_614283
  var valid_614284 = query.getOrDefault("EngineVersion")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "EngineVersion", valid_614284
  var valid_614285 = query.getOrDefault("Action")
  valid_614285 = validateParameter(valid_614285, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_614285 != nil:
    section.add "Action", valid_614285
  var valid_614286 = query.getOrDefault("Version")
  valid_614286 = validateParameter(valid_614286, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614286 != nil:
    section.add "Version", valid_614286
  var valid_614287 = query.getOrDefault("DBInstanceClass")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "DBInstanceClass", valid_614287
  var valid_614288 = query.getOrDefault("Filters")
  valid_614288 = validateParameter(valid_614288, JArray, required = false,
                                 default = nil)
  if valid_614288 != nil:
    section.add "Filters", valid_614288
  var valid_614289 = query.getOrDefault("MaxRecords")
  valid_614289 = validateParameter(valid_614289, JInt, required = false, default = nil)
  if valid_614289 != nil:
    section.add "MaxRecords", valid_614289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614290 = header.getOrDefault("X-Amz-Signature")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "X-Amz-Signature", valid_614290
  var valid_614291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614291 = validateParameter(valid_614291, JString, required = false,
                                 default = nil)
  if valid_614291 != nil:
    section.add "X-Amz-Content-Sha256", valid_614291
  var valid_614292 = header.getOrDefault("X-Amz-Date")
  valid_614292 = validateParameter(valid_614292, JString, required = false,
                                 default = nil)
  if valid_614292 != nil:
    section.add "X-Amz-Date", valid_614292
  var valid_614293 = header.getOrDefault("X-Amz-Credential")
  valid_614293 = validateParameter(valid_614293, JString, required = false,
                                 default = nil)
  if valid_614293 != nil:
    section.add "X-Amz-Credential", valid_614293
  var valid_614294 = header.getOrDefault("X-Amz-Security-Token")
  valid_614294 = validateParameter(valid_614294, JString, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "X-Amz-Security-Token", valid_614294
  var valid_614295 = header.getOrDefault("X-Amz-Algorithm")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "X-Amz-Algorithm", valid_614295
  var valid_614296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614296 = validateParameter(valid_614296, JString, required = false,
                                 default = nil)
  if valid_614296 != nil:
    section.add "X-Amz-SignedHeaders", valid_614296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614297: Call_GetDescribeOrderableDBInstanceOptions_614277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_614297.validator(path, query, header, formData, body)
  let scheme = call_614297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614297.url(scheme.get, call_614297.host, call_614297.base,
                         call_614297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614297, url, valid)

proc call*(call_614298: Call_GetDescribeOrderableDBInstanceOptions_614277;
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
  var query_614299 = newJObject()
  add(query_614299, "Marker", newJString(Marker))
  add(query_614299, "Engine", newJString(Engine))
  add(query_614299, "LicenseModel", newJString(LicenseModel))
  add(query_614299, "Vpc", newJBool(Vpc))
  add(query_614299, "EngineVersion", newJString(EngineVersion))
  add(query_614299, "Action", newJString(Action))
  add(query_614299, "Version", newJString(Version))
  add(query_614299, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_614299.add "Filters", Filters
  add(query_614299, "MaxRecords", newJInt(MaxRecords))
  result = call_614298.call(nil, query_614299, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_614277(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_614278, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_614279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_614343 = ref object of OpenApiRestCall_612642
proc url_PostDescribePendingMaintenanceActions_614345(protocol: Scheme;
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

proc validate_PostDescribePendingMaintenanceActions_614344(path: JsonNode;
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
  var valid_614346 = query.getOrDefault("Action")
  valid_614346 = validateParameter(valid_614346, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_614346 != nil:
    section.add "Action", valid_614346
  var valid_614347 = query.getOrDefault("Version")
  valid_614347 = validateParameter(valid_614347, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614347 != nil:
    section.add "Version", valid_614347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614348 = header.getOrDefault("X-Amz-Signature")
  valid_614348 = validateParameter(valid_614348, JString, required = false,
                                 default = nil)
  if valid_614348 != nil:
    section.add "X-Amz-Signature", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Content-Sha256", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-Date")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Date", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Credential")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Credential", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-Security-Token")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-Security-Token", valid_614352
  var valid_614353 = header.getOrDefault("X-Amz-Algorithm")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "X-Amz-Algorithm", valid_614353
  var valid_614354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "X-Amz-SignedHeaders", valid_614354
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
  var valid_614355 = formData.getOrDefault("MaxRecords")
  valid_614355 = validateParameter(valid_614355, JInt, required = false, default = nil)
  if valid_614355 != nil:
    section.add "MaxRecords", valid_614355
  var valid_614356 = formData.getOrDefault("Marker")
  valid_614356 = validateParameter(valid_614356, JString, required = false,
                                 default = nil)
  if valid_614356 != nil:
    section.add "Marker", valid_614356
  var valid_614357 = formData.getOrDefault("ResourceIdentifier")
  valid_614357 = validateParameter(valid_614357, JString, required = false,
                                 default = nil)
  if valid_614357 != nil:
    section.add "ResourceIdentifier", valid_614357
  var valid_614358 = formData.getOrDefault("Filters")
  valid_614358 = validateParameter(valid_614358, JArray, required = false,
                                 default = nil)
  if valid_614358 != nil:
    section.add "Filters", valid_614358
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614359: Call_PostDescribePendingMaintenanceActions_614343;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_614359.validator(path, query, header, formData, body)
  let scheme = call_614359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614359.url(scheme.get, call_614359.host, call_614359.base,
                         call_614359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614359, url, valid)

proc call*(call_614360: Call_PostDescribePendingMaintenanceActions_614343;
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
  var query_614361 = newJObject()
  var formData_614362 = newJObject()
  add(formData_614362, "MaxRecords", newJInt(MaxRecords))
  add(formData_614362, "Marker", newJString(Marker))
  add(formData_614362, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_614361, "Action", newJString(Action))
  if Filters != nil:
    formData_614362.add "Filters", Filters
  add(query_614361, "Version", newJString(Version))
  result = call_614360.call(nil, query_614361, nil, formData_614362, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_614343(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_614344, base: "/",
    url: url_PostDescribePendingMaintenanceActions_614345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_614324 = ref object of OpenApiRestCall_612642
proc url_GetDescribePendingMaintenanceActions_614326(protocol: Scheme;
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

proc validate_GetDescribePendingMaintenanceActions_614325(path: JsonNode;
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
  var valid_614327 = query.getOrDefault("ResourceIdentifier")
  valid_614327 = validateParameter(valid_614327, JString, required = false,
                                 default = nil)
  if valid_614327 != nil:
    section.add "ResourceIdentifier", valid_614327
  var valid_614328 = query.getOrDefault("Marker")
  valid_614328 = validateParameter(valid_614328, JString, required = false,
                                 default = nil)
  if valid_614328 != nil:
    section.add "Marker", valid_614328
  var valid_614329 = query.getOrDefault("Action")
  valid_614329 = validateParameter(valid_614329, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_614329 != nil:
    section.add "Action", valid_614329
  var valid_614330 = query.getOrDefault("Version")
  valid_614330 = validateParameter(valid_614330, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614330 != nil:
    section.add "Version", valid_614330
  var valid_614331 = query.getOrDefault("Filters")
  valid_614331 = validateParameter(valid_614331, JArray, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "Filters", valid_614331
  var valid_614332 = query.getOrDefault("MaxRecords")
  valid_614332 = validateParameter(valid_614332, JInt, required = false, default = nil)
  if valid_614332 != nil:
    section.add "MaxRecords", valid_614332
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614333 = header.getOrDefault("X-Amz-Signature")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Signature", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Content-Sha256", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-Date")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-Date", valid_614335
  var valid_614336 = header.getOrDefault("X-Amz-Credential")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "X-Amz-Credential", valid_614336
  var valid_614337 = header.getOrDefault("X-Amz-Security-Token")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-Security-Token", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-Algorithm")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-Algorithm", valid_614338
  var valid_614339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "X-Amz-SignedHeaders", valid_614339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614340: Call_GetDescribePendingMaintenanceActions_614324;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_614340.validator(path, query, header, formData, body)
  let scheme = call_614340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614340.url(scheme.get, call_614340.host, call_614340.base,
                         call_614340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614340, url, valid)

proc call*(call_614341: Call_GetDescribePendingMaintenanceActions_614324;
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
  var query_614342 = newJObject()
  add(query_614342, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_614342, "Marker", newJString(Marker))
  add(query_614342, "Action", newJString(Action))
  add(query_614342, "Version", newJString(Version))
  if Filters != nil:
    query_614342.add "Filters", Filters
  add(query_614342, "MaxRecords", newJInt(MaxRecords))
  result = call_614341.call(nil, query_614342, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_614324(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_614325, base: "/",
    url: url_GetDescribePendingMaintenanceActions_614326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_614380 = ref object of OpenApiRestCall_612642
proc url_PostFailoverDBCluster_614382(protocol: Scheme; host: string; base: string;
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

proc validate_PostFailoverDBCluster_614381(path: JsonNode; query: JsonNode;
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
  var valid_614383 = query.getOrDefault("Action")
  valid_614383 = validateParameter(valid_614383, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_614383 != nil:
    section.add "Action", valid_614383
  var valid_614384 = query.getOrDefault("Version")
  valid_614384 = validateParameter(valid_614384, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614384 != nil:
    section.add "Version", valid_614384
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614385 = header.getOrDefault("X-Amz-Signature")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-Signature", valid_614385
  var valid_614386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614386 = validateParameter(valid_614386, JString, required = false,
                                 default = nil)
  if valid_614386 != nil:
    section.add "X-Amz-Content-Sha256", valid_614386
  var valid_614387 = header.getOrDefault("X-Amz-Date")
  valid_614387 = validateParameter(valid_614387, JString, required = false,
                                 default = nil)
  if valid_614387 != nil:
    section.add "X-Amz-Date", valid_614387
  var valid_614388 = header.getOrDefault("X-Amz-Credential")
  valid_614388 = validateParameter(valid_614388, JString, required = false,
                                 default = nil)
  if valid_614388 != nil:
    section.add "X-Amz-Credential", valid_614388
  var valid_614389 = header.getOrDefault("X-Amz-Security-Token")
  valid_614389 = validateParameter(valid_614389, JString, required = false,
                                 default = nil)
  if valid_614389 != nil:
    section.add "X-Amz-Security-Token", valid_614389
  var valid_614390 = header.getOrDefault("X-Amz-Algorithm")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-Algorithm", valid_614390
  var valid_614391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "X-Amz-SignedHeaders", valid_614391
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_614392 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_614392 = validateParameter(valid_614392, JString, required = false,
                                 default = nil)
  if valid_614392 != nil:
    section.add "TargetDBInstanceIdentifier", valid_614392
  var valid_614393 = formData.getOrDefault("DBClusterIdentifier")
  valid_614393 = validateParameter(valid_614393, JString, required = false,
                                 default = nil)
  if valid_614393 != nil:
    section.add "DBClusterIdentifier", valid_614393
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614394: Call_PostFailoverDBCluster_614380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_614394.validator(path, query, header, formData, body)
  let scheme = call_614394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614394.url(scheme.get, call_614394.host, call_614394.base,
                         call_614394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614394, url, valid)

proc call*(call_614395: Call_PostFailoverDBCluster_614380;
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
  var query_614396 = newJObject()
  var formData_614397 = newJObject()
  add(query_614396, "Action", newJString(Action))
  add(formData_614397, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_614396, "Version", newJString(Version))
  add(formData_614397, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_614395.call(nil, query_614396, nil, formData_614397, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_614380(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_614381, base: "/",
    url: url_PostFailoverDBCluster_614382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_614363 = ref object of OpenApiRestCall_612642
proc url_GetFailoverDBCluster_614365(protocol: Scheme; host: string; base: string;
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

proc validate_GetFailoverDBCluster_614364(path: JsonNode; query: JsonNode;
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
  var valid_614366 = query.getOrDefault("DBClusterIdentifier")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "DBClusterIdentifier", valid_614366
  var valid_614367 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "TargetDBInstanceIdentifier", valid_614367
  var valid_614368 = query.getOrDefault("Action")
  valid_614368 = validateParameter(valid_614368, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_614368 != nil:
    section.add "Action", valid_614368
  var valid_614369 = query.getOrDefault("Version")
  valid_614369 = validateParameter(valid_614369, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614369 != nil:
    section.add "Version", valid_614369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614370 = header.getOrDefault("X-Amz-Signature")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-Signature", valid_614370
  var valid_614371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "X-Amz-Content-Sha256", valid_614371
  var valid_614372 = header.getOrDefault("X-Amz-Date")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "X-Amz-Date", valid_614372
  var valid_614373 = header.getOrDefault("X-Amz-Credential")
  valid_614373 = validateParameter(valid_614373, JString, required = false,
                                 default = nil)
  if valid_614373 != nil:
    section.add "X-Amz-Credential", valid_614373
  var valid_614374 = header.getOrDefault("X-Amz-Security-Token")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "X-Amz-Security-Token", valid_614374
  var valid_614375 = header.getOrDefault("X-Amz-Algorithm")
  valid_614375 = validateParameter(valid_614375, JString, required = false,
                                 default = nil)
  if valid_614375 != nil:
    section.add "X-Amz-Algorithm", valid_614375
  var valid_614376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614376 = validateParameter(valid_614376, JString, required = false,
                                 default = nil)
  if valid_614376 != nil:
    section.add "X-Amz-SignedHeaders", valid_614376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614377: Call_GetFailoverDBCluster_614363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_614377.validator(path, query, header, formData, body)
  let scheme = call_614377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614377.url(scheme.get, call_614377.host, call_614377.base,
                         call_614377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614377, url, valid)

proc call*(call_614378: Call_GetFailoverDBCluster_614363;
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
  var query_614379 = newJObject()
  add(query_614379, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_614379, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_614379, "Action", newJString(Action))
  add(query_614379, "Version", newJString(Version))
  result = call_614378.call(nil, query_614379, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_614363(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_614364, base: "/",
    url: url_GetFailoverDBCluster_614365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_614415 = ref object of OpenApiRestCall_612642
proc url_PostListTagsForResource_614417(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_614416(path: JsonNode; query: JsonNode;
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
  var valid_614418 = query.getOrDefault("Action")
  valid_614418 = validateParameter(valid_614418, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614418 != nil:
    section.add "Action", valid_614418
  var valid_614419 = query.getOrDefault("Version")
  valid_614419 = validateParameter(valid_614419, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614419 != nil:
    section.add "Version", valid_614419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614420 = header.getOrDefault("X-Amz-Signature")
  valid_614420 = validateParameter(valid_614420, JString, required = false,
                                 default = nil)
  if valid_614420 != nil:
    section.add "X-Amz-Signature", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Content-Sha256", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Date")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Date", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-Credential")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-Credential", valid_614423
  var valid_614424 = header.getOrDefault("X-Amz-Security-Token")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-Security-Token", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Algorithm")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Algorithm", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-SignedHeaders", valid_614426
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_614427 = formData.getOrDefault("Filters")
  valid_614427 = validateParameter(valid_614427, JArray, required = false,
                                 default = nil)
  if valid_614427 != nil:
    section.add "Filters", valid_614427
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_614428 = formData.getOrDefault("ResourceName")
  valid_614428 = validateParameter(valid_614428, JString, required = true,
                                 default = nil)
  if valid_614428 != nil:
    section.add "ResourceName", valid_614428
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614429: Call_PostListTagsForResource_614415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_614429.validator(path, query, header, formData, body)
  let scheme = call_614429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614429.url(scheme.get, call_614429.host, call_614429.base,
                         call_614429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614429, url, valid)

proc call*(call_614430: Call_PostListTagsForResource_614415; ResourceName: string;
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
  var query_614431 = newJObject()
  var formData_614432 = newJObject()
  add(query_614431, "Action", newJString(Action))
  if Filters != nil:
    formData_614432.add "Filters", Filters
  add(query_614431, "Version", newJString(Version))
  add(formData_614432, "ResourceName", newJString(ResourceName))
  result = call_614430.call(nil, query_614431, nil, formData_614432, nil)

var postListTagsForResource* = Call_PostListTagsForResource_614415(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_614416, base: "/",
    url: url_PostListTagsForResource_614417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_614398 = ref object of OpenApiRestCall_612642
proc url_GetListTagsForResource_614400(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_614399(path: JsonNode; query: JsonNode;
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
  var valid_614401 = query.getOrDefault("ResourceName")
  valid_614401 = validateParameter(valid_614401, JString, required = true,
                                 default = nil)
  if valid_614401 != nil:
    section.add "ResourceName", valid_614401
  var valid_614402 = query.getOrDefault("Action")
  valid_614402 = validateParameter(valid_614402, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614402 != nil:
    section.add "Action", valid_614402
  var valid_614403 = query.getOrDefault("Version")
  valid_614403 = validateParameter(valid_614403, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614403 != nil:
    section.add "Version", valid_614403
  var valid_614404 = query.getOrDefault("Filters")
  valid_614404 = validateParameter(valid_614404, JArray, required = false,
                                 default = nil)
  if valid_614404 != nil:
    section.add "Filters", valid_614404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614405 = header.getOrDefault("X-Amz-Signature")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-Signature", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Content-Sha256", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Date")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Date", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-Credential")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-Credential", valid_614408
  var valid_614409 = header.getOrDefault("X-Amz-Security-Token")
  valid_614409 = validateParameter(valid_614409, JString, required = false,
                                 default = nil)
  if valid_614409 != nil:
    section.add "X-Amz-Security-Token", valid_614409
  var valid_614410 = header.getOrDefault("X-Amz-Algorithm")
  valid_614410 = validateParameter(valid_614410, JString, required = false,
                                 default = nil)
  if valid_614410 != nil:
    section.add "X-Amz-Algorithm", valid_614410
  var valid_614411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614411 = validateParameter(valid_614411, JString, required = false,
                                 default = nil)
  if valid_614411 != nil:
    section.add "X-Amz-SignedHeaders", valid_614411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614412: Call_GetListTagsForResource_614398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_614412.validator(path, query, header, formData, body)
  let scheme = call_614412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614412.url(scheme.get, call_614412.host, call_614412.base,
                         call_614412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614412, url, valid)

proc call*(call_614413: Call_GetListTagsForResource_614398; ResourceName: string;
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
  var query_614414 = newJObject()
  add(query_614414, "ResourceName", newJString(ResourceName))
  add(query_614414, "Action", newJString(Action))
  add(query_614414, "Version", newJString(Version))
  if Filters != nil:
    query_614414.add "Filters", Filters
  result = call_614413.call(nil, query_614414, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_614398(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_614399, base: "/",
    url: url_GetListTagsForResource_614400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_614462 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBCluster_614464(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBCluster_614463(path: JsonNode; query: JsonNode;
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
  var valid_614465 = query.getOrDefault("Action")
  valid_614465 = validateParameter(valid_614465, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_614465 != nil:
    section.add "Action", valid_614465
  var valid_614466 = query.getOrDefault("Version")
  valid_614466 = validateParameter(valid_614466, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614466 != nil:
    section.add "Version", valid_614466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614467 = header.getOrDefault("X-Amz-Signature")
  valid_614467 = validateParameter(valid_614467, JString, required = false,
                                 default = nil)
  if valid_614467 != nil:
    section.add "X-Amz-Signature", valid_614467
  var valid_614468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614468 = validateParameter(valid_614468, JString, required = false,
                                 default = nil)
  if valid_614468 != nil:
    section.add "X-Amz-Content-Sha256", valid_614468
  var valid_614469 = header.getOrDefault("X-Amz-Date")
  valid_614469 = validateParameter(valid_614469, JString, required = false,
                                 default = nil)
  if valid_614469 != nil:
    section.add "X-Amz-Date", valid_614469
  var valid_614470 = header.getOrDefault("X-Amz-Credential")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "X-Amz-Credential", valid_614470
  var valid_614471 = header.getOrDefault("X-Amz-Security-Token")
  valid_614471 = validateParameter(valid_614471, JString, required = false,
                                 default = nil)
  if valid_614471 != nil:
    section.add "X-Amz-Security-Token", valid_614471
  var valid_614472 = header.getOrDefault("X-Amz-Algorithm")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "X-Amz-Algorithm", valid_614472
  var valid_614473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-SignedHeaders", valid_614473
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
  var valid_614474 = formData.getOrDefault("Port")
  valid_614474 = validateParameter(valid_614474, JInt, required = false, default = nil)
  if valid_614474 != nil:
    section.add "Port", valid_614474
  var valid_614475 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "PreferredMaintenanceWindow", valid_614475
  var valid_614476 = formData.getOrDefault("PreferredBackupWindow")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "PreferredBackupWindow", valid_614476
  var valid_614477 = formData.getOrDefault("MasterUserPassword")
  valid_614477 = validateParameter(valid_614477, JString, required = false,
                                 default = nil)
  if valid_614477 != nil:
    section.add "MasterUserPassword", valid_614477
  var valid_614478 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_614478 = validateParameter(valid_614478, JArray, required = false,
                                 default = nil)
  if valid_614478 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_614478
  var valid_614479 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_614479 = validateParameter(valid_614479, JArray, required = false,
                                 default = nil)
  if valid_614479 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_614479
  var valid_614480 = formData.getOrDefault("EngineVersion")
  valid_614480 = validateParameter(valid_614480, JString, required = false,
                                 default = nil)
  if valid_614480 != nil:
    section.add "EngineVersion", valid_614480
  var valid_614481 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_614481 = validateParameter(valid_614481, JArray, required = false,
                                 default = nil)
  if valid_614481 != nil:
    section.add "VpcSecurityGroupIds", valid_614481
  var valid_614482 = formData.getOrDefault("BackupRetentionPeriod")
  valid_614482 = validateParameter(valid_614482, JInt, required = false, default = nil)
  if valid_614482 != nil:
    section.add "BackupRetentionPeriod", valid_614482
  var valid_614483 = formData.getOrDefault("ApplyImmediately")
  valid_614483 = validateParameter(valid_614483, JBool, required = false, default = nil)
  if valid_614483 != nil:
    section.add "ApplyImmediately", valid_614483
  var valid_614484 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_614484 = validateParameter(valid_614484, JString, required = false,
                                 default = nil)
  if valid_614484 != nil:
    section.add "DBClusterParameterGroupName", valid_614484
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_614485 = formData.getOrDefault("DBClusterIdentifier")
  valid_614485 = validateParameter(valid_614485, JString, required = true,
                                 default = nil)
  if valid_614485 != nil:
    section.add "DBClusterIdentifier", valid_614485
  var valid_614486 = formData.getOrDefault("DeletionProtection")
  valid_614486 = validateParameter(valid_614486, JBool, required = false, default = nil)
  if valid_614486 != nil:
    section.add "DeletionProtection", valid_614486
  var valid_614487 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_614487 = validateParameter(valid_614487, JString, required = false,
                                 default = nil)
  if valid_614487 != nil:
    section.add "NewDBClusterIdentifier", valid_614487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614488: Call_PostModifyDBCluster_614462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_614488.validator(path, query, header, formData, body)
  let scheme = call_614488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614488.url(scheme.get, call_614488.host, call_614488.base,
                         call_614488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614488, url, valid)

proc call*(call_614489: Call_PostModifyDBCluster_614462;
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
  var query_614490 = newJObject()
  var formData_614491 = newJObject()
  add(formData_614491, "Port", newJInt(Port))
  add(formData_614491, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_614491, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_614491, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_614491.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_614491.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_614491, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_614491.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_614491, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_614491, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_614490, "Action", newJString(Action))
  add(formData_614491, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_614490, "Version", newJString(Version))
  add(formData_614491, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_614491, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_614491, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  result = call_614489.call(nil, query_614490, nil, formData_614491, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_614462(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_614463, base: "/",
    url: url_PostModifyDBCluster_614464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_614433 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBCluster_614435(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBCluster_614434(path: JsonNode; query: JsonNode;
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
  var valid_614436 = query.getOrDefault("DeletionProtection")
  valid_614436 = validateParameter(valid_614436, JBool, required = false, default = nil)
  if valid_614436 != nil:
    section.add "DeletionProtection", valid_614436
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_614437 = query.getOrDefault("DBClusterIdentifier")
  valid_614437 = validateParameter(valid_614437, JString, required = true,
                                 default = nil)
  if valid_614437 != nil:
    section.add "DBClusterIdentifier", valid_614437
  var valid_614438 = query.getOrDefault("DBClusterParameterGroupName")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "DBClusterParameterGroupName", valid_614438
  var valid_614439 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_614439 = validateParameter(valid_614439, JArray, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_614439
  var valid_614440 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_614440 = validateParameter(valid_614440, JArray, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_614440
  var valid_614441 = query.getOrDefault("BackupRetentionPeriod")
  valid_614441 = validateParameter(valid_614441, JInt, required = false, default = nil)
  if valid_614441 != nil:
    section.add "BackupRetentionPeriod", valid_614441
  var valid_614442 = query.getOrDefault("EngineVersion")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "EngineVersion", valid_614442
  var valid_614443 = query.getOrDefault("Action")
  valid_614443 = validateParameter(valid_614443, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_614443 != nil:
    section.add "Action", valid_614443
  var valid_614444 = query.getOrDefault("ApplyImmediately")
  valid_614444 = validateParameter(valid_614444, JBool, required = false, default = nil)
  if valid_614444 != nil:
    section.add "ApplyImmediately", valid_614444
  var valid_614445 = query.getOrDefault("NewDBClusterIdentifier")
  valid_614445 = validateParameter(valid_614445, JString, required = false,
                                 default = nil)
  if valid_614445 != nil:
    section.add "NewDBClusterIdentifier", valid_614445
  var valid_614446 = query.getOrDefault("Port")
  valid_614446 = validateParameter(valid_614446, JInt, required = false, default = nil)
  if valid_614446 != nil:
    section.add "Port", valid_614446
  var valid_614447 = query.getOrDefault("VpcSecurityGroupIds")
  valid_614447 = validateParameter(valid_614447, JArray, required = false,
                                 default = nil)
  if valid_614447 != nil:
    section.add "VpcSecurityGroupIds", valid_614447
  var valid_614448 = query.getOrDefault("MasterUserPassword")
  valid_614448 = validateParameter(valid_614448, JString, required = false,
                                 default = nil)
  if valid_614448 != nil:
    section.add "MasterUserPassword", valid_614448
  var valid_614449 = query.getOrDefault("Version")
  valid_614449 = validateParameter(valid_614449, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614449 != nil:
    section.add "Version", valid_614449
  var valid_614450 = query.getOrDefault("PreferredBackupWindow")
  valid_614450 = validateParameter(valid_614450, JString, required = false,
                                 default = nil)
  if valid_614450 != nil:
    section.add "PreferredBackupWindow", valid_614450
  var valid_614451 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_614451 = validateParameter(valid_614451, JString, required = false,
                                 default = nil)
  if valid_614451 != nil:
    section.add "PreferredMaintenanceWindow", valid_614451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614452 = header.getOrDefault("X-Amz-Signature")
  valid_614452 = validateParameter(valid_614452, JString, required = false,
                                 default = nil)
  if valid_614452 != nil:
    section.add "X-Amz-Signature", valid_614452
  var valid_614453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614453 = validateParameter(valid_614453, JString, required = false,
                                 default = nil)
  if valid_614453 != nil:
    section.add "X-Amz-Content-Sha256", valid_614453
  var valid_614454 = header.getOrDefault("X-Amz-Date")
  valid_614454 = validateParameter(valid_614454, JString, required = false,
                                 default = nil)
  if valid_614454 != nil:
    section.add "X-Amz-Date", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-Credential")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-Credential", valid_614455
  var valid_614456 = header.getOrDefault("X-Amz-Security-Token")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Security-Token", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-Algorithm")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-Algorithm", valid_614457
  var valid_614458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-SignedHeaders", valid_614458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614459: Call_GetModifyDBCluster_614433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_614459.validator(path, query, header, formData, body)
  let scheme = call_614459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614459.url(scheme.get, call_614459.host, call_614459.base,
                         call_614459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614459, url, valid)

proc call*(call_614460: Call_GetModifyDBCluster_614433;
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
  var query_614461 = newJObject()
  add(query_614461, "DeletionProtection", newJBool(DeletionProtection))
  add(query_614461, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_614461, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_614461.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_614461.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_614461, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_614461, "EngineVersion", newJString(EngineVersion))
  add(query_614461, "Action", newJString(Action))
  add(query_614461, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_614461, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_614461, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_614461.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_614461, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_614461, "Version", newJString(Version))
  add(query_614461, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_614461, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_614460.call(nil, query_614461, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_614433(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_614434,
    base: "/", url: url_GetModifyDBCluster_614435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_614509 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBClusterParameterGroup_614511(protocol: Scheme; host: string;
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

proc validate_PostModifyDBClusterParameterGroup_614510(path: JsonNode;
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
  var valid_614512 = query.getOrDefault("Action")
  valid_614512 = validateParameter(valid_614512, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_614512 != nil:
    section.add "Action", valid_614512
  var valid_614513 = query.getOrDefault("Version")
  valid_614513 = validateParameter(valid_614513, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614513 != nil:
    section.add "Version", valid_614513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614514 = header.getOrDefault("X-Amz-Signature")
  valid_614514 = validateParameter(valid_614514, JString, required = false,
                                 default = nil)
  if valid_614514 != nil:
    section.add "X-Amz-Signature", valid_614514
  var valid_614515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614515 = validateParameter(valid_614515, JString, required = false,
                                 default = nil)
  if valid_614515 != nil:
    section.add "X-Amz-Content-Sha256", valid_614515
  var valid_614516 = header.getOrDefault("X-Amz-Date")
  valid_614516 = validateParameter(valid_614516, JString, required = false,
                                 default = nil)
  if valid_614516 != nil:
    section.add "X-Amz-Date", valid_614516
  var valid_614517 = header.getOrDefault("X-Amz-Credential")
  valid_614517 = validateParameter(valid_614517, JString, required = false,
                                 default = nil)
  if valid_614517 != nil:
    section.add "X-Amz-Credential", valid_614517
  var valid_614518 = header.getOrDefault("X-Amz-Security-Token")
  valid_614518 = validateParameter(valid_614518, JString, required = false,
                                 default = nil)
  if valid_614518 != nil:
    section.add "X-Amz-Security-Token", valid_614518
  var valid_614519 = header.getOrDefault("X-Amz-Algorithm")
  valid_614519 = validateParameter(valid_614519, JString, required = false,
                                 default = nil)
  if valid_614519 != nil:
    section.add "X-Amz-Algorithm", valid_614519
  var valid_614520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614520 = validateParameter(valid_614520, JString, required = false,
                                 default = nil)
  if valid_614520 != nil:
    section.add "X-Amz-SignedHeaders", valid_614520
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_614521 = formData.getOrDefault("Parameters")
  valid_614521 = validateParameter(valid_614521, JArray, required = true, default = nil)
  if valid_614521 != nil:
    section.add "Parameters", valid_614521
  var valid_614522 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_614522 = validateParameter(valid_614522, JString, required = true,
                                 default = nil)
  if valid_614522 != nil:
    section.add "DBClusterParameterGroupName", valid_614522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614523: Call_PostModifyDBClusterParameterGroup_614509;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_614523.validator(path, query, header, formData, body)
  let scheme = call_614523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614523.url(scheme.get, call_614523.host, call_614523.base,
                         call_614523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614523, url, valid)

proc call*(call_614524: Call_PostModifyDBClusterParameterGroup_614509;
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
  var query_614525 = newJObject()
  var formData_614526 = newJObject()
  add(query_614525, "Action", newJString(Action))
  if Parameters != nil:
    formData_614526.add "Parameters", Parameters
  add(formData_614526, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_614525, "Version", newJString(Version))
  result = call_614524.call(nil, query_614525, nil, formData_614526, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_614509(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_614510, base: "/",
    url: url_PostModifyDBClusterParameterGroup_614511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_614492 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBClusterParameterGroup_614494(protocol: Scheme; host: string;
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

proc validate_GetModifyDBClusterParameterGroup_614493(path: JsonNode;
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
  var valid_614495 = query.getOrDefault("Parameters")
  valid_614495 = validateParameter(valid_614495, JArray, required = true, default = nil)
  if valid_614495 != nil:
    section.add "Parameters", valid_614495
  var valid_614496 = query.getOrDefault("DBClusterParameterGroupName")
  valid_614496 = validateParameter(valid_614496, JString, required = true,
                                 default = nil)
  if valid_614496 != nil:
    section.add "DBClusterParameterGroupName", valid_614496
  var valid_614497 = query.getOrDefault("Action")
  valid_614497 = validateParameter(valid_614497, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_614497 != nil:
    section.add "Action", valid_614497
  var valid_614498 = query.getOrDefault("Version")
  valid_614498 = validateParameter(valid_614498, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614498 != nil:
    section.add "Version", valid_614498
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614499 = header.getOrDefault("X-Amz-Signature")
  valid_614499 = validateParameter(valid_614499, JString, required = false,
                                 default = nil)
  if valid_614499 != nil:
    section.add "X-Amz-Signature", valid_614499
  var valid_614500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614500 = validateParameter(valid_614500, JString, required = false,
                                 default = nil)
  if valid_614500 != nil:
    section.add "X-Amz-Content-Sha256", valid_614500
  var valid_614501 = header.getOrDefault("X-Amz-Date")
  valid_614501 = validateParameter(valid_614501, JString, required = false,
                                 default = nil)
  if valid_614501 != nil:
    section.add "X-Amz-Date", valid_614501
  var valid_614502 = header.getOrDefault("X-Amz-Credential")
  valid_614502 = validateParameter(valid_614502, JString, required = false,
                                 default = nil)
  if valid_614502 != nil:
    section.add "X-Amz-Credential", valid_614502
  var valid_614503 = header.getOrDefault("X-Amz-Security-Token")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "X-Amz-Security-Token", valid_614503
  var valid_614504 = header.getOrDefault("X-Amz-Algorithm")
  valid_614504 = validateParameter(valid_614504, JString, required = false,
                                 default = nil)
  if valid_614504 != nil:
    section.add "X-Amz-Algorithm", valid_614504
  var valid_614505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614505 = validateParameter(valid_614505, JString, required = false,
                                 default = nil)
  if valid_614505 != nil:
    section.add "X-Amz-SignedHeaders", valid_614505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614506: Call_GetModifyDBClusterParameterGroup_614492;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_614506.validator(path, query, header, formData, body)
  let scheme = call_614506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614506.url(scheme.get, call_614506.host, call_614506.base,
                         call_614506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614506, url, valid)

proc call*(call_614507: Call_GetModifyDBClusterParameterGroup_614492;
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
  var query_614508 = newJObject()
  if Parameters != nil:
    query_614508.add "Parameters", Parameters
  add(query_614508, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_614508, "Action", newJString(Action))
  add(query_614508, "Version", newJString(Version))
  result = call_614507.call(nil, query_614508, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_614492(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_614493, base: "/",
    url: url_GetModifyDBClusterParameterGroup_614494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_614546 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBClusterSnapshotAttribute_614548(protocol: Scheme;
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

proc validate_PostModifyDBClusterSnapshotAttribute_614547(path: JsonNode;
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
  var valid_614549 = query.getOrDefault("Action")
  valid_614549 = validateParameter(valid_614549, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_614549 != nil:
    section.add "Action", valid_614549
  var valid_614550 = query.getOrDefault("Version")
  valid_614550 = validateParameter(valid_614550, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614550 != nil:
    section.add "Version", valid_614550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614551 = header.getOrDefault("X-Amz-Signature")
  valid_614551 = validateParameter(valid_614551, JString, required = false,
                                 default = nil)
  if valid_614551 != nil:
    section.add "X-Amz-Signature", valid_614551
  var valid_614552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614552 = validateParameter(valid_614552, JString, required = false,
                                 default = nil)
  if valid_614552 != nil:
    section.add "X-Amz-Content-Sha256", valid_614552
  var valid_614553 = header.getOrDefault("X-Amz-Date")
  valid_614553 = validateParameter(valid_614553, JString, required = false,
                                 default = nil)
  if valid_614553 != nil:
    section.add "X-Amz-Date", valid_614553
  var valid_614554 = header.getOrDefault("X-Amz-Credential")
  valid_614554 = validateParameter(valid_614554, JString, required = false,
                                 default = nil)
  if valid_614554 != nil:
    section.add "X-Amz-Credential", valid_614554
  var valid_614555 = header.getOrDefault("X-Amz-Security-Token")
  valid_614555 = validateParameter(valid_614555, JString, required = false,
                                 default = nil)
  if valid_614555 != nil:
    section.add "X-Amz-Security-Token", valid_614555
  var valid_614556 = header.getOrDefault("X-Amz-Algorithm")
  valid_614556 = validateParameter(valid_614556, JString, required = false,
                                 default = nil)
  if valid_614556 != nil:
    section.add "X-Amz-Algorithm", valid_614556
  var valid_614557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614557 = validateParameter(valid_614557, JString, required = false,
                                 default = nil)
  if valid_614557 != nil:
    section.add "X-Amz-SignedHeaders", valid_614557
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
  var valid_614558 = formData.getOrDefault("AttributeName")
  valid_614558 = validateParameter(valid_614558, JString, required = true,
                                 default = nil)
  if valid_614558 != nil:
    section.add "AttributeName", valid_614558
  var valid_614559 = formData.getOrDefault("ValuesToAdd")
  valid_614559 = validateParameter(valid_614559, JArray, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "ValuesToAdd", valid_614559
  var valid_614560 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_614560 = validateParameter(valid_614560, JString, required = true,
                                 default = nil)
  if valid_614560 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_614560
  var valid_614561 = formData.getOrDefault("ValuesToRemove")
  valid_614561 = validateParameter(valid_614561, JArray, required = false,
                                 default = nil)
  if valid_614561 != nil:
    section.add "ValuesToRemove", valid_614561
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614562: Call_PostModifyDBClusterSnapshotAttribute_614546;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_614562.validator(path, query, header, formData, body)
  let scheme = call_614562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614562.url(scheme.get, call_614562.host, call_614562.base,
                         call_614562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614562, url, valid)

proc call*(call_614563: Call_PostModifyDBClusterSnapshotAttribute_614546;
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
  var query_614564 = newJObject()
  var formData_614565 = newJObject()
  add(formData_614565, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    formData_614565.add "ValuesToAdd", ValuesToAdd
  add(formData_614565, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_614564, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_614565.add "ValuesToRemove", ValuesToRemove
  add(query_614564, "Version", newJString(Version))
  result = call_614563.call(nil, query_614564, nil, formData_614565, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_614546(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_614547, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_614548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_614527 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBClusterSnapshotAttribute_614529(protocol: Scheme; host: string;
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

proc validate_GetModifyDBClusterSnapshotAttribute_614528(path: JsonNode;
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
  var valid_614530 = query.getOrDefault("ValuesToRemove")
  valid_614530 = validateParameter(valid_614530, JArray, required = false,
                                 default = nil)
  if valid_614530 != nil:
    section.add "ValuesToRemove", valid_614530
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_614531 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_614531 = validateParameter(valid_614531, JString, required = true,
                                 default = nil)
  if valid_614531 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_614531
  var valid_614532 = query.getOrDefault("Action")
  valid_614532 = validateParameter(valid_614532, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_614532 != nil:
    section.add "Action", valid_614532
  var valid_614533 = query.getOrDefault("AttributeName")
  valid_614533 = validateParameter(valid_614533, JString, required = true,
                                 default = nil)
  if valid_614533 != nil:
    section.add "AttributeName", valid_614533
  var valid_614534 = query.getOrDefault("ValuesToAdd")
  valid_614534 = validateParameter(valid_614534, JArray, required = false,
                                 default = nil)
  if valid_614534 != nil:
    section.add "ValuesToAdd", valid_614534
  var valid_614535 = query.getOrDefault("Version")
  valid_614535 = validateParameter(valid_614535, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614535 != nil:
    section.add "Version", valid_614535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614536 = header.getOrDefault("X-Amz-Signature")
  valid_614536 = validateParameter(valid_614536, JString, required = false,
                                 default = nil)
  if valid_614536 != nil:
    section.add "X-Amz-Signature", valid_614536
  var valid_614537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614537 = validateParameter(valid_614537, JString, required = false,
                                 default = nil)
  if valid_614537 != nil:
    section.add "X-Amz-Content-Sha256", valid_614537
  var valid_614538 = header.getOrDefault("X-Amz-Date")
  valid_614538 = validateParameter(valid_614538, JString, required = false,
                                 default = nil)
  if valid_614538 != nil:
    section.add "X-Amz-Date", valid_614538
  var valid_614539 = header.getOrDefault("X-Amz-Credential")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "X-Amz-Credential", valid_614539
  var valid_614540 = header.getOrDefault("X-Amz-Security-Token")
  valid_614540 = validateParameter(valid_614540, JString, required = false,
                                 default = nil)
  if valid_614540 != nil:
    section.add "X-Amz-Security-Token", valid_614540
  var valid_614541 = header.getOrDefault("X-Amz-Algorithm")
  valid_614541 = validateParameter(valid_614541, JString, required = false,
                                 default = nil)
  if valid_614541 != nil:
    section.add "X-Amz-Algorithm", valid_614541
  var valid_614542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614542 = validateParameter(valid_614542, JString, required = false,
                                 default = nil)
  if valid_614542 != nil:
    section.add "X-Amz-SignedHeaders", valid_614542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614543: Call_GetModifyDBClusterSnapshotAttribute_614527;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_614543.validator(path, query, header, formData, body)
  let scheme = call_614543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614543.url(scheme.get, call_614543.host, call_614543.base,
                         call_614543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614543, url, valid)

proc call*(call_614544: Call_GetModifyDBClusterSnapshotAttribute_614527;
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
  var query_614545 = newJObject()
  if ValuesToRemove != nil:
    query_614545.add "ValuesToRemove", ValuesToRemove
  add(query_614545, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_614545, "Action", newJString(Action))
  add(query_614545, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    query_614545.add "ValuesToAdd", ValuesToAdd
  add(query_614545, "Version", newJString(Version))
  result = call_614544.call(nil, query_614545, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_614527(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_614528, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_614529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_614589 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBInstance_614591(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_614590(path: JsonNode; query: JsonNode;
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
  var valid_614592 = query.getOrDefault("Action")
  valid_614592 = validateParameter(valid_614592, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_614592 != nil:
    section.add "Action", valid_614592
  var valid_614593 = query.getOrDefault("Version")
  valid_614593 = validateParameter(valid_614593, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614593 != nil:
    section.add "Version", valid_614593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614594 = header.getOrDefault("X-Amz-Signature")
  valid_614594 = validateParameter(valid_614594, JString, required = false,
                                 default = nil)
  if valid_614594 != nil:
    section.add "X-Amz-Signature", valid_614594
  var valid_614595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614595 = validateParameter(valid_614595, JString, required = false,
                                 default = nil)
  if valid_614595 != nil:
    section.add "X-Amz-Content-Sha256", valid_614595
  var valid_614596 = header.getOrDefault("X-Amz-Date")
  valid_614596 = validateParameter(valid_614596, JString, required = false,
                                 default = nil)
  if valid_614596 != nil:
    section.add "X-Amz-Date", valid_614596
  var valid_614597 = header.getOrDefault("X-Amz-Credential")
  valid_614597 = validateParameter(valid_614597, JString, required = false,
                                 default = nil)
  if valid_614597 != nil:
    section.add "X-Amz-Credential", valid_614597
  var valid_614598 = header.getOrDefault("X-Amz-Security-Token")
  valid_614598 = validateParameter(valid_614598, JString, required = false,
                                 default = nil)
  if valid_614598 != nil:
    section.add "X-Amz-Security-Token", valid_614598
  var valid_614599 = header.getOrDefault("X-Amz-Algorithm")
  valid_614599 = validateParameter(valid_614599, JString, required = false,
                                 default = nil)
  if valid_614599 != nil:
    section.add "X-Amz-Algorithm", valid_614599
  var valid_614600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614600 = validateParameter(valid_614600, JString, required = false,
                                 default = nil)
  if valid_614600 != nil:
    section.add "X-Amz-SignedHeaders", valid_614600
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
  var valid_614601 = formData.getOrDefault("PromotionTier")
  valid_614601 = validateParameter(valid_614601, JInt, required = false, default = nil)
  if valid_614601 != nil:
    section.add "PromotionTier", valid_614601
  var valid_614602 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_614602 = validateParameter(valid_614602, JString, required = false,
                                 default = nil)
  if valid_614602 != nil:
    section.add "PreferredMaintenanceWindow", valid_614602
  var valid_614603 = formData.getOrDefault("DBInstanceClass")
  valid_614603 = validateParameter(valid_614603, JString, required = false,
                                 default = nil)
  if valid_614603 != nil:
    section.add "DBInstanceClass", valid_614603
  var valid_614604 = formData.getOrDefault("CACertificateIdentifier")
  valid_614604 = validateParameter(valid_614604, JString, required = false,
                                 default = nil)
  if valid_614604 != nil:
    section.add "CACertificateIdentifier", valid_614604
  var valid_614605 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_614605 = validateParameter(valid_614605, JBool, required = false, default = nil)
  if valid_614605 != nil:
    section.add "AutoMinorVersionUpgrade", valid_614605
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614606 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614606 = validateParameter(valid_614606, JString, required = true,
                                 default = nil)
  if valid_614606 != nil:
    section.add "DBInstanceIdentifier", valid_614606
  var valid_614607 = formData.getOrDefault("ApplyImmediately")
  valid_614607 = validateParameter(valid_614607, JBool, required = false, default = nil)
  if valid_614607 != nil:
    section.add "ApplyImmediately", valid_614607
  var valid_614608 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_614608 = validateParameter(valid_614608, JString, required = false,
                                 default = nil)
  if valid_614608 != nil:
    section.add "NewDBInstanceIdentifier", valid_614608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614609: Call_PostModifyDBInstance_614589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_614609.validator(path, query, header, formData, body)
  let scheme = call_614609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614609.url(scheme.get, call_614609.host, call_614609.base,
                         call_614609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614609, url, valid)

proc call*(call_614610: Call_PostModifyDBInstance_614589;
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
  var query_614611 = newJObject()
  var formData_614612 = newJObject()
  add(formData_614612, "PromotionTier", newJInt(PromotionTier))
  add(formData_614612, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_614612, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614612, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(formData_614612, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_614612, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614612, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_614611, "Action", newJString(Action))
  add(formData_614612, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_614611, "Version", newJString(Version))
  result = call_614610.call(nil, query_614611, nil, formData_614612, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_614589(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_614590, base: "/",
    url: url_PostModifyDBInstance_614591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_614566 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBInstance_614568(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_614567(path: JsonNode; query: JsonNode;
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
  var valid_614569 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_614569 = validateParameter(valid_614569, JString, required = false,
                                 default = nil)
  if valid_614569 != nil:
    section.add "NewDBInstanceIdentifier", valid_614569
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614570 = query.getOrDefault("DBInstanceIdentifier")
  valid_614570 = validateParameter(valid_614570, JString, required = true,
                                 default = nil)
  if valid_614570 != nil:
    section.add "DBInstanceIdentifier", valid_614570
  var valid_614571 = query.getOrDefault("PromotionTier")
  valid_614571 = validateParameter(valid_614571, JInt, required = false, default = nil)
  if valid_614571 != nil:
    section.add "PromotionTier", valid_614571
  var valid_614572 = query.getOrDefault("CACertificateIdentifier")
  valid_614572 = validateParameter(valid_614572, JString, required = false,
                                 default = nil)
  if valid_614572 != nil:
    section.add "CACertificateIdentifier", valid_614572
  var valid_614573 = query.getOrDefault("Action")
  valid_614573 = validateParameter(valid_614573, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_614573 != nil:
    section.add "Action", valid_614573
  var valid_614574 = query.getOrDefault("ApplyImmediately")
  valid_614574 = validateParameter(valid_614574, JBool, required = false, default = nil)
  if valid_614574 != nil:
    section.add "ApplyImmediately", valid_614574
  var valid_614575 = query.getOrDefault("Version")
  valid_614575 = validateParameter(valid_614575, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614575 != nil:
    section.add "Version", valid_614575
  var valid_614576 = query.getOrDefault("DBInstanceClass")
  valid_614576 = validateParameter(valid_614576, JString, required = false,
                                 default = nil)
  if valid_614576 != nil:
    section.add "DBInstanceClass", valid_614576
  var valid_614577 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_614577 = validateParameter(valid_614577, JString, required = false,
                                 default = nil)
  if valid_614577 != nil:
    section.add "PreferredMaintenanceWindow", valid_614577
  var valid_614578 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_614578 = validateParameter(valid_614578, JBool, required = false, default = nil)
  if valid_614578 != nil:
    section.add "AutoMinorVersionUpgrade", valid_614578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614579 = header.getOrDefault("X-Amz-Signature")
  valid_614579 = validateParameter(valid_614579, JString, required = false,
                                 default = nil)
  if valid_614579 != nil:
    section.add "X-Amz-Signature", valid_614579
  var valid_614580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614580 = validateParameter(valid_614580, JString, required = false,
                                 default = nil)
  if valid_614580 != nil:
    section.add "X-Amz-Content-Sha256", valid_614580
  var valid_614581 = header.getOrDefault("X-Amz-Date")
  valid_614581 = validateParameter(valid_614581, JString, required = false,
                                 default = nil)
  if valid_614581 != nil:
    section.add "X-Amz-Date", valid_614581
  var valid_614582 = header.getOrDefault("X-Amz-Credential")
  valid_614582 = validateParameter(valid_614582, JString, required = false,
                                 default = nil)
  if valid_614582 != nil:
    section.add "X-Amz-Credential", valid_614582
  var valid_614583 = header.getOrDefault("X-Amz-Security-Token")
  valid_614583 = validateParameter(valid_614583, JString, required = false,
                                 default = nil)
  if valid_614583 != nil:
    section.add "X-Amz-Security-Token", valid_614583
  var valid_614584 = header.getOrDefault("X-Amz-Algorithm")
  valid_614584 = validateParameter(valid_614584, JString, required = false,
                                 default = nil)
  if valid_614584 != nil:
    section.add "X-Amz-Algorithm", valid_614584
  var valid_614585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614585 = validateParameter(valid_614585, JString, required = false,
                                 default = nil)
  if valid_614585 != nil:
    section.add "X-Amz-SignedHeaders", valid_614585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614586: Call_GetModifyDBInstance_614566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_614586.validator(path, query, header, formData, body)
  let scheme = call_614586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614586.url(scheme.get, call_614586.host, call_614586.base,
                         call_614586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614586, url, valid)

proc call*(call_614587: Call_GetModifyDBInstance_614566;
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
  var query_614588 = newJObject()
  add(query_614588, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_614588, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614588, "PromotionTier", newJInt(PromotionTier))
  add(query_614588, "CACertificateIdentifier", newJString(CACertificateIdentifier))
  add(query_614588, "Action", newJString(Action))
  add(query_614588, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_614588, "Version", newJString(Version))
  add(query_614588, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_614588, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_614588, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_614587.call(nil, query_614588, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_614566(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_614567, base: "/",
    url: url_GetModifyDBInstance_614568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_614631 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBSubnetGroup_614633(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_614632(path: JsonNode; query: JsonNode;
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
  var valid_614634 = query.getOrDefault("Action")
  valid_614634 = validateParameter(valid_614634, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_614634 != nil:
    section.add "Action", valid_614634
  var valid_614635 = query.getOrDefault("Version")
  valid_614635 = validateParameter(valid_614635, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614635 != nil:
    section.add "Version", valid_614635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614636 = header.getOrDefault("X-Amz-Signature")
  valid_614636 = validateParameter(valid_614636, JString, required = false,
                                 default = nil)
  if valid_614636 != nil:
    section.add "X-Amz-Signature", valid_614636
  var valid_614637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614637 = validateParameter(valid_614637, JString, required = false,
                                 default = nil)
  if valid_614637 != nil:
    section.add "X-Amz-Content-Sha256", valid_614637
  var valid_614638 = header.getOrDefault("X-Amz-Date")
  valid_614638 = validateParameter(valid_614638, JString, required = false,
                                 default = nil)
  if valid_614638 != nil:
    section.add "X-Amz-Date", valid_614638
  var valid_614639 = header.getOrDefault("X-Amz-Credential")
  valid_614639 = validateParameter(valid_614639, JString, required = false,
                                 default = nil)
  if valid_614639 != nil:
    section.add "X-Amz-Credential", valid_614639
  var valid_614640 = header.getOrDefault("X-Amz-Security-Token")
  valid_614640 = validateParameter(valid_614640, JString, required = false,
                                 default = nil)
  if valid_614640 != nil:
    section.add "X-Amz-Security-Token", valid_614640
  var valid_614641 = header.getOrDefault("X-Amz-Algorithm")
  valid_614641 = validateParameter(valid_614641, JString, required = false,
                                 default = nil)
  if valid_614641 != nil:
    section.add "X-Amz-Algorithm", valid_614641
  var valid_614642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614642 = validateParameter(valid_614642, JString, required = false,
                                 default = nil)
  if valid_614642 != nil:
    section.add "X-Amz-SignedHeaders", valid_614642
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the DB subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  section = newJObject()
  var valid_614643 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_614643 = validateParameter(valid_614643, JString, required = false,
                                 default = nil)
  if valid_614643 != nil:
    section.add "DBSubnetGroupDescription", valid_614643
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_614644 = formData.getOrDefault("DBSubnetGroupName")
  valid_614644 = validateParameter(valid_614644, JString, required = true,
                                 default = nil)
  if valid_614644 != nil:
    section.add "DBSubnetGroupName", valid_614644
  var valid_614645 = formData.getOrDefault("SubnetIds")
  valid_614645 = validateParameter(valid_614645, JArray, required = true, default = nil)
  if valid_614645 != nil:
    section.add "SubnetIds", valid_614645
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614646: Call_PostModifyDBSubnetGroup_614631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_614646.validator(path, query, header, formData, body)
  let scheme = call_614646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614646.url(scheme.get, call_614646.host, call_614646.base,
                         call_614646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614646, url, valid)

proc call*(call_614647: Call_PostModifyDBSubnetGroup_614631;
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
  var query_614648 = newJObject()
  var formData_614649 = newJObject()
  add(formData_614649, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_614648, "Action", newJString(Action))
  add(formData_614649, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614648, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_614649.add "SubnetIds", SubnetIds
  result = call_614647.call(nil, query_614648, nil, formData_614649, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_614631(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_614632, base: "/",
    url: url_PostModifyDBSubnetGroup_614633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_614613 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBSubnetGroup_614615(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_614614(path: JsonNode; query: JsonNode;
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
  var valid_614616 = query.getOrDefault("SubnetIds")
  valid_614616 = validateParameter(valid_614616, JArray, required = true, default = nil)
  if valid_614616 != nil:
    section.add "SubnetIds", valid_614616
  var valid_614617 = query.getOrDefault("Action")
  valid_614617 = validateParameter(valid_614617, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_614617 != nil:
    section.add "Action", valid_614617
  var valid_614618 = query.getOrDefault("DBSubnetGroupDescription")
  valid_614618 = validateParameter(valid_614618, JString, required = false,
                                 default = nil)
  if valid_614618 != nil:
    section.add "DBSubnetGroupDescription", valid_614618
  var valid_614619 = query.getOrDefault("DBSubnetGroupName")
  valid_614619 = validateParameter(valid_614619, JString, required = true,
                                 default = nil)
  if valid_614619 != nil:
    section.add "DBSubnetGroupName", valid_614619
  var valid_614620 = query.getOrDefault("Version")
  valid_614620 = validateParameter(valid_614620, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614620 != nil:
    section.add "Version", valid_614620
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614621 = header.getOrDefault("X-Amz-Signature")
  valid_614621 = validateParameter(valid_614621, JString, required = false,
                                 default = nil)
  if valid_614621 != nil:
    section.add "X-Amz-Signature", valid_614621
  var valid_614622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "X-Amz-Content-Sha256", valid_614622
  var valid_614623 = header.getOrDefault("X-Amz-Date")
  valid_614623 = validateParameter(valid_614623, JString, required = false,
                                 default = nil)
  if valid_614623 != nil:
    section.add "X-Amz-Date", valid_614623
  var valid_614624 = header.getOrDefault("X-Amz-Credential")
  valid_614624 = validateParameter(valid_614624, JString, required = false,
                                 default = nil)
  if valid_614624 != nil:
    section.add "X-Amz-Credential", valid_614624
  var valid_614625 = header.getOrDefault("X-Amz-Security-Token")
  valid_614625 = validateParameter(valid_614625, JString, required = false,
                                 default = nil)
  if valid_614625 != nil:
    section.add "X-Amz-Security-Token", valid_614625
  var valid_614626 = header.getOrDefault("X-Amz-Algorithm")
  valid_614626 = validateParameter(valid_614626, JString, required = false,
                                 default = nil)
  if valid_614626 != nil:
    section.add "X-Amz-Algorithm", valid_614626
  var valid_614627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614627 = validateParameter(valid_614627, JString, required = false,
                                 default = nil)
  if valid_614627 != nil:
    section.add "X-Amz-SignedHeaders", valid_614627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614628: Call_GetModifyDBSubnetGroup_614613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_614628.validator(path, query, header, formData, body)
  let scheme = call_614628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614628.url(scheme.get, call_614628.host, call_614628.base,
                         call_614628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614628, url, valid)

proc call*(call_614629: Call_GetModifyDBSubnetGroup_614613; SubnetIds: JsonNode;
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
  var query_614630 = newJObject()
  if SubnetIds != nil:
    query_614630.add "SubnetIds", SubnetIds
  add(query_614630, "Action", newJString(Action))
  add(query_614630, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_614630, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614630, "Version", newJString(Version))
  result = call_614629.call(nil, query_614630, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_614613(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_614614, base: "/",
    url: url_GetModifyDBSubnetGroup_614615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_614667 = ref object of OpenApiRestCall_612642
proc url_PostRebootDBInstance_614669(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_614668(path: JsonNode; query: JsonNode;
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
  var valid_614670 = query.getOrDefault("Action")
  valid_614670 = validateParameter(valid_614670, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_614670 != nil:
    section.add "Action", valid_614670
  var valid_614671 = query.getOrDefault("Version")
  valid_614671 = validateParameter(valid_614671, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614671 != nil:
    section.add "Version", valid_614671
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614672 = header.getOrDefault("X-Amz-Signature")
  valid_614672 = validateParameter(valid_614672, JString, required = false,
                                 default = nil)
  if valid_614672 != nil:
    section.add "X-Amz-Signature", valid_614672
  var valid_614673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614673 = validateParameter(valid_614673, JString, required = false,
                                 default = nil)
  if valid_614673 != nil:
    section.add "X-Amz-Content-Sha256", valid_614673
  var valid_614674 = header.getOrDefault("X-Amz-Date")
  valid_614674 = validateParameter(valid_614674, JString, required = false,
                                 default = nil)
  if valid_614674 != nil:
    section.add "X-Amz-Date", valid_614674
  var valid_614675 = header.getOrDefault("X-Amz-Credential")
  valid_614675 = validateParameter(valid_614675, JString, required = false,
                                 default = nil)
  if valid_614675 != nil:
    section.add "X-Amz-Credential", valid_614675
  var valid_614676 = header.getOrDefault("X-Amz-Security-Token")
  valid_614676 = validateParameter(valid_614676, JString, required = false,
                                 default = nil)
  if valid_614676 != nil:
    section.add "X-Amz-Security-Token", valid_614676
  var valid_614677 = header.getOrDefault("X-Amz-Algorithm")
  valid_614677 = validateParameter(valid_614677, JString, required = false,
                                 default = nil)
  if valid_614677 != nil:
    section.add "X-Amz-Algorithm", valid_614677
  var valid_614678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614678 = validateParameter(valid_614678, JString, required = false,
                                 default = nil)
  if valid_614678 != nil:
    section.add "X-Amz-SignedHeaders", valid_614678
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  var valid_614679 = formData.getOrDefault("ForceFailover")
  valid_614679 = validateParameter(valid_614679, JBool, required = false, default = nil)
  if valid_614679 != nil:
    section.add "ForceFailover", valid_614679
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614680 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614680 = validateParameter(valid_614680, JString, required = true,
                                 default = nil)
  if valid_614680 != nil:
    section.add "DBInstanceIdentifier", valid_614680
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614681: Call_PostRebootDBInstance_614667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_614681.validator(path, query, header, formData, body)
  let scheme = call_614681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614681.url(scheme.get, call_614681.host, call_614681.base,
                         call_614681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614681, url, valid)

proc call*(call_614682: Call_PostRebootDBInstance_614667;
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
  var query_614683 = newJObject()
  var formData_614684 = newJObject()
  add(formData_614684, "ForceFailover", newJBool(ForceFailover))
  add(formData_614684, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614683, "Action", newJString(Action))
  add(query_614683, "Version", newJString(Version))
  result = call_614682.call(nil, query_614683, nil, formData_614684, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_614667(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_614668, base: "/",
    url: url_PostRebootDBInstance_614669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_614650 = ref object of OpenApiRestCall_612642
proc url_GetRebootDBInstance_614652(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_614651(path: JsonNode; query: JsonNode;
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
  var valid_614653 = query.getOrDefault("ForceFailover")
  valid_614653 = validateParameter(valid_614653, JBool, required = false, default = nil)
  if valid_614653 != nil:
    section.add "ForceFailover", valid_614653
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614654 = query.getOrDefault("DBInstanceIdentifier")
  valid_614654 = validateParameter(valid_614654, JString, required = true,
                                 default = nil)
  if valid_614654 != nil:
    section.add "DBInstanceIdentifier", valid_614654
  var valid_614655 = query.getOrDefault("Action")
  valid_614655 = validateParameter(valid_614655, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_614655 != nil:
    section.add "Action", valid_614655
  var valid_614656 = query.getOrDefault("Version")
  valid_614656 = validateParameter(valid_614656, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614656 != nil:
    section.add "Version", valid_614656
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614657 = header.getOrDefault("X-Amz-Signature")
  valid_614657 = validateParameter(valid_614657, JString, required = false,
                                 default = nil)
  if valid_614657 != nil:
    section.add "X-Amz-Signature", valid_614657
  var valid_614658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614658 = validateParameter(valid_614658, JString, required = false,
                                 default = nil)
  if valid_614658 != nil:
    section.add "X-Amz-Content-Sha256", valid_614658
  var valid_614659 = header.getOrDefault("X-Amz-Date")
  valid_614659 = validateParameter(valid_614659, JString, required = false,
                                 default = nil)
  if valid_614659 != nil:
    section.add "X-Amz-Date", valid_614659
  var valid_614660 = header.getOrDefault("X-Amz-Credential")
  valid_614660 = validateParameter(valid_614660, JString, required = false,
                                 default = nil)
  if valid_614660 != nil:
    section.add "X-Amz-Credential", valid_614660
  var valid_614661 = header.getOrDefault("X-Amz-Security-Token")
  valid_614661 = validateParameter(valid_614661, JString, required = false,
                                 default = nil)
  if valid_614661 != nil:
    section.add "X-Amz-Security-Token", valid_614661
  var valid_614662 = header.getOrDefault("X-Amz-Algorithm")
  valid_614662 = validateParameter(valid_614662, JString, required = false,
                                 default = nil)
  if valid_614662 != nil:
    section.add "X-Amz-Algorithm", valid_614662
  var valid_614663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614663 = validateParameter(valid_614663, JString, required = false,
                                 default = nil)
  if valid_614663 != nil:
    section.add "X-Amz-SignedHeaders", valid_614663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614664: Call_GetRebootDBInstance_614650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_614664.validator(path, query, header, formData, body)
  let scheme = call_614664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614664.url(scheme.get, call_614664.host, call_614664.base,
                         call_614664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614664, url, valid)

proc call*(call_614665: Call_GetRebootDBInstance_614650;
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
  var query_614666 = newJObject()
  add(query_614666, "ForceFailover", newJBool(ForceFailover))
  add(query_614666, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614666, "Action", newJString(Action))
  add(query_614666, "Version", newJString(Version))
  result = call_614665.call(nil, query_614666, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_614650(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_614651, base: "/",
    url: url_GetRebootDBInstance_614652, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_614702 = ref object of OpenApiRestCall_612642
proc url_PostRemoveTagsFromResource_614704(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_614703(path: JsonNode; query: JsonNode;
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
  var valid_614705 = query.getOrDefault("Action")
  valid_614705 = validateParameter(valid_614705, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_614705 != nil:
    section.add "Action", valid_614705
  var valid_614706 = query.getOrDefault("Version")
  valid_614706 = validateParameter(valid_614706, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614706 != nil:
    section.add "Version", valid_614706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614707 = header.getOrDefault("X-Amz-Signature")
  valid_614707 = validateParameter(valid_614707, JString, required = false,
                                 default = nil)
  if valid_614707 != nil:
    section.add "X-Amz-Signature", valid_614707
  var valid_614708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614708 = validateParameter(valid_614708, JString, required = false,
                                 default = nil)
  if valid_614708 != nil:
    section.add "X-Amz-Content-Sha256", valid_614708
  var valid_614709 = header.getOrDefault("X-Amz-Date")
  valid_614709 = validateParameter(valid_614709, JString, required = false,
                                 default = nil)
  if valid_614709 != nil:
    section.add "X-Amz-Date", valid_614709
  var valid_614710 = header.getOrDefault("X-Amz-Credential")
  valid_614710 = validateParameter(valid_614710, JString, required = false,
                                 default = nil)
  if valid_614710 != nil:
    section.add "X-Amz-Credential", valid_614710
  var valid_614711 = header.getOrDefault("X-Amz-Security-Token")
  valid_614711 = validateParameter(valid_614711, JString, required = false,
                                 default = nil)
  if valid_614711 != nil:
    section.add "X-Amz-Security-Token", valid_614711
  var valid_614712 = header.getOrDefault("X-Amz-Algorithm")
  valid_614712 = validateParameter(valid_614712, JString, required = false,
                                 default = nil)
  if valid_614712 != nil:
    section.add "X-Amz-Algorithm", valid_614712
  var valid_614713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614713 = validateParameter(valid_614713, JString, required = false,
                                 default = nil)
  if valid_614713 != nil:
    section.add "X-Amz-SignedHeaders", valid_614713
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_614714 = formData.getOrDefault("TagKeys")
  valid_614714 = validateParameter(valid_614714, JArray, required = true, default = nil)
  if valid_614714 != nil:
    section.add "TagKeys", valid_614714
  var valid_614715 = formData.getOrDefault("ResourceName")
  valid_614715 = validateParameter(valid_614715, JString, required = true,
                                 default = nil)
  if valid_614715 != nil:
    section.add "ResourceName", valid_614715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614716: Call_PostRemoveTagsFromResource_614702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_614716.validator(path, query, header, formData, body)
  let scheme = call_614716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614716.url(scheme.get, call_614716.host, call_614716.base,
                         call_614716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614716, url, valid)

proc call*(call_614717: Call_PostRemoveTagsFromResource_614702; TagKeys: JsonNode;
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
  var query_614718 = newJObject()
  var formData_614719 = newJObject()
  if TagKeys != nil:
    formData_614719.add "TagKeys", TagKeys
  add(query_614718, "Action", newJString(Action))
  add(query_614718, "Version", newJString(Version))
  add(formData_614719, "ResourceName", newJString(ResourceName))
  result = call_614717.call(nil, query_614718, nil, formData_614719, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_614702(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_614703, base: "/",
    url: url_PostRemoveTagsFromResource_614704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_614685 = ref object of OpenApiRestCall_612642
proc url_GetRemoveTagsFromResource_614687(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_614686(path: JsonNode; query: JsonNode;
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
  var valid_614688 = query.getOrDefault("ResourceName")
  valid_614688 = validateParameter(valid_614688, JString, required = true,
                                 default = nil)
  if valid_614688 != nil:
    section.add "ResourceName", valid_614688
  var valid_614689 = query.getOrDefault("TagKeys")
  valid_614689 = validateParameter(valid_614689, JArray, required = true, default = nil)
  if valid_614689 != nil:
    section.add "TagKeys", valid_614689
  var valid_614690 = query.getOrDefault("Action")
  valid_614690 = validateParameter(valid_614690, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_614690 != nil:
    section.add "Action", valid_614690
  var valid_614691 = query.getOrDefault("Version")
  valid_614691 = validateParameter(valid_614691, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614691 != nil:
    section.add "Version", valid_614691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614692 = header.getOrDefault("X-Amz-Signature")
  valid_614692 = validateParameter(valid_614692, JString, required = false,
                                 default = nil)
  if valid_614692 != nil:
    section.add "X-Amz-Signature", valid_614692
  var valid_614693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614693 = validateParameter(valid_614693, JString, required = false,
                                 default = nil)
  if valid_614693 != nil:
    section.add "X-Amz-Content-Sha256", valid_614693
  var valid_614694 = header.getOrDefault("X-Amz-Date")
  valid_614694 = validateParameter(valid_614694, JString, required = false,
                                 default = nil)
  if valid_614694 != nil:
    section.add "X-Amz-Date", valid_614694
  var valid_614695 = header.getOrDefault("X-Amz-Credential")
  valid_614695 = validateParameter(valid_614695, JString, required = false,
                                 default = nil)
  if valid_614695 != nil:
    section.add "X-Amz-Credential", valid_614695
  var valid_614696 = header.getOrDefault("X-Amz-Security-Token")
  valid_614696 = validateParameter(valid_614696, JString, required = false,
                                 default = nil)
  if valid_614696 != nil:
    section.add "X-Amz-Security-Token", valid_614696
  var valid_614697 = header.getOrDefault("X-Amz-Algorithm")
  valid_614697 = validateParameter(valid_614697, JString, required = false,
                                 default = nil)
  if valid_614697 != nil:
    section.add "X-Amz-Algorithm", valid_614697
  var valid_614698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614698 = validateParameter(valid_614698, JString, required = false,
                                 default = nil)
  if valid_614698 != nil:
    section.add "X-Amz-SignedHeaders", valid_614698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614699: Call_GetRemoveTagsFromResource_614685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_614699.validator(path, query, header, formData, body)
  let scheme = call_614699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614699.url(scheme.get, call_614699.host, call_614699.base,
                         call_614699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614699, url, valid)

proc call*(call_614700: Call_GetRemoveTagsFromResource_614685;
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
  var query_614701 = newJObject()
  add(query_614701, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_614701.add "TagKeys", TagKeys
  add(query_614701, "Action", newJString(Action))
  add(query_614701, "Version", newJString(Version))
  result = call_614700.call(nil, query_614701, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_614685(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_614686, base: "/",
    url: url_GetRemoveTagsFromResource_614687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_614738 = ref object of OpenApiRestCall_612642
proc url_PostResetDBClusterParameterGroup_614740(protocol: Scheme; host: string;
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

proc validate_PostResetDBClusterParameterGroup_614739(path: JsonNode;
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
  var valid_614741 = query.getOrDefault("Action")
  valid_614741 = validateParameter(valid_614741, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_614741 != nil:
    section.add "Action", valid_614741
  var valid_614742 = query.getOrDefault("Version")
  valid_614742 = validateParameter(valid_614742, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614742 != nil:
    section.add "Version", valid_614742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614743 = header.getOrDefault("X-Amz-Signature")
  valid_614743 = validateParameter(valid_614743, JString, required = false,
                                 default = nil)
  if valid_614743 != nil:
    section.add "X-Amz-Signature", valid_614743
  var valid_614744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614744 = validateParameter(valid_614744, JString, required = false,
                                 default = nil)
  if valid_614744 != nil:
    section.add "X-Amz-Content-Sha256", valid_614744
  var valid_614745 = header.getOrDefault("X-Amz-Date")
  valid_614745 = validateParameter(valid_614745, JString, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "X-Amz-Date", valid_614745
  var valid_614746 = header.getOrDefault("X-Amz-Credential")
  valid_614746 = validateParameter(valid_614746, JString, required = false,
                                 default = nil)
  if valid_614746 != nil:
    section.add "X-Amz-Credential", valid_614746
  var valid_614747 = header.getOrDefault("X-Amz-Security-Token")
  valid_614747 = validateParameter(valid_614747, JString, required = false,
                                 default = nil)
  if valid_614747 != nil:
    section.add "X-Amz-Security-Token", valid_614747
  var valid_614748 = header.getOrDefault("X-Amz-Algorithm")
  valid_614748 = validateParameter(valid_614748, JString, required = false,
                                 default = nil)
  if valid_614748 != nil:
    section.add "X-Amz-Algorithm", valid_614748
  var valid_614749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614749 = validateParameter(valid_614749, JString, required = false,
                                 default = nil)
  if valid_614749 != nil:
    section.add "X-Amz-SignedHeaders", valid_614749
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  section = newJObject()
  var valid_614750 = formData.getOrDefault("ResetAllParameters")
  valid_614750 = validateParameter(valid_614750, JBool, required = false, default = nil)
  if valid_614750 != nil:
    section.add "ResetAllParameters", valid_614750
  var valid_614751 = formData.getOrDefault("Parameters")
  valid_614751 = validateParameter(valid_614751, JArray, required = false,
                                 default = nil)
  if valid_614751 != nil:
    section.add "Parameters", valid_614751
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_614752 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_614752 = validateParameter(valid_614752, JString, required = true,
                                 default = nil)
  if valid_614752 != nil:
    section.add "DBClusterParameterGroupName", valid_614752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614753: Call_PostResetDBClusterParameterGroup_614738;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_614753.validator(path, query, header, formData, body)
  let scheme = call_614753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614753.url(scheme.get, call_614753.host, call_614753.base,
                         call_614753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614753, url, valid)

proc call*(call_614754: Call_PostResetDBClusterParameterGroup_614738;
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
  var query_614755 = newJObject()
  var formData_614756 = newJObject()
  add(formData_614756, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_614755, "Action", newJString(Action))
  if Parameters != nil:
    formData_614756.add "Parameters", Parameters
  add(formData_614756, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_614755, "Version", newJString(Version))
  result = call_614754.call(nil, query_614755, nil, formData_614756, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_614738(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_614739, base: "/",
    url: url_PostResetDBClusterParameterGroup_614740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_614720 = ref object of OpenApiRestCall_612642
proc url_GetResetDBClusterParameterGroup_614722(protocol: Scheme; host: string;
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

proc validate_GetResetDBClusterParameterGroup_614721(path: JsonNode;
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
  var valid_614723 = query.getOrDefault("Parameters")
  valid_614723 = validateParameter(valid_614723, JArray, required = false,
                                 default = nil)
  if valid_614723 != nil:
    section.add "Parameters", valid_614723
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_614724 = query.getOrDefault("DBClusterParameterGroupName")
  valid_614724 = validateParameter(valid_614724, JString, required = true,
                                 default = nil)
  if valid_614724 != nil:
    section.add "DBClusterParameterGroupName", valid_614724
  var valid_614725 = query.getOrDefault("ResetAllParameters")
  valid_614725 = validateParameter(valid_614725, JBool, required = false, default = nil)
  if valid_614725 != nil:
    section.add "ResetAllParameters", valid_614725
  var valid_614726 = query.getOrDefault("Action")
  valid_614726 = validateParameter(valid_614726, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_614726 != nil:
    section.add "Action", valid_614726
  var valid_614727 = query.getOrDefault("Version")
  valid_614727 = validateParameter(valid_614727, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614727 != nil:
    section.add "Version", valid_614727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614728 = header.getOrDefault("X-Amz-Signature")
  valid_614728 = validateParameter(valid_614728, JString, required = false,
                                 default = nil)
  if valid_614728 != nil:
    section.add "X-Amz-Signature", valid_614728
  var valid_614729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614729 = validateParameter(valid_614729, JString, required = false,
                                 default = nil)
  if valid_614729 != nil:
    section.add "X-Amz-Content-Sha256", valid_614729
  var valid_614730 = header.getOrDefault("X-Amz-Date")
  valid_614730 = validateParameter(valid_614730, JString, required = false,
                                 default = nil)
  if valid_614730 != nil:
    section.add "X-Amz-Date", valid_614730
  var valid_614731 = header.getOrDefault("X-Amz-Credential")
  valid_614731 = validateParameter(valid_614731, JString, required = false,
                                 default = nil)
  if valid_614731 != nil:
    section.add "X-Amz-Credential", valid_614731
  var valid_614732 = header.getOrDefault("X-Amz-Security-Token")
  valid_614732 = validateParameter(valid_614732, JString, required = false,
                                 default = nil)
  if valid_614732 != nil:
    section.add "X-Amz-Security-Token", valid_614732
  var valid_614733 = header.getOrDefault("X-Amz-Algorithm")
  valid_614733 = validateParameter(valid_614733, JString, required = false,
                                 default = nil)
  if valid_614733 != nil:
    section.add "X-Amz-Algorithm", valid_614733
  var valid_614734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614734 = validateParameter(valid_614734, JString, required = false,
                                 default = nil)
  if valid_614734 != nil:
    section.add "X-Amz-SignedHeaders", valid_614734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614735: Call_GetResetDBClusterParameterGroup_614720;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_614735.validator(path, query, header, formData, body)
  let scheme = call_614735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614735.url(scheme.get, call_614735.host, call_614735.base,
                         call_614735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614735, url, valid)

proc call*(call_614736: Call_GetResetDBClusterParameterGroup_614720;
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
  var query_614737 = newJObject()
  if Parameters != nil:
    query_614737.add "Parameters", Parameters
  add(query_614737, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_614737, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_614737, "Action", newJString(Action))
  add(query_614737, "Version", newJString(Version))
  result = call_614736.call(nil, query_614737, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_614720(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_614721, base: "/",
    url: url_GetResetDBClusterParameterGroup_614722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_614784 = ref object of OpenApiRestCall_612642
proc url_PostRestoreDBClusterFromSnapshot_614786(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBClusterFromSnapshot_614785(path: JsonNode;
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
  var valid_614787 = query.getOrDefault("Action")
  valid_614787 = validateParameter(valid_614787, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_614787 != nil:
    section.add "Action", valid_614787
  var valid_614788 = query.getOrDefault("Version")
  valid_614788 = validateParameter(valid_614788, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614788 != nil:
    section.add "Version", valid_614788
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614789 = header.getOrDefault("X-Amz-Signature")
  valid_614789 = validateParameter(valid_614789, JString, required = false,
                                 default = nil)
  if valid_614789 != nil:
    section.add "X-Amz-Signature", valid_614789
  var valid_614790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614790 = validateParameter(valid_614790, JString, required = false,
                                 default = nil)
  if valid_614790 != nil:
    section.add "X-Amz-Content-Sha256", valid_614790
  var valid_614791 = header.getOrDefault("X-Amz-Date")
  valid_614791 = validateParameter(valid_614791, JString, required = false,
                                 default = nil)
  if valid_614791 != nil:
    section.add "X-Amz-Date", valid_614791
  var valid_614792 = header.getOrDefault("X-Amz-Credential")
  valid_614792 = validateParameter(valid_614792, JString, required = false,
                                 default = nil)
  if valid_614792 != nil:
    section.add "X-Amz-Credential", valid_614792
  var valid_614793 = header.getOrDefault("X-Amz-Security-Token")
  valid_614793 = validateParameter(valid_614793, JString, required = false,
                                 default = nil)
  if valid_614793 != nil:
    section.add "X-Amz-Security-Token", valid_614793
  var valid_614794 = header.getOrDefault("X-Amz-Algorithm")
  valid_614794 = validateParameter(valid_614794, JString, required = false,
                                 default = nil)
  if valid_614794 != nil:
    section.add "X-Amz-Algorithm", valid_614794
  var valid_614795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614795 = validateParameter(valid_614795, JString, required = false,
                                 default = nil)
  if valid_614795 != nil:
    section.add "X-Amz-SignedHeaders", valid_614795
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
  var valid_614796 = formData.getOrDefault("Port")
  valid_614796 = validateParameter(valid_614796, JInt, required = false, default = nil)
  if valid_614796 != nil:
    section.add "Port", valid_614796
  var valid_614797 = formData.getOrDefault("EngineVersion")
  valid_614797 = validateParameter(valid_614797, JString, required = false,
                                 default = nil)
  if valid_614797 != nil:
    section.add "EngineVersion", valid_614797
  var valid_614798 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_614798 = validateParameter(valid_614798, JArray, required = false,
                                 default = nil)
  if valid_614798 != nil:
    section.add "VpcSecurityGroupIds", valid_614798
  var valid_614799 = formData.getOrDefault("AvailabilityZones")
  valid_614799 = validateParameter(valid_614799, JArray, required = false,
                                 default = nil)
  if valid_614799 != nil:
    section.add "AvailabilityZones", valid_614799
  var valid_614800 = formData.getOrDefault("KmsKeyId")
  valid_614800 = validateParameter(valid_614800, JString, required = false,
                                 default = nil)
  if valid_614800 != nil:
    section.add "KmsKeyId", valid_614800
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_614801 = formData.getOrDefault("Engine")
  valid_614801 = validateParameter(valid_614801, JString, required = true,
                                 default = nil)
  if valid_614801 != nil:
    section.add "Engine", valid_614801
  var valid_614802 = formData.getOrDefault("SnapshotIdentifier")
  valid_614802 = validateParameter(valid_614802, JString, required = true,
                                 default = nil)
  if valid_614802 != nil:
    section.add "SnapshotIdentifier", valid_614802
  var valid_614803 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_614803 = validateParameter(valid_614803, JArray, required = false,
                                 default = nil)
  if valid_614803 != nil:
    section.add "EnableCloudwatchLogsExports", valid_614803
  var valid_614804 = formData.getOrDefault("Tags")
  valid_614804 = validateParameter(valid_614804, JArray, required = false,
                                 default = nil)
  if valid_614804 != nil:
    section.add "Tags", valid_614804
  var valid_614805 = formData.getOrDefault("DBSubnetGroupName")
  valid_614805 = validateParameter(valid_614805, JString, required = false,
                                 default = nil)
  if valid_614805 != nil:
    section.add "DBSubnetGroupName", valid_614805
  var valid_614806 = formData.getOrDefault("DBClusterIdentifier")
  valid_614806 = validateParameter(valid_614806, JString, required = true,
                                 default = nil)
  if valid_614806 != nil:
    section.add "DBClusterIdentifier", valid_614806
  var valid_614807 = formData.getOrDefault("DeletionProtection")
  valid_614807 = validateParameter(valid_614807, JBool, required = false, default = nil)
  if valid_614807 != nil:
    section.add "DeletionProtection", valid_614807
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614808: Call_PostRestoreDBClusterFromSnapshot_614784;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_614808.validator(path, query, header, formData, body)
  let scheme = call_614808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614808.url(scheme.get, call_614808.host, call_614808.base,
                         call_614808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614808, url, valid)

proc call*(call_614809: Call_PostRestoreDBClusterFromSnapshot_614784;
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
  var query_614810 = newJObject()
  var formData_614811 = newJObject()
  add(formData_614811, "Port", newJInt(Port))
  add(formData_614811, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_614811.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_614811.add "AvailabilityZones", AvailabilityZones
  add(formData_614811, "KmsKeyId", newJString(KmsKeyId))
  add(formData_614811, "Engine", newJString(Engine))
  add(formData_614811, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if EnableCloudwatchLogsExports != nil:
    formData_614811.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_614810, "Action", newJString(Action))
  if Tags != nil:
    formData_614811.add "Tags", Tags
  add(formData_614811, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614810, "Version", newJString(Version))
  add(formData_614811, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_614811, "DeletionProtection", newJBool(DeletionProtection))
  result = call_614809.call(nil, query_614810, nil, formData_614811, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_614784(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_614785, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_614786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_614757 = ref object of OpenApiRestCall_612642
proc url_GetRestoreDBClusterFromSnapshot_614759(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBClusterFromSnapshot_614758(path: JsonNode;
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
  var valid_614760 = query.getOrDefault("DeletionProtection")
  valid_614760 = validateParameter(valid_614760, JBool, required = false, default = nil)
  if valid_614760 != nil:
    section.add "DeletionProtection", valid_614760
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_614761 = query.getOrDefault("Engine")
  valid_614761 = validateParameter(valid_614761, JString, required = true,
                                 default = nil)
  if valid_614761 != nil:
    section.add "Engine", valid_614761
  var valid_614762 = query.getOrDefault("SnapshotIdentifier")
  valid_614762 = validateParameter(valid_614762, JString, required = true,
                                 default = nil)
  if valid_614762 != nil:
    section.add "SnapshotIdentifier", valid_614762
  var valid_614763 = query.getOrDefault("Tags")
  valid_614763 = validateParameter(valid_614763, JArray, required = false,
                                 default = nil)
  if valid_614763 != nil:
    section.add "Tags", valid_614763
  var valid_614764 = query.getOrDefault("KmsKeyId")
  valid_614764 = validateParameter(valid_614764, JString, required = false,
                                 default = nil)
  if valid_614764 != nil:
    section.add "KmsKeyId", valid_614764
  var valid_614765 = query.getOrDefault("DBClusterIdentifier")
  valid_614765 = validateParameter(valid_614765, JString, required = true,
                                 default = nil)
  if valid_614765 != nil:
    section.add "DBClusterIdentifier", valid_614765
  var valid_614766 = query.getOrDefault("AvailabilityZones")
  valid_614766 = validateParameter(valid_614766, JArray, required = false,
                                 default = nil)
  if valid_614766 != nil:
    section.add "AvailabilityZones", valid_614766
  var valid_614767 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_614767 = validateParameter(valid_614767, JArray, required = false,
                                 default = nil)
  if valid_614767 != nil:
    section.add "EnableCloudwatchLogsExports", valid_614767
  var valid_614768 = query.getOrDefault("EngineVersion")
  valid_614768 = validateParameter(valid_614768, JString, required = false,
                                 default = nil)
  if valid_614768 != nil:
    section.add "EngineVersion", valid_614768
  var valid_614769 = query.getOrDefault("Action")
  valid_614769 = validateParameter(valid_614769, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_614769 != nil:
    section.add "Action", valid_614769
  var valid_614770 = query.getOrDefault("Port")
  valid_614770 = validateParameter(valid_614770, JInt, required = false, default = nil)
  if valid_614770 != nil:
    section.add "Port", valid_614770
  var valid_614771 = query.getOrDefault("VpcSecurityGroupIds")
  valid_614771 = validateParameter(valid_614771, JArray, required = false,
                                 default = nil)
  if valid_614771 != nil:
    section.add "VpcSecurityGroupIds", valid_614771
  var valid_614772 = query.getOrDefault("DBSubnetGroupName")
  valid_614772 = validateParameter(valid_614772, JString, required = false,
                                 default = nil)
  if valid_614772 != nil:
    section.add "DBSubnetGroupName", valid_614772
  var valid_614773 = query.getOrDefault("Version")
  valid_614773 = validateParameter(valid_614773, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614773 != nil:
    section.add "Version", valid_614773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614774 = header.getOrDefault("X-Amz-Signature")
  valid_614774 = validateParameter(valid_614774, JString, required = false,
                                 default = nil)
  if valid_614774 != nil:
    section.add "X-Amz-Signature", valid_614774
  var valid_614775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614775 = validateParameter(valid_614775, JString, required = false,
                                 default = nil)
  if valid_614775 != nil:
    section.add "X-Amz-Content-Sha256", valid_614775
  var valid_614776 = header.getOrDefault("X-Amz-Date")
  valid_614776 = validateParameter(valid_614776, JString, required = false,
                                 default = nil)
  if valid_614776 != nil:
    section.add "X-Amz-Date", valid_614776
  var valid_614777 = header.getOrDefault("X-Amz-Credential")
  valid_614777 = validateParameter(valid_614777, JString, required = false,
                                 default = nil)
  if valid_614777 != nil:
    section.add "X-Amz-Credential", valid_614777
  var valid_614778 = header.getOrDefault("X-Amz-Security-Token")
  valid_614778 = validateParameter(valid_614778, JString, required = false,
                                 default = nil)
  if valid_614778 != nil:
    section.add "X-Amz-Security-Token", valid_614778
  var valid_614779 = header.getOrDefault("X-Amz-Algorithm")
  valid_614779 = validateParameter(valid_614779, JString, required = false,
                                 default = nil)
  if valid_614779 != nil:
    section.add "X-Amz-Algorithm", valid_614779
  var valid_614780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614780 = validateParameter(valid_614780, JString, required = false,
                                 default = nil)
  if valid_614780 != nil:
    section.add "X-Amz-SignedHeaders", valid_614780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614781: Call_GetRestoreDBClusterFromSnapshot_614757;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_614781.validator(path, query, header, formData, body)
  let scheme = call_614781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614781.url(scheme.get, call_614781.host, call_614781.base,
                         call_614781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614781, url, valid)

proc call*(call_614782: Call_GetRestoreDBClusterFromSnapshot_614757;
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
  var query_614783 = newJObject()
  add(query_614783, "DeletionProtection", newJBool(DeletionProtection))
  add(query_614783, "Engine", newJString(Engine))
  add(query_614783, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if Tags != nil:
    query_614783.add "Tags", Tags
  add(query_614783, "KmsKeyId", newJString(KmsKeyId))
  add(query_614783, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if AvailabilityZones != nil:
    query_614783.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    query_614783.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_614783, "EngineVersion", newJString(EngineVersion))
  add(query_614783, "Action", newJString(Action))
  add(query_614783, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_614783.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_614783, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614783, "Version", newJString(Version))
  result = call_614782.call(nil, query_614783, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_614757(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_614758, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_614759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_614838 = ref object of OpenApiRestCall_612642
proc url_PostRestoreDBClusterToPointInTime_614840(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBClusterToPointInTime_614839(path: JsonNode;
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
  var valid_614841 = query.getOrDefault("Action")
  valid_614841 = validateParameter(valid_614841, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_614841 != nil:
    section.add "Action", valid_614841
  var valid_614842 = query.getOrDefault("Version")
  valid_614842 = validateParameter(valid_614842, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614842 != nil:
    section.add "Version", valid_614842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614843 = header.getOrDefault("X-Amz-Signature")
  valid_614843 = validateParameter(valid_614843, JString, required = false,
                                 default = nil)
  if valid_614843 != nil:
    section.add "X-Amz-Signature", valid_614843
  var valid_614844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614844 = validateParameter(valid_614844, JString, required = false,
                                 default = nil)
  if valid_614844 != nil:
    section.add "X-Amz-Content-Sha256", valid_614844
  var valid_614845 = header.getOrDefault("X-Amz-Date")
  valid_614845 = validateParameter(valid_614845, JString, required = false,
                                 default = nil)
  if valid_614845 != nil:
    section.add "X-Amz-Date", valid_614845
  var valid_614846 = header.getOrDefault("X-Amz-Credential")
  valid_614846 = validateParameter(valid_614846, JString, required = false,
                                 default = nil)
  if valid_614846 != nil:
    section.add "X-Amz-Credential", valid_614846
  var valid_614847 = header.getOrDefault("X-Amz-Security-Token")
  valid_614847 = validateParameter(valid_614847, JString, required = false,
                                 default = nil)
  if valid_614847 != nil:
    section.add "X-Amz-Security-Token", valid_614847
  var valid_614848 = header.getOrDefault("X-Amz-Algorithm")
  valid_614848 = validateParameter(valid_614848, JString, required = false,
                                 default = nil)
  if valid_614848 != nil:
    section.add "X-Amz-Algorithm", valid_614848
  var valid_614849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614849 = validateParameter(valid_614849, JString, required = false,
                                 default = nil)
  if valid_614849 != nil:
    section.add "X-Amz-SignedHeaders", valid_614849
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
  var valid_614850 = formData.getOrDefault("Port")
  valid_614850 = validateParameter(valid_614850, JInt, required = false, default = nil)
  if valid_614850 != nil:
    section.add "Port", valid_614850
  var valid_614851 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_614851 = validateParameter(valid_614851, JArray, required = false,
                                 default = nil)
  if valid_614851 != nil:
    section.add "VpcSecurityGroupIds", valid_614851
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterIdentifier` field"
  var valid_614852 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_614852 = validateParameter(valid_614852, JString, required = true,
                                 default = nil)
  if valid_614852 != nil:
    section.add "SourceDBClusterIdentifier", valid_614852
  var valid_614853 = formData.getOrDefault("KmsKeyId")
  valid_614853 = validateParameter(valid_614853, JString, required = false,
                                 default = nil)
  if valid_614853 != nil:
    section.add "KmsKeyId", valid_614853
  var valid_614854 = formData.getOrDefault("UseLatestRestorableTime")
  valid_614854 = validateParameter(valid_614854, JBool, required = false, default = nil)
  if valid_614854 != nil:
    section.add "UseLatestRestorableTime", valid_614854
  var valid_614855 = formData.getOrDefault("RestoreToTime")
  valid_614855 = validateParameter(valid_614855, JString, required = false,
                                 default = nil)
  if valid_614855 != nil:
    section.add "RestoreToTime", valid_614855
  var valid_614856 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_614856 = validateParameter(valid_614856, JArray, required = false,
                                 default = nil)
  if valid_614856 != nil:
    section.add "EnableCloudwatchLogsExports", valid_614856
  var valid_614857 = formData.getOrDefault("Tags")
  valid_614857 = validateParameter(valid_614857, JArray, required = false,
                                 default = nil)
  if valid_614857 != nil:
    section.add "Tags", valid_614857
  var valid_614858 = formData.getOrDefault("DBSubnetGroupName")
  valid_614858 = validateParameter(valid_614858, JString, required = false,
                                 default = nil)
  if valid_614858 != nil:
    section.add "DBSubnetGroupName", valid_614858
  var valid_614859 = formData.getOrDefault("DBClusterIdentifier")
  valid_614859 = validateParameter(valid_614859, JString, required = true,
                                 default = nil)
  if valid_614859 != nil:
    section.add "DBClusterIdentifier", valid_614859
  var valid_614860 = formData.getOrDefault("DeletionProtection")
  valid_614860 = validateParameter(valid_614860, JBool, required = false, default = nil)
  if valid_614860 != nil:
    section.add "DeletionProtection", valid_614860
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614861: Call_PostRestoreDBClusterToPointInTime_614838;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_614861.validator(path, query, header, formData, body)
  let scheme = call_614861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614861.url(scheme.get, call_614861.host, call_614861.base,
                         call_614861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614861, url, valid)

proc call*(call_614862: Call_PostRestoreDBClusterToPointInTime_614838;
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
  var query_614863 = newJObject()
  var formData_614864 = newJObject()
  add(formData_614864, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_614864.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_614864, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_614864, "KmsKeyId", newJString(KmsKeyId))
  add(formData_614864, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_614864, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    formData_614864.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_614863, "Action", newJString(Action))
  if Tags != nil:
    formData_614864.add "Tags", Tags
  add(formData_614864, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614863, "Version", newJString(Version))
  add(formData_614864, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_614864, "DeletionProtection", newJBool(DeletionProtection))
  result = call_614862.call(nil, query_614863, nil, formData_614864, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_614838(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_614839, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_614840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_614812 = ref object of OpenApiRestCall_612642
proc url_GetRestoreDBClusterToPointInTime_614814(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBClusterToPointInTime_614813(path: JsonNode;
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
  var valid_614815 = query.getOrDefault("DeletionProtection")
  valid_614815 = validateParameter(valid_614815, JBool, required = false, default = nil)
  if valid_614815 != nil:
    section.add "DeletionProtection", valid_614815
  var valid_614816 = query.getOrDefault("UseLatestRestorableTime")
  valid_614816 = validateParameter(valid_614816, JBool, required = false, default = nil)
  if valid_614816 != nil:
    section.add "UseLatestRestorableTime", valid_614816
  var valid_614817 = query.getOrDefault("Tags")
  valid_614817 = validateParameter(valid_614817, JArray, required = false,
                                 default = nil)
  if valid_614817 != nil:
    section.add "Tags", valid_614817
  var valid_614818 = query.getOrDefault("KmsKeyId")
  valid_614818 = validateParameter(valid_614818, JString, required = false,
                                 default = nil)
  if valid_614818 != nil:
    section.add "KmsKeyId", valid_614818
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_614819 = query.getOrDefault("DBClusterIdentifier")
  valid_614819 = validateParameter(valid_614819, JString, required = true,
                                 default = nil)
  if valid_614819 != nil:
    section.add "DBClusterIdentifier", valid_614819
  var valid_614820 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_614820 = validateParameter(valid_614820, JString, required = true,
                                 default = nil)
  if valid_614820 != nil:
    section.add "SourceDBClusterIdentifier", valid_614820
  var valid_614821 = query.getOrDefault("RestoreToTime")
  valid_614821 = validateParameter(valid_614821, JString, required = false,
                                 default = nil)
  if valid_614821 != nil:
    section.add "RestoreToTime", valid_614821
  var valid_614822 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_614822 = validateParameter(valid_614822, JArray, required = false,
                                 default = nil)
  if valid_614822 != nil:
    section.add "EnableCloudwatchLogsExports", valid_614822
  var valid_614823 = query.getOrDefault("Action")
  valid_614823 = validateParameter(valid_614823, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_614823 != nil:
    section.add "Action", valid_614823
  var valid_614824 = query.getOrDefault("Port")
  valid_614824 = validateParameter(valid_614824, JInt, required = false, default = nil)
  if valid_614824 != nil:
    section.add "Port", valid_614824
  var valid_614825 = query.getOrDefault("VpcSecurityGroupIds")
  valid_614825 = validateParameter(valid_614825, JArray, required = false,
                                 default = nil)
  if valid_614825 != nil:
    section.add "VpcSecurityGroupIds", valid_614825
  var valid_614826 = query.getOrDefault("DBSubnetGroupName")
  valid_614826 = validateParameter(valid_614826, JString, required = false,
                                 default = nil)
  if valid_614826 != nil:
    section.add "DBSubnetGroupName", valid_614826
  var valid_614827 = query.getOrDefault("Version")
  valid_614827 = validateParameter(valid_614827, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614827 != nil:
    section.add "Version", valid_614827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614828 = header.getOrDefault("X-Amz-Signature")
  valid_614828 = validateParameter(valid_614828, JString, required = false,
                                 default = nil)
  if valid_614828 != nil:
    section.add "X-Amz-Signature", valid_614828
  var valid_614829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614829 = validateParameter(valid_614829, JString, required = false,
                                 default = nil)
  if valid_614829 != nil:
    section.add "X-Amz-Content-Sha256", valid_614829
  var valid_614830 = header.getOrDefault("X-Amz-Date")
  valid_614830 = validateParameter(valid_614830, JString, required = false,
                                 default = nil)
  if valid_614830 != nil:
    section.add "X-Amz-Date", valid_614830
  var valid_614831 = header.getOrDefault("X-Amz-Credential")
  valid_614831 = validateParameter(valid_614831, JString, required = false,
                                 default = nil)
  if valid_614831 != nil:
    section.add "X-Amz-Credential", valid_614831
  var valid_614832 = header.getOrDefault("X-Amz-Security-Token")
  valid_614832 = validateParameter(valid_614832, JString, required = false,
                                 default = nil)
  if valid_614832 != nil:
    section.add "X-Amz-Security-Token", valid_614832
  var valid_614833 = header.getOrDefault("X-Amz-Algorithm")
  valid_614833 = validateParameter(valid_614833, JString, required = false,
                                 default = nil)
  if valid_614833 != nil:
    section.add "X-Amz-Algorithm", valid_614833
  var valid_614834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614834 = validateParameter(valid_614834, JString, required = false,
                                 default = nil)
  if valid_614834 != nil:
    section.add "X-Amz-SignedHeaders", valid_614834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614835: Call_GetRestoreDBClusterToPointInTime_614812;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_614835.validator(path, query, header, formData, body)
  let scheme = call_614835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614835.url(scheme.get, call_614835.host, call_614835.base,
                         call_614835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614835, url, valid)

proc call*(call_614836: Call_GetRestoreDBClusterToPointInTime_614812;
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
  var query_614837 = newJObject()
  add(query_614837, "DeletionProtection", newJBool(DeletionProtection))
  add(query_614837, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_614837.add "Tags", Tags
  add(query_614837, "KmsKeyId", newJString(KmsKeyId))
  add(query_614837, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_614837, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_614837, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    query_614837.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_614837, "Action", newJString(Action))
  add(query_614837, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_614837.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_614837, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614837, "Version", newJString(Version))
  result = call_614836.call(nil, query_614837, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_614812(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_614813, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_614814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_614881 = ref object of OpenApiRestCall_612642
proc url_PostStartDBCluster_614883(protocol: Scheme; host: string; base: string;
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

proc validate_PostStartDBCluster_614882(path: JsonNode; query: JsonNode;
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
  var valid_614884 = query.getOrDefault("Action")
  valid_614884 = validateParameter(valid_614884, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_614884 != nil:
    section.add "Action", valid_614884
  var valid_614885 = query.getOrDefault("Version")
  valid_614885 = validateParameter(valid_614885, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614885 != nil:
    section.add "Version", valid_614885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614886 = header.getOrDefault("X-Amz-Signature")
  valid_614886 = validateParameter(valid_614886, JString, required = false,
                                 default = nil)
  if valid_614886 != nil:
    section.add "X-Amz-Signature", valid_614886
  var valid_614887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614887 = validateParameter(valid_614887, JString, required = false,
                                 default = nil)
  if valid_614887 != nil:
    section.add "X-Amz-Content-Sha256", valid_614887
  var valid_614888 = header.getOrDefault("X-Amz-Date")
  valid_614888 = validateParameter(valid_614888, JString, required = false,
                                 default = nil)
  if valid_614888 != nil:
    section.add "X-Amz-Date", valid_614888
  var valid_614889 = header.getOrDefault("X-Amz-Credential")
  valid_614889 = validateParameter(valid_614889, JString, required = false,
                                 default = nil)
  if valid_614889 != nil:
    section.add "X-Amz-Credential", valid_614889
  var valid_614890 = header.getOrDefault("X-Amz-Security-Token")
  valid_614890 = validateParameter(valid_614890, JString, required = false,
                                 default = nil)
  if valid_614890 != nil:
    section.add "X-Amz-Security-Token", valid_614890
  var valid_614891 = header.getOrDefault("X-Amz-Algorithm")
  valid_614891 = validateParameter(valid_614891, JString, required = false,
                                 default = nil)
  if valid_614891 != nil:
    section.add "X-Amz-Algorithm", valid_614891
  var valid_614892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614892 = validateParameter(valid_614892, JString, required = false,
                                 default = nil)
  if valid_614892 != nil:
    section.add "X-Amz-SignedHeaders", valid_614892
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_614893 = formData.getOrDefault("DBClusterIdentifier")
  valid_614893 = validateParameter(valid_614893, JString, required = true,
                                 default = nil)
  if valid_614893 != nil:
    section.add "DBClusterIdentifier", valid_614893
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614894: Call_PostStartDBCluster_614881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_614894.validator(path, query, header, formData, body)
  let scheme = call_614894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614894.url(scheme.get, call_614894.host, call_614894.base,
                         call_614894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614894, url, valid)

proc call*(call_614895: Call_PostStartDBCluster_614881;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_614896 = newJObject()
  var formData_614897 = newJObject()
  add(query_614896, "Action", newJString(Action))
  add(query_614896, "Version", newJString(Version))
  add(formData_614897, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_614895.call(nil, query_614896, nil, formData_614897, nil)

var postStartDBCluster* = Call_PostStartDBCluster_614881(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_614882, base: "/",
    url: url_PostStartDBCluster_614883, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_614865 = ref object of OpenApiRestCall_612642
proc url_GetStartDBCluster_614867(protocol: Scheme; host: string; base: string;
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

proc validate_GetStartDBCluster_614866(path: JsonNode; query: JsonNode;
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
  var valid_614868 = query.getOrDefault("DBClusterIdentifier")
  valid_614868 = validateParameter(valid_614868, JString, required = true,
                                 default = nil)
  if valid_614868 != nil:
    section.add "DBClusterIdentifier", valid_614868
  var valid_614869 = query.getOrDefault("Action")
  valid_614869 = validateParameter(valid_614869, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_614869 != nil:
    section.add "Action", valid_614869
  var valid_614870 = query.getOrDefault("Version")
  valid_614870 = validateParameter(valid_614870, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614870 != nil:
    section.add "Version", valid_614870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614871 = header.getOrDefault("X-Amz-Signature")
  valid_614871 = validateParameter(valid_614871, JString, required = false,
                                 default = nil)
  if valid_614871 != nil:
    section.add "X-Amz-Signature", valid_614871
  var valid_614872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614872 = validateParameter(valid_614872, JString, required = false,
                                 default = nil)
  if valid_614872 != nil:
    section.add "X-Amz-Content-Sha256", valid_614872
  var valid_614873 = header.getOrDefault("X-Amz-Date")
  valid_614873 = validateParameter(valid_614873, JString, required = false,
                                 default = nil)
  if valid_614873 != nil:
    section.add "X-Amz-Date", valid_614873
  var valid_614874 = header.getOrDefault("X-Amz-Credential")
  valid_614874 = validateParameter(valid_614874, JString, required = false,
                                 default = nil)
  if valid_614874 != nil:
    section.add "X-Amz-Credential", valid_614874
  var valid_614875 = header.getOrDefault("X-Amz-Security-Token")
  valid_614875 = validateParameter(valid_614875, JString, required = false,
                                 default = nil)
  if valid_614875 != nil:
    section.add "X-Amz-Security-Token", valid_614875
  var valid_614876 = header.getOrDefault("X-Amz-Algorithm")
  valid_614876 = validateParameter(valid_614876, JString, required = false,
                                 default = nil)
  if valid_614876 != nil:
    section.add "X-Amz-Algorithm", valid_614876
  var valid_614877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614877 = validateParameter(valid_614877, JString, required = false,
                                 default = nil)
  if valid_614877 != nil:
    section.add "X-Amz-SignedHeaders", valid_614877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614878: Call_GetStartDBCluster_614865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_614878.validator(path, query, header, formData, body)
  let scheme = call_614878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614878.url(scheme.get, call_614878.host, call_614878.base,
                         call_614878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614878, url, valid)

proc call*(call_614879: Call_GetStartDBCluster_614865; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614880 = newJObject()
  add(query_614880, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_614880, "Action", newJString(Action))
  add(query_614880, "Version", newJString(Version))
  result = call_614879.call(nil, query_614880, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_614865(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_614866,
    base: "/", url: url_GetStartDBCluster_614867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_614914 = ref object of OpenApiRestCall_612642
proc url_PostStopDBCluster_614916(protocol: Scheme; host: string; base: string;
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

proc validate_PostStopDBCluster_614915(path: JsonNode; query: JsonNode;
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
  var valid_614917 = query.getOrDefault("Action")
  valid_614917 = validateParameter(valid_614917, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_614917 != nil:
    section.add "Action", valid_614917
  var valid_614918 = query.getOrDefault("Version")
  valid_614918 = validateParameter(valid_614918, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614918 != nil:
    section.add "Version", valid_614918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614919 = header.getOrDefault("X-Amz-Signature")
  valid_614919 = validateParameter(valid_614919, JString, required = false,
                                 default = nil)
  if valid_614919 != nil:
    section.add "X-Amz-Signature", valid_614919
  var valid_614920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614920 = validateParameter(valid_614920, JString, required = false,
                                 default = nil)
  if valid_614920 != nil:
    section.add "X-Amz-Content-Sha256", valid_614920
  var valid_614921 = header.getOrDefault("X-Amz-Date")
  valid_614921 = validateParameter(valid_614921, JString, required = false,
                                 default = nil)
  if valid_614921 != nil:
    section.add "X-Amz-Date", valid_614921
  var valid_614922 = header.getOrDefault("X-Amz-Credential")
  valid_614922 = validateParameter(valid_614922, JString, required = false,
                                 default = nil)
  if valid_614922 != nil:
    section.add "X-Amz-Credential", valid_614922
  var valid_614923 = header.getOrDefault("X-Amz-Security-Token")
  valid_614923 = validateParameter(valid_614923, JString, required = false,
                                 default = nil)
  if valid_614923 != nil:
    section.add "X-Amz-Security-Token", valid_614923
  var valid_614924 = header.getOrDefault("X-Amz-Algorithm")
  valid_614924 = validateParameter(valid_614924, JString, required = false,
                                 default = nil)
  if valid_614924 != nil:
    section.add "X-Amz-Algorithm", valid_614924
  var valid_614925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614925 = validateParameter(valid_614925, JString, required = false,
                                 default = nil)
  if valid_614925 != nil:
    section.add "X-Amz-SignedHeaders", valid_614925
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_614926 = formData.getOrDefault("DBClusterIdentifier")
  valid_614926 = validateParameter(valid_614926, JString, required = true,
                                 default = nil)
  if valid_614926 != nil:
    section.add "DBClusterIdentifier", valid_614926
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614927: Call_PostStopDBCluster_614914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_614927.validator(path, query, header, formData, body)
  let scheme = call_614927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614927.url(scheme.get, call_614927.host, call_614927.base,
                         call_614927.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614927, url, valid)

proc call*(call_614928: Call_PostStopDBCluster_614914; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_614929 = newJObject()
  var formData_614930 = newJObject()
  add(query_614929, "Action", newJString(Action))
  add(query_614929, "Version", newJString(Version))
  add(formData_614930, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_614928.call(nil, query_614929, nil, formData_614930, nil)

var postStopDBCluster* = Call_PostStopDBCluster_614914(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_614915,
    base: "/", url: url_PostStopDBCluster_614916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_614898 = ref object of OpenApiRestCall_612642
proc url_GetStopDBCluster_614900(protocol: Scheme; host: string; base: string;
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

proc validate_GetStopDBCluster_614899(path: JsonNode; query: JsonNode;
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
  var valid_614901 = query.getOrDefault("DBClusterIdentifier")
  valid_614901 = validateParameter(valid_614901, JString, required = true,
                                 default = nil)
  if valid_614901 != nil:
    section.add "DBClusterIdentifier", valid_614901
  var valid_614902 = query.getOrDefault("Action")
  valid_614902 = validateParameter(valid_614902, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_614902 != nil:
    section.add "Action", valid_614902
  var valid_614903 = query.getOrDefault("Version")
  valid_614903 = validateParameter(valid_614903, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_614903 != nil:
    section.add "Version", valid_614903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614904 = header.getOrDefault("X-Amz-Signature")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "X-Amz-Signature", valid_614904
  var valid_614905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614905 = validateParameter(valid_614905, JString, required = false,
                                 default = nil)
  if valid_614905 != nil:
    section.add "X-Amz-Content-Sha256", valid_614905
  var valid_614906 = header.getOrDefault("X-Amz-Date")
  valid_614906 = validateParameter(valid_614906, JString, required = false,
                                 default = nil)
  if valid_614906 != nil:
    section.add "X-Amz-Date", valid_614906
  var valid_614907 = header.getOrDefault("X-Amz-Credential")
  valid_614907 = validateParameter(valid_614907, JString, required = false,
                                 default = nil)
  if valid_614907 != nil:
    section.add "X-Amz-Credential", valid_614907
  var valid_614908 = header.getOrDefault("X-Amz-Security-Token")
  valid_614908 = validateParameter(valid_614908, JString, required = false,
                                 default = nil)
  if valid_614908 != nil:
    section.add "X-Amz-Security-Token", valid_614908
  var valid_614909 = header.getOrDefault("X-Amz-Algorithm")
  valid_614909 = validateParameter(valid_614909, JString, required = false,
                                 default = nil)
  if valid_614909 != nil:
    section.add "X-Amz-Algorithm", valid_614909
  var valid_614910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614910 = validateParameter(valid_614910, JString, required = false,
                                 default = nil)
  if valid_614910 != nil:
    section.add "X-Amz-SignedHeaders", valid_614910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614911: Call_GetStopDBCluster_614898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_614911.validator(path, query, header, formData, body)
  let scheme = call_614911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614911.url(scheme.get, call_614911.host, call_614911.base,
                         call_614911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614911, url, valid)

proc call*(call_614912: Call_GetStopDBCluster_614898; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614913 = newJObject()
  add(query_614913, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_614913, "Action", newJString(Action))
  add(query_614913, "Version", newJString(Version))
  result = call_614912.call(nil, query_614913, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_614898(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_614899,
    base: "/", url: url_GetStopDBCluster_614900,
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

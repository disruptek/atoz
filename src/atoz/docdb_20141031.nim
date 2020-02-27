
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616850 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616850](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616850): Option[Scheme] {.used.} =
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
                           "us-east-1": "rds.us-east-1.amazonaws.com", "cn-northwest-1": "rds.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "rds.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "rds.ap-south-1.amazonaws.com",
                           "eu-north-1": "rds.eu-north-1.amazonaws.com",
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
      "ap-northeast-2": "rds.ap-northeast-2.amazonaws.com",
      "ap-south-1": "rds.ap-south-1.amazonaws.com",
      "eu-north-1": "rds.eu-north-1.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostAddTagsToResource_617464 = ref object of OpenApiRestCall_616850
proc url_PostAddTagsToResource_617466(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTagsToResource_617465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617467 = query.getOrDefault("Action")
  valid_617467 = validateParameter(valid_617467, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_617467 != nil:
    section.add "Action", valid_617467
  var valid_617468 = query.getOrDefault("Version")
  valid_617468 = validateParameter(valid_617468, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617468 != nil:
    section.add "Version", valid_617468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617469 = header.getOrDefault("X-Amz-Date")
  valid_617469 = validateParameter(valid_617469, JString, required = false,
                                 default = nil)
  if valid_617469 != nil:
    section.add "X-Amz-Date", valid_617469
  var valid_617470 = header.getOrDefault("X-Amz-Security-Token")
  valid_617470 = validateParameter(valid_617470, JString, required = false,
                                 default = nil)
  if valid_617470 != nil:
    section.add "X-Amz-Security-Token", valid_617470
  var valid_617471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617471 = validateParameter(valid_617471, JString, required = false,
                                 default = nil)
  if valid_617471 != nil:
    section.add "X-Amz-Content-Sha256", valid_617471
  var valid_617472 = header.getOrDefault("X-Amz-Algorithm")
  valid_617472 = validateParameter(valid_617472, JString, required = false,
                                 default = nil)
  if valid_617472 != nil:
    section.add "X-Amz-Algorithm", valid_617472
  var valid_617473 = header.getOrDefault("X-Amz-Signature")
  valid_617473 = validateParameter(valid_617473, JString, required = false,
                                 default = nil)
  if valid_617473 != nil:
    section.add "X-Amz-Signature", valid_617473
  var valid_617474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617474 = validateParameter(valid_617474, JString, required = false,
                                 default = nil)
  if valid_617474 != nil:
    section.add "X-Amz-SignedHeaders", valid_617474
  var valid_617475 = header.getOrDefault("X-Amz-Credential")
  valid_617475 = validateParameter(valid_617475, JString, required = false,
                                 default = nil)
  if valid_617475 != nil:
    section.add "X-Amz-Credential", valid_617475
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_617476 = formData.getOrDefault("Tags")
  valid_617476 = validateParameter(valid_617476, JArray, required = true, default = nil)
  if valid_617476 != nil:
    section.add "Tags", valid_617476
  var valid_617477 = formData.getOrDefault("ResourceName")
  valid_617477 = validateParameter(valid_617477, JString, required = true,
                                 default = nil)
  if valid_617477 != nil:
    section.add "ResourceName", valid_617477
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617478: Call_PostAddTagsToResource_617464; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_617478.validator(path, query, header, formData, body, _)
  let scheme = call_617478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617478.url(scheme.get, call_617478.host, call_617478.base,
                         call_617478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617478, url, valid, _)

proc call*(call_617479: Call_PostAddTagsToResource_617464; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-10-31"): Recallable =
  ## postAddTagsToResource
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_617480 = newJObject()
  var formData_617481 = newJObject()
  if Tags != nil:
    formData_617481.add "Tags", Tags
  add(query_617480, "Action", newJString(Action))
  add(formData_617481, "ResourceName", newJString(ResourceName))
  add(query_617480, "Version", newJString(Version))
  result = call_617479.call(nil, query_617480, nil, formData_617481, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_617464(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_617465, base: "/",
    url: url_PostAddTagsToResource_617466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_617189 = ref object of OpenApiRestCall_616850
proc url_GetAddTagsToResource_617191(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTagsToResource_617190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   Action: JString (required)
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_617303 = query.getOrDefault("Tags")
  valid_617303 = validateParameter(valid_617303, JArray, required = true, default = nil)
  if valid_617303 != nil:
    section.add "Tags", valid_617303
  var valid_617317 = query.getOrDefault("Action")
  valid_617317 = validateParameter(valid_617317, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_617317 != nil:
    section.add "Action", valid_617317
  var valid_617318 = query.getOrDefault("ResourceName")
  valid_617318 = validateParameter(valid_617318, JString, required = true,
                                 default = nil)
  if valid_617318 != nil:
    section.add "ResourceName", valid_617318
  var valid_617319 = query.getOrDefault("Version")
  valid_617319 = validateParameter(valid_617319, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617319 != nil:
    section.add "Version", valid_617319
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617320 = header.getOrDefault("X-Amz-Date")
  valid_617320 = validateParameter(valid_617320, JString, required = false,
                                 default = nil)
  if valid_617320 != nil:
    section.add "X-Amz-Date", valid_617320
  var valid_617321 = header.getOrDefault("X-Amz-Security-Token")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "X-Amz-Security-Token", valid_617321
  var valid_617322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "X-Amz-Content-Sha256", valid_617322
  var valid_617323 = header.getOrDefault("X-Amz-Algorithm")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Algorithm", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-Signature")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-Signature", valid_617324
  var valid_617325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617325 = validateParameter(valid_617325, JString, required = false,
                                 default = nil)
  if valid_617325 != nil:
    section.add "X-Amz-SignedHeaders", valid_617325
  var valid_617326 = header.getOrDefault("X-Amz-Credential")
  valid_617326 = validateParameter(valid_617326, JString, required = false,
                                 default = nil)
  if valid_617326 != nil:
    section.add "X-Amz-Credential", valid_617326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617350: Call_GetAddTagsToResource_617189; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_617350.validator(path, query, header, formData, body, _)
  let scheme = call_617350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617350.url(scheme.get, call_617350.host, call_617350.base,
                         call_617350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617350, url, valid, _)

proc call*(call_617421: Call_GetAddTagsToResource_617189; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-10-31"): Recallable =
  ## getAddTagsToResource
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_617422 = newJObject()
  if Tags != nil:
    query_617422.add "Tags", Tags
  add(query_617422, "Action", newJString(Action))
  add(query_617422, "ResourceName", newJString(ResourceName))
  add(query_617422, "Version", newJString(Version))
  result = call_617421.call(nil, query_617422, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_617189(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_617190, base: "/",
    url: url_GetAddTagsToResource_617191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_617500 = ref object of OpenApiRestCall_616850
proc url_PostApplyPendingMaintenanceAction_617502(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplyPendingMaintenanceAction_617501(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_617503 = query.getOrDefault("Action")
  valid_617503 = validateParameter(valid_617503, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_617503 != nil:
    section.add "Action", valid_617503
  var valid_617504 = query.getOrDefault("Version")
  valid_617504 = validateParameter(valid_617504, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617504 != nil:
    section.add "Version", valid_617504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617505 = header.getOrDefault("X-Amz-Date")
  valid_617505 = validateParameter(valid_617505, JString, required = false,
                                 default = nil)
  if valid_617505 != nil:
    section.add "X-Amz-Date", valid_617505
  var valid_617506 = header.getOrDefault("X-Amz-Security-Token")
  valid_617506 = validateParameter(valid_617506, JString, required = false,
                                 default = nil)
  if valid_617506 != nil:
    section.add "X-Amz-Security-Token", valid_617506
  var valid_617507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617507 = validateParameter(valid_617507, JString, required = false,
                                 default = nil)
  if valid_617507 != nil:
    section.add "X-Amz-Content-Sha256", valid_617507
  var valid_617508 = header.getOrDefault("X-Amz-Algorithm")
  valid_617508 = validateParameter(valid_617508, JString, required = false,
                                 default = nil)
  if valid_617508 != nil:
    section.add "X-Amz-Algorithm", valid_617508
  var valid_617509 = header.getOrDefault("X-Amz-Signature")
  valid_617509 = validateParameter(valid_617509, JString, required = false,
                                 default = nil)
  if valid_617509 != nil:
    section.add "X-Amz-Signature", valid_617509
  var valid_617510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617510 = validateParameter(valid_617510, JString, required = false,
                                 default = nil)
  if valid_617510 != nil:
    section.add "X-Amz-SignedHeaders", valid_617510
  var valid_617511 = header.getOrDefault("X-Amz-Credential")
  valid_617511 = validateParameter(valid_617511, JString, required = false,
                                 default = nil)
  if valid_617511 != nil:
    section.add "X-Amz-Credential", valid_617511
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplyAction: JString (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   ResourceIdentifier: JString (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   OptInType: JString (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ApplyAction` field"
  var valid_617512 = formData.getOrDefault("ApplyAction")
  valid_617512 = validateParameter(valid_617512, JString, required = true,
                                 default = nil)
  if valid_617512 != nil:
    section.add "ApplyAction", valid_617512
  var valid_617513 = formData.getOrDefault("ResourceIdentifier")
  valid_617513 = validateParameter(valid_617513, JString, required = true,
                                 default = nil)
  if valid_617513 != nil:
    section.add "ResourceIdentifier", valid_617513
  var valid_617514 = formData.getOrDefault("OptInType")
  valid_617514 = validateParameter(valid_617514, JString, required = true,
                                 default = nil)
  if valid_617514 != nil:
    section.add "OptInType", valid_617514
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617515: Call_PostApplyPendingMaintenanceAction_617500;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_617515.validator(path, query, header, formData, body, _)
  let scheme = call_617515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617515.url(scheme.get, call_617515.host, call_617515.base,
                         call_617515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617515, url, valid, _)

proc call*(call_617516: Call_PostApplyPendingMaintenanceAction_617500;
          ApplyAction: string; ResourceIdentifier: string; OptInType: string;
          Action: string = "ApplyPendingMaintenanceAction";
          Version: string = "2014-10-31"): Recallable =
  ## postApplyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ##   Action: string (required)
  ##   ApplyAction: string (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   ResourceIdentifier: string (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   OptInType: string (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  ##   Version: string (required)
  var query_617517 = newJObject()
  var formData_617518 = newJObject()
  add(query_617517, "Action", newJString(Action))
  add(formData_617518, "ApplyAction", newJString(ApplyAction))
  add(formData_617518, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_617518, "OptInType", newJString(OptInType))
  add(query_617517, "Version", newJString(Version))
  result = call_617516.call(nil, query_617517, nil, formData_617518, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_617500(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_617501, base: "/",
    url: url_PostApplyPendingMaintenanceAction_617502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_617482 = ref object of OpenApiRestCall_616850
proc url_GetApplyPendingMaintenanceAction_617484(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplyPendingMaintenanceAction_617483(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplyAction: JString (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   ResourceIdentifier: JString (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   Action: JString (required)
  ##   OptInType: JString (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplyAction` field"
  var valid_617485 = query.getOrDefault("ApplyAction")
  valid_617485 = validateParameter(valid_617485, JString, required = true,
                                 default = nil)
  if valid_617485 != nil:
    section.add "ApplyAction", valid_617485
  var valid_617486 = query.getOrDefault("ResourceIdentifier")
  valid_617486 = validateParameter(valid_617486, JString, required = true,
                                 default = nil)
  if valid_617486 != nil:
    section.add "ResourceIdentifier", valid_617486
  var valid_617487 = query.getOrDefault("Action")
  valid_617487 = validateParameter(valid_617487, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_617487 != nil:
    section.add "Action", valid_617487
  var valid_617488 = query.getOrDefault("OptInType")
  valid_617488 = validateParameter(valid_617488, JString, required = true,
                                 default = nil)
  if valid_617488 != nil:
    section.add "OptInType", valid_617488
  var valid_617489 = query.getOrDefault("Version")
  valid_617489 = validateParameter(valid_617489, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617489 != nil:
    section.add "Version", valid_617489
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617490 = header.getOrDefault("X-Amz-Date")
  valid_617490 = validateParameter(valid_617490, JString, required = false,
                                 default = nil)
  if valid_617490 != nil:
    section.add "X-Amz-Date", valid_617490
  var valid_617491 = header.getOrDefault("X-Amz-Security-Token")
  valid_617491 = validateParameter(valid_617491, JString, required = false,
                                 default = nil)
  if valid_617491 != nil:
    section.add "X-Amz-Security-Token", valid_617491
  var valid_617492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617492 = validateParameter(valid_617492, JString, required = false,
                                 default = nil)
  if valid_617492 != nil:
    section.add "X-Amz-Content-Sha256", valid_617492
  var valid_617493 = header.getOrDefault("X-Amz-Algorithm")
  valid_617493 = validateParameter(valid_617493, JString, required = false,
                                 default = nil)
  if valid_617493 != nil:
    section.add "X-Amz-Algorithm", valid_617493
  var valid_617494 = header.getOrDefault("X-Amz-Signature")
  valid_617494 = validateParameter(valid_617494, JString, required = false,
                                 default = nil)
  if valid_617494 != nil:
    section.add "X-Amz-Signature", valid_617494
  var valid_617495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617495 = validateParameter(valid_617495, JString, required = false,
                                 default = nil)
  if valid_617495 != nil:
    section.add "X-Amz-SignedHeaders", valid_617495
  var valid_617496 = header.getOrDefault("X-Amz-Credential")
  valid_617496 = validateParameter(valid_617496, JString, required = false,
                                 default = nil)
  if valid_617496 != nil:
    section.add "X-Amz-Credential", valid_617496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617497: Call_GetApplyPendingMaintenanceAction_617482;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_617497.validator(path, query, header, formData, body, _)
  let scheme = call_617497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617497.url(scheme.get, call_617497.host, call_617497.base,
                         call_617497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617497, url, valid, _)

proc call*(call_617498: Call_GetApplyPendingMaintenanceAction_617482;
          ApplyAction: string; ResourceIdentifier: string; OptInType: string;
          Action: string = "ApplyPendingMaintenanceAction";
          Version: string = "2014-10-31"): Recallable =
  ## getApplyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ##   ApplyAction: string (required)
  ##              : <p>The pending maintenance action to apply to this resource.</p> <p>Valid values: <code>system-update</code>, <code>db-upgrade</code> </p>
  ##   ResourceIdentifier: string (required)
  ##                     : The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to.
  ##   Action: string (required)
  ##   OptInType: string (required)
  ##            : <p>A value that specifies the type of opt-in request or undoes an opt-in request. An opt-in request of type <code>immediate</code> can't be undone.</p> <p>Valid values:</p> <ul> <li> <p> <code>immediate</code> - Apply the maintenance action immediately.</p> </li> <li> <p> <code>next-maintenance</code> - Apply the maintenance action during the next maintenance window for the resource.</p> </li> <li> <p> <code>undo-opt-in</code> - Cancel any existing <code>next-maintenance</code> opt-in requests.</p> </li> </ul>
  ##   Version: string (required)
  var query_617499 = newJObject()
  add(query_617499, "ApplyAction", newJString(ApplyAction))
  add(query_617499, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_617499, "Action", newJString(Action))
  add(query_617499, "OptInType", newJString(OptInType))
  add(query_617499, "Version", newJString(Version))
  result = call_617498.call(nil, query_617499, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_617482(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_617483, base: "/",
    url: url_GetApplyPendingMaintenanceAction_617484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_617538 = ref object of OpenApiRestCall_616850
proc url_PostCopyDBClusterParameterGroup_617540(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBClusterParameterGroup_617539(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_617541 = query.getOrDefault("Action")
  valid_617541 = validateParameter(valid_617541, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_617541 != nil:
    section.add "Action", valid_617541
  var valid_617542 = query.getOrDefault("Version")
  valid_617542 = validateParameter(valid_617542, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617542 != nil:
    section.add "Version", valid_617542
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617543 = header.getOrDefault("X-Amz-Date")
  valid_617543 = validateParameter(valid_617543, JString, required = false,
                                 default = nil)
  if valid_617543 != nil:
    section.add "X-Amz-Date", valid_617543
  var valid_617544 = header.getOrDefault("X-Amz-Security-Token")
  valid_617544 = validateParameter(valid_617544, JString, required = false,
                                 default = nil)
  if valid_617544 != nil:
    section.add "X-Amz-Security-Token", valid_617544
  var valid_617545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "X-Amz-Content-Sha256", valid_617545
  var valid_617546 = header.getOrDefault("X-Amz-Algorithm")
  valid_617546 = validateParameter(valid_617546, JString, required = false,
                                 default = nil)
  if valid_617546 != nil:
    section.add "X-Amz-Algorithm", valid_617546
  var valid_617547 = header.getOrDefault("X-Amz-Signature")
  valid_617547 = validateParameter(valid_617547, JString, required = false,
                                 default = nil)
  if valid_617547 != nil:
    section.add "X-Amz-Signature", valid_617547
  var valid_617548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617548 = validateParameter(valid_617548, JString, required = false,
                                 default = nil)
  if valid_617548 != nil:
    section.add "X-Amz-SignedHeaders", valid_617548
  var valid_617549 = header.getOrDefault("X-Amz-Credential")
  valid_617549 = validateParameter(valid_617549, JString, required = false,
                                 default = nil)
  if valid_617549 != nil:
    section.add "X-Amz-Credential", valid_617549
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid cluster parameter group.</p> </li> <li> <p>If the source cluster parameter group is in the same AWS Region as the copy, specify a valid parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source parameter group is in a different AWS Region than the copy, specify a valid cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBClusterParameterGroupDescription` field"
  var valid_617550 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_617550 = validateParameter(valid_617550, JString, required = true,
                                 default = nil)
  if valid_617550 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_617550
  var valid_617551 = formData.getOrDefault("Tags")
  valid_617551 = validateParameter(valid_617551, JArray, required = false,
                                 default = nil)
  if valid_617551 != nil:
    section.add "Tags", valid_617551
  var valid_617552 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_617552 = validateParameter(valid_617552, JString, required = true,
                                 default = nil)
  if valid_617552 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_617552
  var valid_617553 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_617553 = validateParameter(valid_617553, JString, required = true,
                                 default = nil)
  if valid_617553 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_617553
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617554: Call_PostCopyDBClusterParameterGroup_617538;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Copies the specified cluster parameter group.
  ## 
  let valid = call_617554.validator(path, query, header, formData, body, _)
  let scheme = call_617554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617554.url(scheme.get, call_617554.host, call_617554.base,
                         call_617554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617554, url, valid, _)

proc call*(call_617555: Call_PostCopyDBClusterParameterGroup_617538;
          TargetDBClusterParameterGroupDescription: string;
          SourceDBClusterParameterGroupIdentifier: string;
          TargetDBClusterParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterParameterGroup
  ## Copies the specified cluster parameter group.
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   Action: string (required)
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid cluster parameter group.</p> </li> <li> <p>If the source cluster parameter group is in the same AWS Region as the copy, specify a valid parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source parameter group is in a different AWS Region than the copy, specify a valid cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Version: string (required)
  var query_617556 = newJObject()
  var formData_617557 = newJObject()
  add(formData_617557, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    formData_617557.add "Tags", Tags
  add(query_617556, "Action", newJString(Action))
  add(formData_617557, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(formData_617557, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_617556, "Version", newJString(Version))
  result = call_617555.call(nil, query_617556, nil, formData_617557, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_617538(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_617539, base: "/",
    url: url_PostCopyDBClusterParameterGroup_617540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_617519 = ref object of OpenApiRestCall_616850
proc url_GetCopyDBClusterParameterGroup_617521(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBClusterParameterGroup_617520(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Copies the specified cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid cluster parameter group.</p> </li> <li> <p>If the source cluster parameter group is in the same AWS Region as the copy, specify a valid parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source parameter group is in a different AWS Region than the copy, specify a valid cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied cluster parameter group.
  ##   Action: JString (required)
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBClusterParameterGroupIdentifier` field"
  var valid_617522 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_617522 = validateParameter(valid_617522, JString, required = true,
                                 default = nil)
  if valid_617522 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_617522
  var valid_617523 = query.getOrDefault("Tags")
  valid_617523 = validateParameter(valid_617523, JArray, required = false,
                                 default = nil)
  if valid_617523 != nil:
    section.add "Tags", valid_617523
  var valid_617524 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_617524 = validateParameter(valid_617524, JString, required = true,
                                 default = nil)
  if valid_617524 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_617524
  var valid_617525 = query.getOrDefault("Action")
  valid_617525 = validateParameter(valid_617525, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_617525 != nil:
    section.add "Action", valid_617525
  var valid_617526 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_617526 = validateParameter(valid_617526, JString, required = true,
                                 default = nil)
  if valid_617526 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_617526
  var valid_617527 = query.getOrDefault("Version")
  valid_617527 = validateParameter(valid_617527, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617527 != nil:
    section.add "Version", valid_617527
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617528 = header.getOrDefault("X-Amz-Date")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Date", valid_617528
  var valid_617529 = header.getOrDefault("X-Amz-Security-Token")
  valid_617529 = validateParameter(valid_617529, JString, required = false,
                                 default = nil)
  if valid_617529 != nil:
    section.add "X-Amz-Security-Token", valid_617529
  var valid_617530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617530 = validateParameter(valid_617530, JString, required = false,
                                 default = nil)
  if valid_617530 != nil:
    section.add "X-Amz-Content-Sha256", valid_617530
  var valid_617531 = header.getOrDefault("X-Amz-Algorithm")
  valid_617531 = validateParameter(valid_617531, JString, required = false,
                                 default = nil)
  if valid_617531 != nil:
    section.add "X-Amz-Algorithm", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-Signature")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-Signature", valid_617532
  var valid_617533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617533 = validateParameter(valid_617533, JString, required = false,
                                 default = nil)
  if valid_617533 != nil:
    section.add "X-Amz-SignedHeaders", valid_617533
  var valid_617534 = header.getOrDefault("X-Amz-Credential")
  valid_617534 = validateParameter(valid_617534, JString, required = false,
                                 default = nil)
  if valid_617534 != nil:
    section.add "X-Amz-Credential", valid_617534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617535: Call_GetCopyDBClusterParameterGroup_617519;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Copies the specified cluster parameter group.
  ## 
  let valid = call_617535.validator(path, query, header, formData, body, _)
  let scheme = call_617535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617535.url(scheme.get, call_617535.host, call_617535.base,
                         call_617535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617535, url, valid, _)

proc call*(call_617536: Call_GetCopyDBClusterParameterGroup_617519;
          SourceDBClusterParameterGroupIdentifier: string;
          TargetDBClusterParameterGroupDescription: string;
          TargetDBClusterParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCopyDBClusterParameterGroup
  ## Copies the specified cluster parameter group.
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid cluster parameter group.</p> </li> <li> <p>If the source cluster parameter group is in the same AWS Region as the copy, specify a valid parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source parameter group is in a different AWS Region than the copy, specify a valid cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied cluster parameter group.
  ##   Action: string (required)
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Version: string (required)
  var query_617537 = newJObject()
  add(query_617537, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  if Tags != nil:
    query_617537.add "Tags", Tags
  add(query_617537, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  add(query_617537, "Action", newJString(Action))
  add(query_617537, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_617537, "Version", newJString(Version))
  result = call_617536.call(nil, query_617537, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_617519(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_617520, base: "/",
    url: url_GetCopyDBClusterParameterGroup_617521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_617579 = ref object of OpenApiRestCall_616850
proc url_PostCopyDBClusterSnapshot_617581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBClusterSnapshot_617580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617582 = query.getOrDefault("Action")
  valid_617582 = validateParameter(valid_617582, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_617582 != nil:
    section.add "Action", valid_617582
  var valid_617583 = query.getOrDefault("Version")
  valid_617583 = validateParameter(valid_617583, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617583 != nil:
    section.add "Version", valid_617583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617584 = header.getOrDefault("X-Amz-Date")
  valid_617584 = validateParameter(valid_617584, JString, required = false,
                                 default = nil)
  if valid_617584 != nil:
    section.add "X-Amz-Date", valid_617584
  var valid_617585 = header.getOrDefault("X-Amz-Security-Token")
  valid_617585 = validateParameter(valid_617585, JString, required = false,
                                 default = nil)
  if valid_617585 != nil:
    section.add "X-Amz-Security-Token", valid_617585
  var valid_617586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617586 = validateParameter(valid_617586, JString, required = false,
                                 default = nil)
  if valid_617586 != nil:
    section.add "X-Amz-Content-Sha256", valid_617586
  var valid_617587 = header.getOrDefault("X-Amz-Algorithm")
  valid_617587 = validateParameter(valid_617587, JString, required = false,
                                 default = nil)
  if valid_617587 != nil:
    section.add "X-Amz-Algorithm", valid_617587
  var valid_617588 = header.getOrDefault("X-Amz-Signature")
  valid_617588 = validateParameter(valid_617588, JString, required = false,
                                 default = nil)
  if valid_617588 != nil:
    section.add "X-Amz-Signature", valid_617588
  var valid_617589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617589 = validateParameter(valid_617589, JString, required = false,
                                 default = nil)
  if valid_617589 != nil:
    section.add "X-Amz-SignedHeaders", valid_617589
  var valid_617590 = header.getOrDefault("X-Amz-Credential")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "X-Amz-Credential", valid_617590
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The cluster snapshot identifier for the encrypted cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new cluster snapshot to create from the source cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  section = newJObject()
  var valid_617591 = formData.getOrDefault("PreSignedUrl")
  valid_617591 = validateParameter(valid_617591, JString, required = false,
                                 default = nil)
  if valid_617591 != nil:
    section.add "PreSignedUrl", valid_617591
  var valid_617592 = formData.getOrDefault("Tags")
  valid_617592 = validateParameter(valid_617592, JArray, required = false,
                                 default = nil)
  if valid_617592 != nil:
    section.add "Tags", valid_617592
  var valid_617593 = formData.getOrDefault("CopyTags")
  valid_617593 = validateParameter(valid_617593, JBool, required = false, default = nil)
  if valid_617593 != nil:
    section.add "CopyTags", valid_617593
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_617594 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_617594 = validateParameter(valid_617594, JString, required = true,
                                 default = nil)
  if valid_617594 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_617594
  var valid_617595 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_617595 = validateParameter(valid_617595, JString, required = true,
                                 default = nil)
  if valid_617595 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_617595
  var valid_617596 = formData.getOrDefault("KmsKeyId")
  valid_617596 = validateParameter(valid_617596, JString, required = false,
                                 default = nil)
  if valid_617596 != nil:
    section.add "KmsKeyId", valid_617596
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617597: Call_PostCopyDBClusterSnapshot_617579;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_617597.validator(path, query, header, formData, body, _)
  let scheme = call_617597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617597.url(scheme.get, call_617597.host, call_617597.base,
                         call_617597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617597, url, valid, _)

proc call*(call_617598: Call_PostCopyDBClusterSnapshot_617579;
          SourceDBClusterSnapshotIdentifier: string;
          TargetDBClusterSnapshotIdentifier: string; PreSignedUrl: string = "";
          Tags: JsonNode = nil; CopyTags: bool = false;
          Action: string = "CopyDBClusterSnapshot"; KmsKeyId: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The cluster snapshot identifier for the encrypted cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new cluster snapshot to create from the source cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Action: string (required)
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   Version: string (required)
  var query_617599 = newJObject()
  var formData_617600 = newJObject()
  add(formData_617600, "PreSignedUrl", newJString(PreSignedUrl))
  if Tags != nil:
    formData_617600.add "Tags", Tags
  add(formData_617600, "CopyTags", newJBool(CopyTags))
  add(formData_617600, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_617600, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_617599, "Action", newJString(Action))
  add(formData_617600, "KmsKeyId", newJString(KmsKeyId))
  add(query_617599, "Version", newJString(Version))
  result = call_617598.call(nil, query_617599, nil, formData_617600, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_617579(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_617580, base: "/",
    url: url_PostCopyDBClusterSnapshot_617581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_617558 = ref object of OpenApiRestCall_616850
proc url_GetCopyDBClusterSnapshot_617560(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBClusterSnapshot_617559(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The cluster snapshot identifier for the encrypted cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new cluster snapshot to create from the source cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   Action: JString (required)
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   Version: JString (required)
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  section = newJObject()
  var valid_617561 = query.getOrDefault("PreSignedUrl")
  valid_617561 = validateParameter(valid_617561, JString, required = false,
                                 default = nil)
  if valid_617561 != nil:
    section.add "PreSignedUrl", valid_617561
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_617562 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_617562 = validateParameter(valid_617562, JString, required = true,
                                 default = nil)
  if valid_617562 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_617562
  var valid_617563 = query.getOrDefault("Tags")
  valid_617563 = validateParameter(valid_617563, JArray, required = false,
                                 default = nil)
  if valid_617563 != nil:
    section.add "Tags", valid_617563
  var valid_617564 = query.getOrDefault("Action")
  valid_617564 = validateParameter(valid_617564, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_617564 != nil:
    section.add "Action", valid_617564
  var valid_617565 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_617565 = validateParameter(valid_617565, JString, required = true,
                                 default = nil)
  if valid_617565 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_617565
  var valid_617566 = query.getOrDefault("KmsKeyId")
  valid_617566 = validateParameter(valid_617566, JString, required = false,
                                 default = nil)
  if valid_617566 != nil:
    section.add "KmsKeyId", valid_617566
  var valid_617567 = query.getOrDefault("Version")
  valid_617567 = validateParameter(valid_617567, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617567 != nil:
    section.add "Version", valid_617567
  var valid_617568 = query.getOrDefault("CopyTags")
  valid_617568 = validateParameter(valid_617568, JBool, required = false, default = nil)
  if valid_617568 != nil:
    section.add "CopyTags", valid_617568
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617569 = header.getOrDefault("X-Amz-Date")
  valid_617569 = validateParameter(valid_617569, JString, required = false,
                                 default = nil)
  if valid_617569 != nil:
    section.add "X-Amz-Date", valid_617569
  var valid_617570 = header.getOrDefault("X-Amz-Security-Token")
  valid_617570 = validateParameter(valid_617570, JString, required = false,
                                 default = nil)
  if valid_617570 != nil:
    section.add "X-Amz-Security-Token", valid_617570
  var valid_617571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617571 = validateParameter(valid_617571, JString, required = false,
                                 default = nil)
  if valid_617571 != nil:
    section.add "X-Amz-Content-Sha256", valid_617571
  var valid_617572 = header.getOrDefault("X-Amz-Algorithm")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "X-Amz-Algorithm", valid_617572
  var valid_617573 = header.getOrDefault("X-Amz-Signature")
  valid_617573 = validateParameter(valid_617573, JString, required = false,
                                 default = nil)
  if valid_617573 != nil:
    section.add "X-Amz-Signature", valid_617573
  var valid_617574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617574 = validateParameter(valid_617574, JString, required = false,
                                 default = nil)
  if valid_617574 != nil:
    section.add "X-Amz-SignedHeaders", valid_617574
  var valid_617575 = header.getOrDefault("X-Amz-Credential")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-Credential", valid_617575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617576: Call_GetCopyDBClusterSnapshot_617558; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_617576.validator(path, query, header, formData, body, _)
  let scheme = call_617576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617576.url(scheme.get, call_617576.host, call_617576.base,
                         call_617576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617576, url, valid, _)

proc call*(call_617577: Call_GetCopyDBClusterSnapshot_617558;
          TargetDBClusterSnapshotIdentifier: string;
          SourceDBClusterSnapshotIdentifier: string; PreSignedUrl: string = "";
          Tags: JsonNode = nil; Action: string = "CopyDBClusterSnapshot";
          KmsKeyId: string = ""; Version: string = "2014-10-31"; CopyTags: bool = false): Recallable =
  ## getCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The cluster snapshot identifier for the encrypted cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new cluster snapshot to create from the source cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   Action: string (required)
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   Version: string (required)
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  var query_617578 = newJObject()
  add(query_617578, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_617578, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  if Tags != nil:
    query_617578.add "Tags", Tags
  add(query_617578, "Action", newJString(Action))
  add(query_617578, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_617578, "KmsKeyId", newJString(KmsKeyId))
  add(query_617578, "Version", newJString(Version))
  add(query_617578, "CopyTags", newJBool(CopyTags))
  result = call_617577.call(nil, query_617578, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_617558(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_617559, base: "/",
    url: url_GetCopyDBClusterSnapshot_617560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_617634 = ref object of OpenApiRestCall_616850
proc url_PostCreateDBCluster_617636(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBCluster_617635(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617637 = query.getOrDefault("Action")
  valid_617637 = validateParameter(valid_617637, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_617637 != nil:
    section.add "Action", valid_617637
  var valid_617638 = query.getOrDefault("Version")
  valid_617638 = validateParameter(valid_617638, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617638 != nil:
    section.add "Version", valid_617638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617639 = header.getOrDefault("X-Amz-Date")
  valid_617639 = validateParameter(valid_617639, JString, required = false,
                                 default = nil)
  if valid_617639 != nil:
    section.add "X-Amz-Date", valid_617639
  var valid_617640 = header.getOrDefault("X-Amz-Security-Token")
  valid_617640 = validateParameter(valid_617640, JString, required = false,
                                 default = nil)
  if valid_617640 != nil:
    section.add "X-Amz-Security-Token", valid_617640
  var valid_617641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617641 = validateParameter(valid_617641, JString, required = false,
                                 default = nil)
  if valid_617641 != nil:
    section.add "X-Amz-Content-Sha256", valid_617641
  var valid_617642 = header.getOrDefault("X-Amz-Algorithm")
  valid_617642 = validateParameter(valid_617642, JString, required = false,
                                 default = nil)
  if valid_617642 != nil:
    section.add "X-Amz-Algorithm", valid_617642
  var valid_617643 = header.getOrDefault("X-Amz-Signature")
  valid_617643 = validateParameter(valid_617643, JString, required = false,
                                 default = nil)
  if valid_617643 != nil:
    section.add "X-Amz-Signature", valid_617643
  var valid_617644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617644 = validateParameter(valid_617644, JString, required = false,
                                 default = nil)
  if valid_617644 != nil:
    section.add "X-Amz-SignedHeaders", valid_617644
  var valid_617645 = header.getOrDefault("X-Amz-Credential")
  valid_617645 = validateParameter(valid_617645, JString, required = false,
                                 default = nil)
  if valid_617645 != nil:
    section.add "X-Amz-Credential", valid_617645
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : The port number on which the instances in the cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the cluster is encrypted.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  var valid_617646 = formData.getOrDefault("Port")
  valid_617646 = validateParameter(valid_617646, JInt, required = false, default = nil)
  if valid_617646 != nil:
    section.add "Port", valid_617646
  var valid_617647 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_617647 = validateParameter(valid_617647, JArray, required = false,
                                 default = nil)
  if valid_617647 != nil:
    section.add "VpcSecurityGroupIds", valid_617647
  var valid_617648 = formData.getOrDefault("BackupRetentionPeriod")
  valid_617648 = validateParameter(valid_617648, JInt, required = false, default = nil)
  if valid_617648 != nil:
    section.add "BackupRetentionPeriod", valid_617648
  var valid_617649 = formData.getOrDefault("PreferredBackupWindow")
  valid_617649 = validateParameter(valid_617649, JString, required = false,
                                 default = nil)
  if valid_617649 != nil:
    section.add "PreferredBackupWindow", valid_617649
  var valid_617650 = formData.getOrDefault("Tags")
  valid_617650 = validateParameter(valid_617650, JArray, required = false,
                                 default = nil)
  if valid_617650 != nil:
    section.add "Tags", valid_617650
  assert formData != nil, "formData argument is necessary due to required `MasterUserPassword` field"
  var valid_617651 = formData.getOrDefault("MasterUserPassword")
  valid_617651 = validateParameter(valid_617651, JString, required = true,
                                 default = nil)
  if valid_617651 != nil:
    section.add "MasterUserPassword", valid_617651
  var valid_617652 = formData.getOrDefault("DeletionProtection")
  valid_617652 = validateParameter(valid_617652, JBool, required = false, default = nil)
  if valid_617652 != nil:
    section.add "DeletionProtection", valid_617652
  var valid_617653 = formData.getOrDefault("DBSubnetGroupName")
  valid_617653 = validateParameter(valid_617653, JString, required = false,
                                 default = nil)
  if valid_617653 != nil:
    section.add "DBSubnetGroupName", valid_617653
  var valid_617654 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_617654 = validateParameter(valid_617654, JString, required = false,
                                 default = nil)
  if valid_617654 != nil:
    section.add "DBClusterParameterGroupName", valid_617654
  var valid_617655 = formData.getOrDefault("MasterUsername")
  valid_617655 = validateParameter(valid_617655, JString, required = true,
                                 default = nil)
  if valid_617655 != nil:
    section.add "MasterUsername", valid_617655
  var valid_617656 = formData.getOrDefault("AvailabilityZones")
  valid_617656 = validateParameter(valid_617656, JArray, required = false,
                                 default = nil)
  if valid_617656 != nil:
    section.add "AvailabilityZones", valid_617656
  var valid_617657 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_617657 = validateParameter(valid_617657, JArray, required = false,
                                 default = nil)
  if valid_617657 != nil:
    section.add "EnableCloudwatchLogsExports", valid_617657
  var valid_617658 = formData.getOrDefault("Engine")
  valid_617658 = validateParameter(valid_617658, JString, required = true,
                                 default = nil)
  if valid_617658 != nil:
    section.add "Engine", valid_617658
  var valid_617659 = formData.getOrDefault("KmsKeyId")
  valid_617659 = validateParameter(valid_617659, JString, required = false,
                                 default = nil)
  if valid_617659 != nil:
    section.add "KmsKeyId", valid_617659
  var valid_617660 = formData.getOrDefault("StorageEncrypted")
  valid_617660 = validateParameter(valid_617660, JBool, required = false, default = nil)
  if valid_617660 != nil:
    section.add "StorageEncrypted", valid_617660
  var valid_617661 = formData.getOrDefault("DBClusterIdentifier")
  valid_617661 = validateParameter(valid_617661, JString, required = true,
                                 default = nil)
  if valid_617661 != nil:
    section.add "DBClusterIdentifier", valid_617661
  var valid_617662 = formData.getOrDefault("EngineVersion")
  valid_617662 = validateParameter(valid_617662, JString, required = false,
                                 default = nil)
  if valid_617662 != nil:
    section.add "EngineVersion", valid_617662
  var valid_617663 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_617663 = validateParameter(valid_617663, JString, required = false,
                                 default = nil)
  if valid_617663 != nil:
    section.add "PreferredMaintenanceWindow", valid_617663
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617664: Call_PostCreateDBCluster_617634; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  let valid = call_617664.validator(path, query, header, formData, body, _)
  let scheme = call_617664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617664.url(scheme.get, call_617664.host, call_617664.base,
                         call_617664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617664, url, valid, _)

proc call*(call_617665: Call_PostCreateDBCluster_617634;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBClusterIdentifier: string; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          PreferredBackupWindow: string = ""; Tags: JsonNode = nil;
          DeletionProtection: bool = false; DBSubnetGroupName: string = "";
          Action: string = "CreateDBCluster";
          DBClusterParameterGroupName: string = "";
          AvailabilityZones: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; KmsKeyId: string = "";
          StorageEncrypted: bool = false; EngineVersion: string = "";
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postCreateDBCluster
  ## Creates a new Amazon DocumentDB cluster.
  ##   Port: int
  ##       : The port number on which the instances in the cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the cluster is encrypted.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_617666 = newJObject()
  var formData_617667 = newJObject()
  add(formData_617667, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_617667.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_617667, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_617667, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  if Tags != nil:
    formData_617667.add "Tags", Tags
  add(formData_617667, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_617667, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_617667, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_617666, "Action", newJString(Action))
  add(formData_617667, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_617667, "MasterUsername", newJString(MasterUsername))
  if AvailabilityZones != nil:
    formData_617667.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    formData_617667.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_617667, "Engine", newJString(Engine))
  add(formData_617667, "KmsKeyId", newJString(KmsKeyId))
  add(formData_617667, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_617667, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_617667, "EngineVersion", newJString(EngineVersion))
  add(query_617666, "Version", newJString(Version))
  add(formData_617667, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_617665.call(nil, query_617666, nil, formData_617667, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_617634(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_617635, base: "/",
    url: url_PostCreateDBCluster_617636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_617601 = ref object of OpenApiRestCall_616850
proc url_GetCreateDBCluster_617603(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBCluster_617602(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the cluster is encrypted.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   Action: JString (required)
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   Port: JInt
  ##       : The port number on which the instances in the cluster accept connections.
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   Version: JString (required)
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  section = newJObject()
  var valid_617604 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_617604 = validateParameter(valid_617604, JString, required = false,
                                 default = nil)
  if valid_617604 != nil:
    section.add "PreferredMaintenanceWindow", valid_617604
  var valid_617605 = query.getOrDefault("DBClusterParameterGroupName")
  valid_617605 = validateParameter(valid_617605, JString, required = false,
                                 default = nil)
  if valid_617605 != nil:
    section.add "DBClusterParameterGroupName", valid_617605
  var valid_617606 = query.getOrDefault("StorageEncrypted")
  valid_617606 = validateParameter(valid_617606, JBool, required = false, default = nil)
  if valid_617606 != nil:
    section.add "StorageEncrypted", valid_617606
  var valid_617607 = query.getOrDefault("AvailabilityZones")
  valid_617607 = validateParameter(valid_617607, JArray, required = false,
                                 default = nil)
  if valid_617607 != nil:
    section.add "AvailabilityZones", valid_617607
  assert query != nil, "query argument is necessary due to required `MasterUserPassword` field"
  var valid_617608 = query.getOrDefault("MasterUserPassword")
  valid_617608 = validateParameter(valid_617608, JString, required = true,
                                 default = nil)
  if valid_617608 != nil:
    section.add "MasterUserPassword", valid_617608
  var valid_617609 = query.getOrDefault("DBClusterIdentifier")
  valid_617609 = validateParameter(valid_617609, JString, required = true,
                                 default = nil)
  if valid_617609 != nil:
    section.add "DBClusterIdentifier", valid_617609
  var valid_617610 = query.getOrDefault("BackupRetentionPeriod")
  valid_617610 = validateParameter(valid_617610, JInt, required = false, default = nil)
  if valid_617610 != nil:
    section.add "BackupRetentionPeriod", valid_617610
  var valid_617611 = query.getOrDefault("VpcSecurityGroupIds")
  valid_617611 = validateParameter(valid_617611, JArray, required = false,
                                 default = nil)
  if valid_617611 != nil:
    section.add "VpcSecurityGroupIds", valid_617611
  var valid_617612 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_617612 = validateParameter(valid_617612, JArray, required = false,
                                 default = nil)
  if valid_617612 != nil:
    section.add "EnableCloudwatchLogsExports", valid_617612
  var valid_617613 = query.getOrDefault("Tags")
  valid_617613 = validateParameter(valid_617613, JArray, required = false,
                                 default = nil)
  if valid_617613 != nil:
    section.add "Tags", valid_617613
  var valid_617614 = query.getOrDefault("DeletionProtection")
  valid_617614 = validateParameter(valid_617614, JBool, required = false, default = nil)
  if valid_617614 != nil:
    section.add "DeletionProtection", valid_617614
  var valid_617615 = query.getOrDefault("DBSubnetGroupName")
  valid_617615 = validateParameter(valid_617615, JString, required = false,
                                 default = nil)
  if valid_617615 != nil:
    section.add "DBSubnetGroupName", valid_617615
  var valid_617616 = query.getOrDefault("KmsKeyId")
  valid_617616 = validateParameter(valid_617616, JString, required = false,
                                 default = nil)
  if valid_617616 != nil:
    section.add "KmsKeyId", valid_617616
  var valid_617617 = query.getOrDefault("Action")
  valid_617617 = validateParameter(valid_617617, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_617617 != nil:
    section.add "Action", valid_617617
  var valid_617618 = query.getOrDefault("EngineVersion")
  valid_617618 = validateParameter(valid_617618, JString, required = false,
                                 default = nil)
  if valid_617618 != nil:
    section.add "EngineVersion", valid_617618
  var valid_617619 = query.getOrDefault("Port")
  valid_617619 = validateParameter(valid_617619, JInt, required = false, default = nil)
  if valid_617619 != nil:
    section.add "Port", valid_617619
  var valid_617620 = query.getOrDefault("Engine")
  valid_617620 = validateParameter(valid_617620, JString, required = true,
                                 default = nil)
  if valid_617620 != nil:
    section.add "Engine", valid_617620
  var valid_617621 = query.getOrDefault("Version")
  valid_617621 = validateParameter(valid_617621, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617621 != nil:
    section.add "Version", valid_617621
  var valid_617622 = query.getOrDefault("PreferredBackupWindow")
  valid_617622 = validateParameter(valid_617622, JString, required = false,
                                 default = nil)
  if valid_617622 != nil:
    section.add "PreferredBackupWindow", valid_617622
  var valid_617623 = query.getOrDefault("MasterUsername")
  valid_617623 = validateParameter(valid_617623, JString, required = true,
                                 default = nil)
  if valid_617623 != nil:
    section.add "MasterUsername", valid_617623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617624 = header.getOrDefault("X-Amz-Date")
  valid_617624 = validateParameter(valid_617624, JString, required = false,
                                 default = nil)
  if valid_617624 != nil:
    section.add "X-Amz-Date", valid_617624
  var valid_617625 = header.getOrDefault("X-Amz-Security-Token")
  valid_617625 = validateParameter(valid_617625, JString, required = false,
                                 default = nil)
  if valid_617625 != nil:
    section.add "X-Amz-Security-Token", valid_617625
  var valid_617626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617626 = validateParameter(valid_617626, JString, required = false,
                                 default = nil)
  if valid_617626 != nil:
    section.add "X-Amz-Content-Sha256", valid_617626
  var valid_617627 = header.getOrDefault("X-Amz-Algorithm")
  valid_617627 = validateParameter(valid_617627, JString, required = false,
                                 default = nil)
  if valid_617627 != nil:
    section.add "X-Amz-Algorithm", valid_617627
  var valid_617628 = header.getOrDefault("X-Amz-Signature")
  valid_617628 = validateParameter(valid_617628, JString, required = false,
                                 default = nil)
  if valid_617628 != nil:
    section.add "X-Amz-Signature", valid_617628
  var valid_617629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617629 = validateParameter(valid_617629, JString, required = false,
                                 default = nil)
  if valid_617629 != nil:
    section.add "X-Amz-SignedHeaders", valid_617629
  var valid_617630 = header.getOrDefault("X-Amz-Credential")
  valid_617630 = validateParameter(valid_617630, JString, required = false,
                                 default = nil)
  if valid_617630 != nil:
    section.add "X-Amz-Credential", valid_617630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617631: Call_GetCreateDBCluster_617601; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  let valid = call_617631.validator(path, query, header, formData, body, _)
  let scheme = call_617631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617631.url(scheme.get, call_617631.host, call_617631.base,
                         call_617631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617631, url, valid, _)

proc call*(call_617632: Call_GetCreateDBCluster_617601; MasterUserPassword: string;
          DBClusterIdentifier: string; Engine: string; MasterUsername: string;
          PreferredMaintenanceWindow: string = "";
          DBClusterParameterGroupName: string = ""; StorageEncrypted: bool = false;
          AvailabilityZones: JsonNode = nil; BackupRetentionPeriod: int = 0;
          VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false; DBSubnetGroupName: string = "";
          KmsKeyId: string = ""; Action: string = "CreateDBCluster";
          EngineVersion: string = ""; Port: int = 0; Version: string = "2014-10-31";
          PreferredBackupWindow: string = ""): Recallable =
  ## getCreateDBCluster
  ## Creates a new Amazon DocumentDB cluster.
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the cluster is encrypted.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   Action: string (required)
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   Port: int
  ##       : The port number on which the instances in the cluster accept connections.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  var query_617633 = newJObject()
  add(query_617633, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_617633, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_617633, "StorageEncrypted", newJBool(StorageEncrypted))
  if AvailabilityZones != nil:
    query_617633.add "AvailabilityZones", AvailabilityZones
  add(query_617633, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_617633, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_617633, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if VpcSecurityGroupIds != nil:
    query_617633.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_617633.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_617633.add "Tags", Tags
  add(query_617633, "DeletionProtection", newJBool(DeletionProtection))
  add(query_617633, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_617633, "KmsKeyId", newJString(KmsKeyId))
  add(query_617633, "Action", newJString(Action))
  add(query_617633, "EngineVersion", newJString(EngineVersion))
  add(query_617633, "Port", newJInt(Port))
  add(query_617633, "Engine", newJString(Engine))
  add(query_617633, "Version", newJString(Version))
  add(query_617633, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_617633, "MasterUsername", newJString(MasterUsername))
  result = call_617632.call(nil, query_617633, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_617601(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_617602,
    base: "/", url: url_GetCreateDBCluster_617603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_617687 = ref object of OpenApiRestCall_616850
proc url_PostCreateDBClusterParameterGroup_617689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBClusterParameterGroup_617688(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_617690 = query.getOrDefault("Action")
  valid_617690 = validateParameter(valid_617690, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_617690 != nil:
    section.add "Action", valid_617690
  var valid_617691 = query.getOrDefault("Version")
  valid_617691 = validateParameter(valid_617691, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617691 != nil:
    section.add "Version", valid_617691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617692 = header.getOrDefault("X-Amz-Date")
  valid_617692 = validateParameter(valid_617692, JString, required = false,
                                 default = nil)
  if valid_617692 != nil:
    section.add "X-Amz-Date", valid_617692
  var valid_617693 = header.getOrDefault("X-Amz-Security-Token")
  valid_617693 = validateParameter(valid_617693, JString, required = false,
                                 default = nil)
  if valid_617693 != nil:
    section.add "X-Amz-Security-Token", valid_617693
  var valid_617694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617694 = validateParameter(valid_617694, JString, required = false,
                                 default = nil)
  if valid_617694 != nil:
    section.add "X-Amz-Content-Sha256", valid_617694
  var valid_617695 = header.getOrDefault("X-Amz-Algorithm")
  valid_617695 = validateParameter(valid_617695, JString, required = false,
                                 default = nil)
  if valid_617695 != nil:
    section.add "X-Amz-Algorithm", valid_617695
  var valid_617696 = header.getOrDefault("X-Amz-Signature")
  valid_617696 = validateParameter(valid_617696, JString, required = false,
                                 default = nil)
  if valid_617696 != nil:
    section.add "X-Amz-Signature", valid_617696
  var valid_617697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617697 = validateParameter(valid_617697, JString, required = false,
                                 default = nil)
  if valid_617697 != nil:
    section.add "X-Amz-SignedHeaders", valid_617697
  var valid_617698 = header.getOrDefault("X-Amz-Credential")
  valid_617698 = validateParameter(valid_617698, JString, required = false,
                                 default = nil)
  if valid_617698 != nil:
    section.add "X-Amz-Credential", valid_617698
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster parameter group.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must not match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The cluster parameter group family name.
  ##   Description: JString (required)
  ##              : The description for the cluster parameter group.
  section = newJObject()
  var valid_617699 = formData.getOrDefault("Tags")
  valid_617699 = validateParameter(valid_617699, JArray, required = false,
                                 default = nil)
  if valid_617699 != nil:
    section.add "Tags", valid_617699
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_617700 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_617700 = validateParameter(valid_617700, JString, required = true,
                                 default = nil)
  if valid_617700 != nil:
    section.add "DBClusterParameterGroupName", valid_617700
  var valid_617701 = formData.getOrDefault("DBParameterGroupFamily")
  valid_617701 = validateParameter(valid_617701, JString, required = true,
                                 default = nil)
  if valid_617701 != nil:
    section.add "DBParameterGroupFamily", valid_617701
  var valid_617702 = formData.getOrDefault("Description")
  valid_617702 = validateParameter(valid_617702, JString, required = true,
                                 default = nil)
  if valid_617702 != nil:
    section.add "Description", valid_617702
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617703: Call_PostCreateDBClusterParameterGroup_617687;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_617703.validator(path, query, header, formData, body, _)
  let scheme = call_617703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617703.url(scheme.get, call_617703.host, call_617703.base,
                         call_617703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617703, url, valid, _)

proc call*(call_617704: Call_PostCreateDBClusterParameterGroup_617687;
          DBClusterParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterParameterGroup
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster parameter group.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must not match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   DBParameterGroupFamily: string (required)
  ##                         : The cluster parameter group family name.
  ##   Version: string (required)
  ##   Description: string (required)
  ##              : The description for the cluster parameter group.
  var query_617705 = newJObject()
  var formData_617706 = newJObject()
  if Tags != nil:
    formData_617706.add "Tags", Tags
  add(query_617705, "Action", newJString(Action))
  add(formData_617706, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_617706, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_617705, "Version", newJString(Version))
  add(formData_617706, "Description", newJString(Description))
  result = call_617704.call(nil, query_617705, nil, formData_617706, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_617687(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_617688, base: "/",
    url: url_PostCreateDBClusterParameterGroup_617689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_617668 = ref object of OpenApiRestCall_616850
proc url_GetCreateDBClusterParameterGroup_617670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBClusterParameterGroup_617669(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must not match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Description: JString (required)
  ##              : The description for the cluster parameter group.
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster parameter group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_617671 = query.getOrDefault("DBClusterParameterGroupName")
  valid_617671 = validateParameter(valid_617671, JString, required = true,
                                 default = nil)
  if valid_617671 != nil:
    section.add "DBClusterParameterGroupName", valid_617671
  var valid_617672 = query.getOrDefault("Description")
  valid_617672 = validateParameter(valid_617672, JString, required = true,
                                 default = nil)
  if valid_617672 != nil:
    section.add "Description", valid_617672
  var valid_617673 = query.getOrDefault("DBParameterGroupFamily")
  valid_617673 = validateParameter(valid_617673, JString, required = true,
                                 default = nil)
  if valid_617673 != nil:
    section.add "DBParameterGroupFamily", valid_617673
  var valid_617674 = query.getOrDefault("Tags")
  valid_617674 = validateParameter(valid_617674, JArray, required = false,
                                 default = nil)
  if valid_617674 != nil:
    section.add "Tags", valid_617674
  var valid_617675 = query.getOrDefault("Action")
  valid_617675 = validateParameter(valid_617675, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_617675 != nil:
    section.add "Action", valid_617675
  var valid_617676 = query.getOrDefault("Version")
  valid_617676 = validateParameter(valid_617676, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617676 != nil:
    section.add "Version", valid_617676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617677 = header.getOrDefault("X-Amz-Date")
  valid_617677 = validateParameter(valid_617677, JString, required = false,
                                 default = nil)
  if valid_617677 != nil:
    section.add "X-Amz-Date", valid_617677
  var valid_617678 = header.getOrDefault("X-Amz-Security-Token")
  valid_617678 = validateParameter(valid_617678, JString, required = false,
                                 default = nil)
  if valid_617678 != nil:
    section.add "X-Amz-Security-Token", valid_617678
  var valid_617679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617679 = validateParameter(valid_617679, JString, required = false,
                                 default = nil)
  if valid_617679 != nil:
    section.add "X-Amz-Content-Sha256", valid_617679
  var valid_617680 = header.getOrDefault("X-Amz-Algorithm")
  valid_617680 = validateParameter(valid_617680, JString, required = false,
                                 default = nil)
  if valid_617680 != nil:
    section.add "X-Amz-Algorithm", valid_617680
  var valid_617681 = header.getOrDefault("X-Amz-Signature")
  valid_617681 = validateParameter(valid_617681, JString, required = false,
                                 default = nil)
  if valid_617681 != nil:
    section.add "X-Amz-Signature", valid_617681
  var valid_617682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617682 = validateParameter(valid_617682, JString, required = false,
                                 default = nil)
  if valid_617682 != nil:
    section.add "X-Amz-SignedHeaders", valid_617682
  var valid_617683 = header.getOrDefault("X-Amz-Credential")
  valid_617683 = validateParameter(valid_617683, JString, required = false,
                                 default = nil)
  if valid_617683 != nil:
    section.add "X-Amz-Credential", valid_617683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617684: Call_GetCreateDBClusterParameterGroup_617668;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_617684.validator(path, query, header, formData, body, _)
  let scheme = call_617684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617684.url(scheme.get, call_617684.host, call_617684.base,
                         call_617684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617684, url, valid, _)

proc call*(call_617685: Call_GetCreateDBClusterParameterGroup_617668;
          DBClusterParameterGroupName: string; Description: string;
          DBParameterGroupFamily: string; Tags: JsonNode = nil;
          Action: string = "CreateDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterParameterGroup
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must not match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Description: string (required)
  ##              : The description for the cluster parameter group.
  ##   DBParameterGroupFamily: string (required)
  ##                         : The cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster parameter group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_617686 = newJObject()
  add(query_617686, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_617686, "Description", newJString(Description))
  add(query_617686, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_617686.add "Tags", Tags
  add(query_617686, "Action", newJString(Action))
  add(query_617686, "Version", newJString(Version))
  result = call_617685.call(nil, query_617686, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_617668(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_617669, base: "/",
    url: url_GetCreateDBClusterParameterGroup_617670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_617725 = ref object of OpenApiRestCall_616850
proc url_PostCreateDBClusterSnapshot_617727(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBClusterSnapshot_617726(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617728 = query.getOrDefault("Action")
  valid_617728 = validateParameter(valid_617728, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_617728 != nil:
    section.add "Action", valid_617728
  var valid_617729 = query.getOrDefault("Version")
  valid_617729 = validateParameter(valid_617729, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617729 != nil:
    section.add "Version", valid_617729
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617730 = header.getOrDefault("X-Amz-Date")
  valid_617730 = validateParameter(valid_617730, JString, required = false,
                                 default = nil)
  if valid_617730 != nil:
    section.add "X-Amz-Date", valid_617730
  var valid_617731 = header.getOrDefault("X-Amz-Security-Token")
  valid_617731 = validateParameter(valid_617731, JString, required = false,
                                 default = nil)
  if valid_617731 != nil:
    section.add "X-Amz-Security-Token", valid_617731
  var valid_617732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617732 = validateParameter(valid_617732, JString, required = false,
                                 default = nil)
  if valid_617732 != nil:
    section.add "X-Amz-Content-Sha256", valid_617732
  var valid_617733 = header.getOrDefault("X-Amz-Algorithm")
  valid_617733 = validateParameter(valid_617733, JString, required = false,
                                 default = nil)
  if valid_617733 != nil:
    section.add "X-Amz-Algorithm", valid_617733
  var valid_617734 = header.getOrDefault("X-Amz-Signature")
  valid_617734 = validateParameter(valid_617734, JString, required = false,
                                 default = nil)
  if valid_617734 != nil:
    section.add "X-Amz-Signature", valid_617734
  var valid_617735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617735 = validateParameter(valid_617735, JString, required = false,
                                 default = nil)
  if valid_617735 != nil:
    section.add "X-Amz-SignedHeaders", valid_617735
  var valid_617736 = header.getOrDefault("X-Amz-Credential")
  valid_617736 = validateParameter(valid_617736, JString, required = false,
                                 default = nil)
  if valid_617736 != nil:
    section.add "X-Amz-Credential", valid_617736
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
  var valid_617737 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_617737 = validateParameter(valid_617737, JString, required = true,
                                 default = nil)
  if valid_617737 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_617737
  var valid_617738 = formData.getOrDefault("Tags")
  valid_617738 = validateParameter(valid_617738, JArray, required = false,
                                 default = nil)
  if valid_617738 != nil:
    section.add "Tags", valid_617738
  var valid_617739 = formData.getOrDefault("DBClusterIdentifier")
  valid_617739 = validateParameter(valid_617739, JString, required = true,
                                 default = nil)
  if valid_617739 != nil:
    section.add "DBClusterIdentifier", valid_617739
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617740: Call_PostCreateDBClusterSnapshot_617725;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a snapshot of a cluster. 
  ## 
  let valid = call_617740.validator(path, query, header, formData, body, _)
  let scheme = call_617740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617740.url(scheme.get, call_617740.host, call_617740.base,
                         call_617740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617740, url, valid, _)

proc call*(call_617741: Call_PostCreateDBClusterSnapshot_617725;
          DBClusterSnapshotIdentifier: string; DBClusterIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBClusterSnapshot";
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterSnapshot
  ## Creates a snapshot of a cluster. 
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   Version: string (required)
  var query_617742 = newJObject()
  var formData_617743 = newJObject()
  add(formData_617743, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    formData_617743.add "Tags", Tags
  add(query_617742, "Action", newJString(Action))
  add(formData_617743, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_617742, "Version", newJString(Version))
  result = call_617741.call(nil, query_617742, nil, formData_617743, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_617725(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_617726, base: "/",
    url: url_PostCreateDBClusterSnapshot_617727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_617707 = ref object of OpenApiRestCall_616850
proc url_GetCreateDBClusterSnapshot_617709(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBClusterSnapshot_617708(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Creates a snapshot of a cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The identifier of the cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_617710 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_617710 = validateParameter(valid_617710, JString, required = true,
                                 default = nil)
  if valid_617710 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_617710
  var valid_617711 = query.getOrDefault("DBClusterIdentifier")
  valid_617711 = validateParameter(valid_617711, JString, required = true,
                                 default = nil)
  if valid_617711 != nil:
    section.add "DBClusterIdentifier", valid_617711
  var valid_617712 = query.getOrDefault("Tags")
  valid_617712 = validateParameter(valid_617712, JArray, required = false,
                                 default = nil)
  if valid_617712 != nil:
    section.add "Tags", valid_617712
  var valid_617713 = query.getOrDefault("Action")
  valid_617713 = validateParameter(valid_617713, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_617713 != nil:
    section.add "Action", valid_617713
  var valid_617714 = query.getOrDefault("Version")
  valid_617714 = validateParameter(valid_617714, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617714 != nil:
    section.add "Version", valid_617714
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617715 = header.getOrDefault("X-Amz-Date")
  valid_617715 = validateParameter(valid_617715, JString, required = false,
                                 default = nil)
  if valid_617715 != nil:
    section.add "X-Amz-Date", valid_617715
  var valid_617716 = header.getOrDefault("X-Amz-Security-Token")
  valid_617716 = validateParameter(valid_617716, JString, required = false,
                                 default = nil)
  if valid_617716 != nil:
    section.add "X-Amz-Security-Token", valid_617716
  var valid_617717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617717 = validateParameter(valid_617717, JString, required = false,
                                 default = nil)
  if valid_617717 != nil:
    section.add "X-Amz-Content-Sha256", valid_617717
  var valid_617718 = header.getOrDefault("X-Amz-Algorithm")
  valid_617718 = validateParameter(valid_617718, JString, required = false,
                                 default = nil)
  if valid_617718 != nil:
    section.add "X-Amz-Algorithm", valid_617718
  var valid_617719 = header.getOrDefault("X-Amz-Signature")
  valid_617719 = validateParameter(valid_617719, JString, required = false,
                                 default = nil)
  if valid_617719 != nil:
    section.add "X-Amz-Signature", valid_617719
  var valid_617720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617720 = validateParameter(valid_617720, JString, required = false,
                                 default = nil)
  if valid_617720 != nil:
    section.add "X-Amz-SignedHeaders", valid_617720
  var valid_617721 = header.getOrDefault("X-Amz-Credential")
  valid_617721 = validateParameter(valid_617721, JString, required = false,
                                 default = nil)
  if valid_617721 != nil:
    section.add "X-Amz-Credential", valid_617721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617722: Call_GetCreateDBClusterSnapshot_617707;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a snapshot of a cluster. 
  ## 
  let valid = call_617722.validator(path, query, header, formData, body, _)
  let scheme = call_617722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617722.url(scheme.get, call_617722.host, call_617722.base,
                         call_617722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617722, url, valid, _)

proc call*(call_617723: Call_GetCreateDBClusterSnapshot_617707;
          DBClusterSnapshotIdentifier: string; DBClusterIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBClusterSnapshot";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterSnapshot
  ## Creates a snapshot of a cluster. 
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_617724 = newJObject()
  add(query_617724, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_617724, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Tags != nil:
    query_617724.add "Tags", Tags
  add(query_617724, "Action", newJString(Action))
  add(query_617724, "Version", newJString(Version))
  result = call_617723.call(nil, query_617724, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_617707(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_617708, base: "/",
    url: url_GetCreateDBClusterSnapshot_617709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_617768 = ref object of OpenApiRestCall_616850
proc url_PostCreateDBInstance_617770(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_617769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617771 = query.getOrDefault("Action")
  valid_617771 = validateParameter(valid_617771, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_617771 != nil:
    section.add "Action", valid_617771
  var valid_617772 = query.getOrDefault("Version")
  valid_617772 = validateParameter(valid_617772, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617772 != nil:
    section.add "Version", valid_617772
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617773 = header.getOrDefault("X-Amz-Date")
  valid_617773 = validateParameter(valid_617773, JString, required = false,
                                 default = nil)
  if valid_617773 != nil:
    section.add "X-Amz-Date", valid_617773
  var valid_617774 = header.getOrDefault("X-Amz-Security-Token")
  valid_617774 = validateParameter(valid_617774, JString, required = false,
                                 default = nil)
  if valid_617774 != nil:
    section.add "X-Amz-Security-Token", valid_617774
  var valid_617775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617775 = validateParameter(valid_617775, JString, required = false,
                                 default = nil)
  if valid_617775 != nil:
    section.add "X-Amz-Content-Sha256", valid_617775
  var valid_617776 = header.getOrDefault("X-Amz-Algorithm")
  valid_617776 = validateParameter(valid_617776, JString, required = false,
                                 default = nil)
  if valid_617776 != nil:
    section.add "X-Amz-Algorithm", valid_617776
  var valid_617777 = header.getOrDefault("X-Amz-Signature")
  valid_617777 = validateParameter(valid_617777, JString, required = false,
                                 default = nil)
  if valid_617777 != nil:
    section.add "X-Amz-Signature", valid_617777
  var valid_617778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617778 = validateParameter(valid_617778, JString, required = false,
                                 default = nil)
  if valid_617778 != nil:
    section.add "X-Amz-SignedHeaders", valid_617778
  var valid_617779 = header.getOrDefault("X-Amz-Credential")
  valid_617779 = validateParameter(valid_617779, JString, required = false,
                                 default = nil)
  if valid_617779 != nil:
    section.add "X-Amz-Credential", valid_617779
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_617780 = formData.getOrDefault("DBInstanceClass")
  valid_617780 = validateParameter(valid_617780, JString, required = true,
                                 default = nil)
  if valid_617780 != nil:
    section.add "DBInstanceClass", valid_617780
  var valid_617781 = formData.getOrDefault("Engine")
  valid_617781 = validateParameter(valid_617781, JString, required = true,
                                 default = nil)
  if valid_617781 != nil:
    section.add "Engine", valid_617781
  var valid_617782 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_617782 = validateParameter(valid_617782, JBool, required = false, default = nil)
  if valid_617782 != nil:
    section.add "AutoMinorVersionUpgrade", valid_617782
  var valid_617783 = formData.getOrDefault("DBInstanceIdentifier")
  valid_617783 = validateParameter(valid_617783, JString, required = true,
                                 default = nil)
  if valid_617783 != nil:
    section.add "DBInstanceIdentifier", valid_617783
  var valid_617784 = formData.getOrDefault("Tags")
  valid_617784 = validateParameter(valid_617784, JArray, required = false,
                                 default = nil)
  if valid_617784 != nil:
    section.add "Tags", valid_617784
  var valid_617785 = formData.getOrDefault("PromotionTier")
  valid_617785 = validateParameter(valid_617785, JInt, required = false, default = nil)
  if valid_617785 != nil:
    section.add "PromotionTier", valid_617785
  var valid_617786 = formData.getOrDefault("AvailabilityZone")
  valid_617786 = validateParameter(valid_617786, JString, required = false,
                                 default = nil)
  if valid_617786 != nil:
    section.add "AvailabilityZone", valid_617786
  var valid_617787 = formData.getOrDefault("DBClusterIdentifier")
  valid_617787 = validateParameter(valid_617787, JString, required = true,
                                 default = nil)
  if valid_617787 != nil:
    section.add "DBClusterIdentifier", valid_617787
  var valid_617788 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_617788 = validateParameter(valid_617788, JString, required = false,
                                 default = nil)
  if valid_617788 != nil:
    section.add "PreferredMaintenanceWindow", valid_617788
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617789: Call_PostCreateDBInstance_617768; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new instance.
  ## 
  let valid = call_617789.validator(path, query, header, formData, body, _)
  let scheme = call_617789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617789.url(scheme.get, call_617789.host, call_617789.base,
                         call_617789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617789, url, valid, _)

proc call*(call_617790: Call_PostCreateDBInstance_617768; DBInstanceClass: string;
          Engine: string; DBInstanceIdentifier: string; DBClusterIdentifier: string;
          AutoMinorVersionUpgrade: bool = false; Tags: JsonNode = nil;
          Action: string = "CreateDBInstance"; PromotionTier: int = 0;
          AvailabilityZone: string = ""; Version: string = "2014-10-31";
          PreferredMaintenanceWindow: string = ""): Recallable =
  ## postCreateDBInstance
  ## Creates a new instance.
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   Action: string (required)
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_617791 = newJObject()
  var formData_617792 = newJObject()
  add(formData_617792, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_617792, "Engine", newJString(Engine))
  add(formData_617792, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_617792, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_617792.add "Tags", Tags
  add(query_617791, "Action", newJString(Action))
  add(formData_617792, "PromotionTier", newJInt(PromotionTier))
  add(formData_617792, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_617792, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_617791, "Version", newJString(Version))
  add(formData_617792, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_617790.call(nil, query_617791, nil, formData_617792, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_617768(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_617769, base: "/",
    url: url_PostCreateDBInstance_617770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_617744 = ref object of OpenApiRestCall_616850
proc url_GetCreateDBInstance_617746(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_617745(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## Creates a new instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   Action: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  section = newJObject()
  var valid_617747 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_617747 = validateParameter(valid_617747, JString, required = false,
                                 default = nil)
  if valid_617747 != nil:
    section.add "PreferredMaintenanceWindow", valid_617747
  var valid_617748 = query.getOrDefault("AvailabilityZone")
  valid_617748 = validateParameter(valid_617748, JString, required = false,
                                 default = nil)
  if valid_617748 != nil:
    section.add "AvailabilityZone", valid_617748
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_617749 = query.getOrDefault("DBClusterIdentifier")
  valid_617749 = validateParameter(valid_617749, JString, required = true,
                                 default = nil)
  if valid_617749 != nil:
    section.add "DBClusterIdentifier", valid_617749
  var valid_617750 = query.getOrDefault("PromotionTier")
  valid_617750 = validateParameter(valid_617750, JInt, required = false, default = nil)
  if valid_617750 != nil:
    section.add "PromotionTier", valid_617750
  var valid_617751 = query.getOrDefault("Tags")
  valid_617751 = validateParameter(valid_617751, JArray, required = false,
                                 default = nil)
  if valid_617751 != nil:
    section.add "Tags", valid_617751
  var valid_617752 = query.getOrDefault("DBInstanceClass")
  valid_617752 = validateParameter(valid_617752, JString, required = true,
                                 default = nil)
  if valid_617752 != nil:
    section.add "DBInstanceClass", valid_617752
  var valid_617753 = query.getOrDefault("Action")
  valid_617753 = validateParameter(valid_617753, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_617753 != nil:
    section.add "Action", valid_617753
  var valid_617754 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_617754 = validateParameter(valid_617754, JBool, required = false, default = nil)
  if valid_617754 != nil:
    section.add "AutoMinorVersionUpgrade", valid_617754
  var valid_617755 = query.getOrDefault("Engine")
  valid_617755 = validateParameter(valid_617755, JString, required = true,
                                 default = nil)
  if valid_617755 != nil:
    section.add "Engine", valid_617755
  var valid_617756 = query.getOrDefault("Version")
  valid_617756 = validateParameter(valid_617756, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617756 != nil:
    section.add "Version", valid_617756
  var valid_617757 = query.getOrDefault("DBInstanceIdentifier")
  valid_617757 = validateParameter(valid_617757, JString, required = true,
                                 default = nil)
  if valid_617757 != nil:
    section.add "DBInstanceIdentifier", valid_617757
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617758 = header.getOrDefault("X-Amz-Date")
  valid_617758 = validateParameter(valid_617758, JString, required = false,
                                 default = nil)
  if valid_617758 != nil:
    section.add "X-Amz-Date", valid_617758
  var valid_617759 = header.getOrDefault("X-Amz-Security-Token")
  valid_617759 = validateParameter(valid_617759, JString, required = false,
                                 default = nil)
  if valid_617759 != nil:
    section.add "X-Amz-Security-Token", valid_617759
  var valid_617760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617760 = validateParameter(valid_617760, JString, required = false,
                                 default = nil)
  if valid_617760 != nil:
    section.add "X-Amz-Content-Sha256", valid_617760
  var valid_617761 = header.getOrDefault("X-Amz-Algorithm")
  valid_617761 = validateParameter(valid_617761, JString, required = false,
                                 default = nil)
  if valid_617761 != nil:
    section.add "X-Amz-Algorithm", valid_617761
  var valid_617762 = header.getOrDefault("X-Amz-Signature")
  valid_617762 = validateParameter(valid_617762, JString, required = false,
                                 default = nil)
  if valid_617762 != nil:
    section.add "X-Amz-Signature", valid_617762
  var valid_617763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617763 = validateParameter(valid_617763, JString, required = false,
                                 default = nil)
  if valid_617763 != nil:
    section.add "X-Amz-SignedHeaders", valid_617763
  var valid_617764 = header.getOrDefault("X-Amz-Credential")
  valid_617764 = validateParameter(valid_617764, JString, required = false,
                                 default = nil)
  if valid_617764 != nil:
    section.add "X-Amz-Credential", valid_617764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617765: Call_GetCreateDBInstance_617744; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new instance.
  ## 
  let valid = call_617765.validator(path, query, header, formData, body, _)
  let scheme = call_617765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617765.url(scheme.get, call_617765.host, call_617765.base,
                         call_617765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617765, url, valid, _)

proc call*(call_617766: Call_GetCreateDBInstance_617744;
          DBClusterIdentifier: string; DBInstanceClass: string; Engine: string;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          AvailabilityZone: string = ""; PromotionTier: int = 0; Tags: JsonNode = nil;
          Action: string = "CreateDBInstance";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBInstance
  ## Creates a new instance.
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   Action: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  var query_617767 = newJObject()
  add(query_617767, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_617767, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_617767, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_617767, "PromotionTier", newJInt(PromotionTier))
  if Tags != nil:
    query_617767.add "Tags", Tags
  add(query_617767, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_617767, "Action", newJString(Action))
  add(query_617767, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_617767, "Engine", newJString(Engine))
  add(query_617767, "Version", newJString(Version))
  add(query_617767, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_617766.call(nil, query_617767, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_617744(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_617745, base: "/",
    url: url_GetCreateDBInstance_617746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_617812 = ref object of OpenApiRestCall_616850
proc url_PostCreateDBSubnetGroup_617814(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_617813(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617815 = query.getOrDefault("Action")
  valid_617815 = validateParameter(valid_617815, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_617815 != nil:
    section.add "Action", valid_617815
  var valid_617816 = query.getOrDefault("Version")
  valid_617816 = validateParameter(valid_617816, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617816 != nil:
    section.add "Version", valid_617816
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617817 = header.getOrDefault("X-Amz-Date")
  valid_617817 = validateParameter(valid_617817, JString, required = false,
                                 default = nil)
  if valid_617817 != nil:
    section.add "X-Amz-Date", valid_617817
  var valid_617818 = header.getOrDefault("X-Amz-Security-Token")
  valid_617818 = validateParameter(valid_617818, JString, required = false,
                                 default = nil)
  if valid_617818 != nil:
    section.add "X-Amz-Security-Token", valid_617818
  var valid_617819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617819 = validateParameter(valid_617819, JString, required = false,
                                 default = nil)
  if valid_617819 != nil:
    section.add "X-Amz-Content-Sha256", valid_617819
  var valid_617820 = header.getOrDefault("X-Amz-Algorithm")
  valid_617820 = validateParameter(valid_617820, JString, required = false,
                                 default = nil)
  if valid_617820 != nil:
    section.add "X-Amz-Algorithm", valid_617820
  var valid_617821 = header.getOrDefault("X-Amz-Signature")
  valid_617821 = validateParameter(valid_617821, JString, required = false,
                                 default = nil)
  if valid_617821 != nil:
    section.add "X-Amz-Signature", valid_617821
  var valid_617822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617822 = validateParameter(valid_617822, JString, required = false,
                                 default = nil)
  if valid_617822 != nil:
    section.add "X-Amz-SignedHeaders", valid_617822
  var valid_617823 = header.getOrDefault("X-Amz-Credential")
  valid_617823 = validateParameter(valid_617823, JString, required = false,
                                 default = nil)
  if valid_617823 != nil:
    section.add "X-Amz-Credential", valid_617823
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the subnet group.
  section = newJObject()
  var valid_617824 = formData.getOrDefault("Tags")
  valid_617824 = validateParameter(valid_617824, JArray, required = false,
                                 default = nil)
  if valid_617824 != nil:
    section.add "Tags", valid_617824
  assert formData != nil,
        "formData argument is necessary due to required `SubnetIds` field"
  var valid_617825 = formData.getOrDefault("SubnetIds")
  valid_617825 = validateParameter(valid_617825, JArray, required = true, default = nil)
  if valid_617825 != nil:
    section.add "SubnetIds", valid_617825
  var valid_617826 = formData.getOrDefault("DBSubnetGroupName")
  valid_617826 = validateParameter(valid_617826, JString, required = true,
                                 default = nil)
  if valid_617826 != nil:
    section.add "DBSubnetGroupName", valid_617826
  var valid_617827 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_617827 = validateParameter(valid_617827, JString, required = true,
                                 default = nil)
  if valid_617827 != nil:
    section.add "DBSubnetGroupDescription", valid_617827
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617828: Call_PostCreateDBSubnetGroup_617812; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_617828.validator(path, query, header, formData, body, _)
  let scheme = call_617828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617828.url(scheme.get, call_617828.host, call_617828.base,
                         call_617828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617828, url, valid, _)

proc call*(call_617829: Call_PostCreateDBSubnetGroup_617812; SubnetIds: JsonNode;
          DBSubnetGroupName: string; DBSubnetGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBSubnetGroup
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the subnet group.
  var query_617830 = newJObject()
  var formData_617831 = newJObject()
  if Tags != nil:
    formData_617831.add "Tags", Tags
  if SubnetIds != nil:
    formData_617831.add "SubnetIds", SubnetIds
  add(formData_617831, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_617830, "Action", newJString(Action))
  add(query_617830, "Version", newJString(Version))
  add(formData_617831, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  result = call_617829.call(nil, query_617830, nil, formData_617831, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_617812(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_617813, base: "/",
    url: url_PostCreateDBSubnetGroup_617814, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_617793 = ref object of OpenApiRestCall_616850
proc url_GetCreateDBSubnetGroup_617795(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_617794(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the subnet group.
  ##   Version: JString (required)
  section = newJObject()
  var valid_617796 = query.getOrDefault("Tags")
  valid_617796 = validateParameter(valid_617796, JArray, required = false,
                                 default = nil)
  if valid_617796 != nil:
    section.add "Tags", valid_617796
  var valid_617797 = query.getOrDefault("Action")
  valid_617797 = validateParameter(valid_617797, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_617797 != nil:
    section.add "Action", valid_617797
  var valid_617798 = query.getOrDefault("DBSubnetGroupName")
  valid_617798 = validateParameter(valid_617798, JString, required = true,
                                 default = nil)
  if valid_617798 != nil:
    section.add "DBSubnetGroupName", valid_617798
  var valid_617799 = query.getOrDefault("SubnetIds")
  valid_617799 = validateParameter(valid_617799, JArray, required = true, default = nil)
  if valid_617799 != nil:
    section.add "SubnetIds", valid_617799
  var valid_617800 = query.getOrDefault("DBSubnetGroupDescription")
  valid_617800 = validateParameter(valid_617800, JString, required = true,
                                 default = nil)
  if valid_617800 != nil:
    section.add "DBSubnetGroupDescription", valid_617800
  var valid_617801 = query.getOrDefault("Version")
  valid_617801 = validateParameter(valid_617801, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617801 != nil:
    section.add "Version", valid_617801
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617802 = header.getOrDefault("X-Amz-Date")
  valid_617802 = validateParameter(valid_617802, JString, required = false,
                                 default = nil)
  if valid_617802 != nil:
    section.add "X-Amz-Date", valid_617802
  var valid_617803 = header.getOrDefault("X-Amz-Security-Token")
  valid_617803 = validateParameter(valid_617803, JString, required = false,
                                 default = nil)
  if valid_617803 != nil:
    section.add "X-Amz-Security-Token", valid_617803
  var valid_617804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617804 = validateParameter(valid_617804, JString, required = false,
                                 default = nil)
  if valid_617804 != nil:
    section.add "X-Amz-Content-Sha256", valid_617804
  var valid_617805 = header.getOrDefault("X-Amz-Algorithm")
  valid_617805 = validateParameter(valid_617805, JString, required = false,
                                 default = nil)
  if valid_617805 != nil:
    section.add "X-Amz-Algorithm", valid_617805
  var valid_617806 = header.getOrDefault("X-Amz-Signature")
  valid_617806 = validateParameter(valid_617806, JString, required = false,
                                 default = nil)
  if valid_617806 != nil:
    section.add "X-Amz-Signature", valid_617806
  var valid_617807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617807 = validateParameter(valid_617807, JString, required = false,
                                 default = nil)
  if valid_617807 != nil:
    section.add "X-Amz-SignedHeaders", valid_617807
  var valid_617808 = header.getOrDefault("X-Amz-Credential")
  valid_617808 = validateParameter(valid_617808, JString, required = false,
                                 default = nil)
  if valid_617808 != nil:
    section.add "X-Amz-Credential", valid_617808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617809: Call_GetCreateDBSubnetGroup_617793; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_617809.validator(path, query, header, formData, body, _)
  let scheme = call_617809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617809.url(scheme.get, call_617809.host, call_617809.base,
                         call_617809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617809, url, valid, _)

proc call*(call_617810: Call_GetCreateDBSubnetGroup_617793;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBSubnetGroup
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the subnet group.
  ##   Version: string (required)
  var query_617811 = newJObject()
  if Tags != nil:
    query_617811.add "Tags", Tags
  add(query_617811, "Action", newJString(Action))
  add(query_617811, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_617811.add "SubnetIds", SubnetIds
  add(query_617811, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_617811, "Version", newJString(Version))
  result = call_617810.call(nil, query_617811, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_617793(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_617794, base: "/",
    url: url_GetCreateDBSubnetGroup_617795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_617850 = ref object of OpenApiRestCall_616850
proc url_PostDeleteDBCluster_617852(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBCluster_617851(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617853 = query.getOrDefault("Action")
  valid_617853 = validateParameter(valid_617853, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_617853 != nil:
    section.add "Action", valid_617853
  var valid_617854 = query.getOrDefault("Version")
  valid_617854 = validateParameter(valid_617854, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617854 != nil:
    section.add "Version", valid_617854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617855 = header.getOrDefault("X-Amz-Date")
  valid_617855 = validateParameter(valid_617855, JString, required = false,
                                 default = nil)
  if valid_617855 != nil:
    section.add "X-Amz-Date", valid_617855
  var valid_617856 = header.getOrDefault("X-Amz-Security-Token")
  valid_617856 = validateParameter(valid_617856, JString, required = false,
                                 default = nil)
  if valid_617856 != nil:
    section.add "X-Amz-Security-Token", valid_617856
  var valid_617857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617857 = validateParameter(valid_617857, JString, required = false,
                                 default = nil)
  if valid_617857 != nil:
    section.add "X-Amz-Content-Sha256", valid_617857
  var valid_617858 = header.getOrDefault("X-Amz-Algorithm")
  valid_617858 = validateParameter(valid_617858, JString, required = false,
                                 default = nil)
  if valid_617858 != nil:
    section.add "X-Amz-Algorithm", valid_617858
  var valid_617859 = header.getOrDefault("X-Amz-Signature")
  valid_617859 = validateParameter(valid_617859, JString, required = false,
                                 default = nil)
  if valid_617859 != nil:
    section.add "X-Amz-Signature", valid_617859
  var valid_617860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617860 = validateParameter(valid_617860, JString, required = false,
                                 default = nil)
  if valid_617860 != nil:
    section.add "X-Amz-SignedHeaders", valid_617860
  var valid_617861 = header.getOrDefault("X-Amz-Credential")
  valid_617861 = validateParameter(valid_617861, JString, required = false,
                                 default = nil)
  if valid_617861 != nil:
    section.add "X-Amz-Credential", valid_617861
  result.add "header", section
  ## parameters in `formData` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The cluster snapshot identifier of the new cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final cluster snapshot is created before the cluster is deleted. If <code>true</code> is specified, no cluster snapshot is created. If <code>false</code> is specified, a cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_617862 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_617862 = validateParameter(valid_617862, JString, required = false,
                                 default = nil)
  if valid_617862 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_617862
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_617863 = formData.getOrDefault("DBClusterIdentifier")
  valid_617863 = validateParameter(valid_617863, JString, required = true,
                                 default = nil)
  if valid_617863 != nil:
    section.add "DBClusterIdentifier", valid_617863
  var valid_617864 = formData.getOrDefault("SkipFinalSnapshot")
  valid_617864 = validateParameter(valid_617864, JBool, required = false, default = nil)
  if valid_617864 != nil:
    section.add "SkipFinalSnapshot", valid_617864
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617865: Call_PostDeleteDBCluster_617850; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ## 
  let valid = call_617865.validator(path, query, header, formData, body, _)
  let scheme = call_617865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617865.url(scheme.get, call_617865.host, call_617865.base,
                         call_617865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617865, url, valid, _)

proc call*(call_617866: Call_PostDeleteDBCluster_617850;
          DBClusterIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBCluster"; Version: string = "2014-10-31";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBCluster
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The cluster snapshot identifier of the new cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final cluster snapshot is created before the cluster is deleted. If <code>true</code> is specified, no cluster snapshot is created. If <code>false</code> is specified, a cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  var query_617867 = newJObject()
  var formData_617868 = newJObject()
  add(formData_617868, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_617867, "Action", newJString(Action))
  add(formData_617868, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_617867, "Version", newJString(Version))
  add(formData_617868, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_617866.call(nil, query_617867, nil, formData_617868, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_617850(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_617851, base: "/",
    url: url_PostDeleteDBCluster_617852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_617832 = ref object of OpenApiRestCall_616850
proc url_GetDeleteDBCluster_617834(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBCluster_617833(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The cluster snapshot identifier of the new cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Action: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final cluster snapshot is created before the cluster is deleted. If <code>true</code> is specified, no cluster snapshot is created. If <code>false</code> is specified, a cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_617835 = query.getOrDefault("DBClusterIdentifier")
  valid_617835 = validateParameter(valid_617835, JString, required = true,
                                 default = nil)
  if valid_617835 != nil:
    section.add "DBClusterIdentifier", valid_617835
  var valid_617836 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_617836 = validateParameter(valid_617836, JString, required = false,
                                 default = nil)
  if valid_617836 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_617836
  var valid_617837 = query.getOrDefault("Action")
  valid_617837 = validateParameter(valid_617837, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_617837 != nil:
    section.add "Action", valid_617837
  var valid_617838 = query.getOrDefault("SkipFinalSnapshot")
  valid_617838 = validateParameter(valid_617838, JBool, required = false, default = nil)
  if valid_617838 != nil:
    section.add "SkipFinalSnapshot", valid_617838
  var valid_617839 = query.getOrDefault("Version")
  valid_617839 = validateParameter(valid_617839, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617839 != nil:
    section.add "Version", valid_617839
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617840 = header.getOrDefault("X-Amz-Date")
  valid_617840 = validateParameter(valid_617840, JString, required = false,
                                 default = nil)
  if valid_617840 != nil:
    section.add "X-Amz-Date", valid_617840
  var valid_617841 = header.getOrDefault("X-Amz-Security-Token")
  valid_617841 = validateParameter(valid_617841, JString, required = false,
                                 default = nil)
  if valid_617841 != nil:
    section.add "X-Amz-Security-Token", valid_617841
  var valid_617842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617842 = validateParameter(valid_617842, JString, required = false,
                                 default = nil)
  if valid_617842 != nil:
    section.add "X-Amz-Content-Sha256", valid_617842
  var valid_617843 = header.getOrDefault("X-Amz-Algorithm")
  valid_617843 = validateParameter(valid_617843, JString, required = false,
                                 default = nil)
  if valid_617843 != nil:
    section.add "X-Amz-Algorithm", valid_617843
  var valid_617844 = header.getOrDefault("X-Amz-Signature")
  valid_617844 = validateParameter(valid_617844, JString, required = false,
                                 default = nil)
  if valid_617844 != nil:
    section.add "X-Amz-Signature", valid_617844
  var valid_617845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617845 = validateParameter(valid_617845, JString, required = false,
                                 default = nil)
  if valid_617845 != nil:
    section.add "X-Amz-SignedHeaders", valid_617845
  var valid_617846 = header.getOrDefault("X-Amz-Credential")
  valid_617846 = validateParameter(valid_617846, JString, required = false,
                                 default = nil)
  if valid_617846 != nil:
    section.add "X-Amz-Credential", valid_617846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617847: Call_GetDeleteDBCluster_617832; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ## 
  let valid = call_617847.validator(path, query, header, formData, body, _)
  let scheme = call_617847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617847.url(scheme.get, call_617847.host, call_617847.base,
                         call_617847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617847, url, valid, _)

proc call*(call_617848: Call_GetDeleteDBCluster_617832;
          DBClusterIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBCluster"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBCluster
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The cluster snapshot identifier of the new cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final cluster snapshot is created before the cluster is deleted. If <code>true</code> is specified, no cluster snapshot is created. If <code>false</code> is specified, a cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Version: string (required)
  var query_617849 = newJObject()
  add(query_617849, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_617849, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_617849, "Action", newJString(Action))
  add(query_617849, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_617849, "Version", newJString(Version))
  result = call_617848.call(nil, query_617849, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_617832(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_617833,
    base: "/", url: url_GetDeleteDBCluster_617834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_617885 = ref object of OpenApiRestCall_616850
proc url_PostDeleteDBClusterParameterGroup_617887(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBClusterParameterGroup_617886(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_617888 = query.getOrDefault("Action")
  valid_617888 = validateParameter(valid_617888, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_617888 != nil:
    section.add "Action", valid_617888
  var valid_617889 = query.getOrDefault("Version")
  valid_617889 = validateParameter(valid_617889, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617889 != nil:
    section.add "Version", valid_617889
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617890 = header.getOrDefault("X-Amz-Date")
  valid_617890 = validateParameter(valid_617890, JString, required = false,
                                 default = nil)
  if valid_617890 != nil:
    section.add "X-Amz-Date", valid_617890
  var valid_617891 = header.getOrDefault("X-Amz-Security-Token")
  valid_617891 = validateParameter(valid_617891, JString, required = false,
                                 default = nil)
  if valid_617891 != nil:
    section.add "X-Amz-Security-Token", valid_617891
  var valid_617892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617892 = validateParameter(valid_617892, JString, required = false,
                                 default = nil)
  if valid_617892 != nil:
    section.add "X-Amz-Content-Sha256", valid_617892
  var valid_617893 = header.getOrDefault("X-Amz-Algorithm")
  valid_617893 = validateParameter(valid_617893, JString, required = false,
                                 default = nil)
  if valid_617893 != nil:
    section.add "X-Amz-Algorithm", valid_617893
  var valid_617894 = header.getOrDefault("X-Amz-Signature")
  valid_617894 = validateParameter(valid_617894, JString, required = false,
                                 default = nil)
  if valid_617894 != nil:
    section.add "X-Amz-Signature", valid_617894
  var valid_617895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617895 = validateParameter(valid_617895, JString, required = false,
                                 default = nil)
  if valid_617895 != nil:
    section.add "X-Amz-SignedHeaders", valid_617895
  var valid_617896 = header.getOrDefault("X-Amz-Credential")
  valid_617896 = validateParameter(valid_617896, JString, required = false,
                                 default = nil)
  if valid_617896 != nil:
    section.add "X-Amz-Credential", valid_617896
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_617897 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_617897 = validateParameter(valid_617897, JString, required = true,
                                 default = nil)
  if valid_617897 != nil:
    section.add "DBClusterParameterGroupName", valid_617897
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617898: Call_PostDeleteDBClusterParameterGroup_617885;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ## 
  let valid = call_617898.validator(path, query, header, formData, body, _)
  let scheme = call_617898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617898.url(scheme.get, call_617898.host, call_617898.base,
                         call_617898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617898, url, valid, _)

proc call*(call_617899: Call_PostDeleteDBClusterParameterGroup_617885;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_617900 = newJObject()
  var formData_617901 = newJObject()
  add(query_617900, "Action", newJString(Action))
  add(formData_617901, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_617900, "Version", newJString(Version))
  result = call_617899.call(nil, query_617900, nil, formData_617901, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_617885(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_617886, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_617887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_617869 = ref object of OpenApiRestCall_616850
proc url_GetDeleteDBClusterParameterGroup_617871(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBClusterParameterGroup_617870(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_617872 = query.getOrDefault("DBClusterParameterGroupName")
  valid_617872 = validateParameter(valid_617872, JString, required = true,
                                 default = nil)
  if valid_617872 != nil:
    section.add "DBClusterParameterGroupName", valid_617872
  var valid_617873 = query.getOrDefault("Action")
  valid_617873 = validateParameter(valid_617873, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_617873 != nil:
    section.add "Action", valid_617873
  var valid_617874 = query.getOrDefault("Version")
  valid_617874 = validateParameter(valid_617874, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617874 != nil:
    section.add "Version", valid_617874
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617875 = header.getOrDefault("X-Amz-Date")
  valid_617875 = validateParameter(valid_617875, JString, required = false,
                                 default = nil)
  if valid_617875 != nil:
    section.add "X-Amz-Date", valid_617875
  var valid_617876 = header.getOrDefault("X-Amz-Security-Token")
  valid_617876 = validateParameter(valid_617876, JString, required = false,
                                 default = nil)
  if valid_617876 != nil:
    section.add "X-Amz-Security-Token", valid_617876
  var valid_617877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617877 = validateParameter(valid_617877, JString, required = false,
                                 default = nil)
  if valid_617877 != nil:
    section.add "X-Amz-Content-Sha256", valid_617877
  var valid_617878 = header.getOrDefault("X-Amz-Algorithm")
  valid_617878 = validateParameter(valid_617878, JString, required = false,
                                 default = nil)
  if valid_617878 != nil:
    section.add "X-Amz-Algorithm", valid_617878
  var valid_617879 = header.getOrDefault("X-Amz-Signature")
  valid_617879 = validateParameter(valid_617879, JString, required = false,
                                 default = nil)
  if valid_617879 != nil:
    section.add "X-Amz-Signature", valid_617879
  var valid_617880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617880 = validateParameter(valid_617880, JString, required = false,
                                 default = nil)
  if valid_617880 != nil:
    section.add "X-Amz-SignedHeaders", valid_617880
  var valid_617881 = header.getOrDefault("X-Amz-Credential")
  valid_617881 = validateParameter(valid_617881, JString, required = false,
                                 default = nil)
  if valid_617881 != nil:
    section.add "X-Amz-Credential", valid_617881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617882: Call_GetDeleteDBClusterParameterGroup_617869;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ## 
  let valid = call_617882.validator(path, query, header, formData, body, _)
  let scheme = call_617882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617882.url(scheme.get, call_617882.host, call_617882.base,
                         call_617882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617882, url, valid, _)

proc call*(call_617883: Call_GetDeleteDBClusterParameterGroup_617869;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_617884 = newJObject()
  add(query_617884, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_617884, "Action", newJString(Action))
  add(query_617884, "Version", newJString(Version))
  result = call_617883.call(nil, query_617884, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_617869(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_617870, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_617871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_617918 = ref object of OpenApiRestCall_616850
proc url_PostDeleteDBClusterSnapshot_617920(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBClusterSnapshot_617919(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617921 = query.getOrDefault("Action")
  valid_617921 = validateParameter(valid_617921, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_617921 != nil:
    section.add "Action", valid_617921
  var valid_617922 = query.getOrDefault("Version")
  valid_617922 = validateParameter(valid_617922, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617922 != nil:
    section.add "Version", valid_617922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617923 = header.getOrDefault("X-Amz-Date")
  valid_617923 = validateParameter(valid_617923, JString, required = false,
                                 default = nil)
  if valid_617923 != nil:
    section.add "X-Amz-Date", valid_617923
  var valid_617924 = header.getOrDefault("X-Amz-Security-Token")
  valid_617924 = validateParameter(valid_617924, JString, required = false,
                                 default = nil)
  if valid_617924 != nil:
    section.add "X-Amz-Security-Token", valid_617924
  var valid_617925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617925 = validateParameter(valid_617925, JString, required = false,
                                 default = nil)
  if valid_617925 != nil:
    section.add "X-Amz-Content-Sha256", valid_617925
  var valid_617926 = header.getOrDefault("X-Amz-Algorithm")
  valid_617926 = validateParameter(valid_617926, JString, required = false,
                                 default = nil)
  if valid_617926 != nil:
    section.add "X-Amz-Algorithm", valid_617926
  var valid_617927 = header.getOrDefault("X-Amz-Signature")
  valid_617927 = validateParameter(valid_617927, JString, required = false,
                                 default = nil)
  if valid_617927 != nil:
    section.add "X-Amz-Signature", valid_617927
  var valid_617928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617928 = validateParameter(valid_617928, JString, required = false,
                                 default = nil)
  if valid_617928 != nil:
    section.add "X-Amz-SignedHeaders", valid_617928
  var valid_617929 = header.getOrDefault("X-Amz-Credential")
  valid_617929 = validateParameter(valid_617929, JString, required = false,
                                 default = nil)
  if valid_617929 != nil:
    section.add "X-Amz-Credential", valid_617929
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_617930 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_617930 = validateParameter(valid_617930, JString, required = true,
                                 default = nil)
  if valid_617930 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_617930
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617931: Call_PostDeleteDBClusterSnapshot_617918;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_617931.validator(path, query, header, formData, body, _)
  let scheme = call_617931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617931.url(scheme.get, call_617931.host, call_617931.base,
                         call_617931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617931, url, valid, _)

proc call*(call_617932: Call_PostDeleteDBClusterSnapshot_617918;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_617933 = newJObject()
  var formData_617934 = newJObject()
  add(formData_617934, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_617933, "Action", newJString(Action))
  add(query_617933, "Version", newJString(Version))
  result = call_617932.call(nil, query_617933, nil, formData_617934, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_617918(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_617919, base: "/",
    url: url_PostDeleteDBClusterSnapshot_617920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_617902 = ref object of OpenApiRestCall_616850
proc url_GetDeleteDBClusterSnapshot_617904(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBClusterSnapshot_617903(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617905 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_617905 = validateParameter(valid_617905, JString, required = true,
                                 default = nil)
  if valid_617905 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_617905
  var valid_617906 = query.getOrDefault("Action")
  valid_617906 = validateParameter(valid_617906, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_617906 != nil:
    section.add "Action", valid_617906
  var valid_617907 = query.getOrDefault("Version")
  valid_617907 = validateParameter(valid_617907, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617907 != nil:
    section.add "Version", valid_617907
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617908 = header.getOrDefault("X-Amz-Date")
  valid_617908 = validateParameter(valid_617908, JString, required = false,
                                 default = nil)
  if valid_617908 != nil:
    section.add "X-Amz-Date", valid_617908
  var valid_617909 = header.getOrDefault("X-Amz-Security-Token")
  valid_617909 = validateParameter(valid_617909, JString, required = false,
                                 default = nil)
  if valid_617909 != nil:
    section.add "X-Amz-Security-Token", valid_617909
  var valid_617910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617910 = validateParameter(valid_617910, JString, required = false,
                                 default = nil)
  if valid_617910 != nil:
    section.add "X-Amz-Content-Sha256", valid_617910
  var valid_617911 = header.getOrDefault("X-Amz-Algorithm")
  valid_617911 = validateParameter(valid_617911, JString, required = false,
                                 default = nil)
  if valid_617911 != nil:
    section.add "X-Amz-Algorithm", valid_617911
  var valid_617912 = header.getOrDefault("X-Amz-Signature")
  valid_617912 = validateParameter(valid_617912, JString, required = false,
                                 default = nil)
  if valid_617912 != nil:
    section.add "X-Amz-Signature", valid_617912
  var valid_617913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617913 = validateParameter(valid_617913, JString, required = false,
                                 default = nil)
  if valid_617913 != nil:
    section.add "X-Amz-SignedHeaders", valid_617913
  var valid_617914 = header.getOrDefault("X-Amz-Credential")
  valid_617914 = validateParameter(valid_617914, JString, required = false,
                                 default = nil)
  if valid_617914 != nil:
    section.add "X-Amz-Credential", valid_617914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617915: Call_GetDeleteDBClusterSnapshot_617902;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_617915.validator(path, query, header, formData, body, _)
  let scheme = call_617915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617915.url(scheme.get, call_617915.host, call_617915.base,
                         call_617915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617915, url, valid, _)

proc call*(call_617916: Call_GetDeleteDBClusterSnapshot_617902;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_617917 = newJObject()
  add(query_617917, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_617917, "Action", newJString(Action))
  add(query_617917, "Version", newJString(Version))
  result = call_617916.call(nil, query_617917, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_617902(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_617903, base: "/",
    url: url_GetDeleteDBClusterSnapshot_617904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_617951 = ref object of OpenApiRestCall_616850
proc url_PostDeleteDBInstance_617953(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_617952(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617954 = query.getOrDefault("Action")
  valid_617954 = validateParameter(valid_617954, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_617954 != nil:
    section.add "Action", valid_617954
  var valid_617955 = query.getOrDefault("Version")
  valid_617955 = validateParameter(valid_617955, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617955 != nil:
    section.add "Version", valid_617955
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617956 = header.getOrDefault("X-Amz-Date")
  valid_617956 = validateParameter(valid_617956, JString, required = false,
                                 default = nil)
  if valid_617956 != nil:
    section.add "X-Amz-Date", valid_617956
  var valid_617957 = header.getOrDefault("X-Amz-Security-Token")
  valid_617957 = validateParameter(valid_617957, JString, required = false,
                                 default = nil)
  if valid_617957 != nil:
    section.add "X-Amz-Security-Token", valid_617957
  var valid_617958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617958 = validateParameter(valid_617958, JString, required = false,
                                 default = nil)
  if valid_617958 != nil:
    section.add "X-Amz-Content-Sha256", valid_617958
  var valid_617959 = header.getOrDefault("X-Amz-Algorithm")
  valid_617959 = validateParameter(valid_617959, JString, required = false,
                                 default = nil)
  if valid_617959 != nil:
    section.add "X-Amz-Algorithm", valid_617959
  var valid_617960 = header.getOrDefault("X-Amz-Signature")
  valid_617960 = validateParameter(valid_617960, JString, required = false,
                                 default = nil)
  if valid_617960 != nil:
    section.add "X-Amz-Signature", valid_617960
  var valid_617961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617961 = validateParameter(valid_617961, JString, required = false,
                                 default = nil)
  if valid_617961 != nil:
    section.add "X-Amz-SignedHeaders", valid_617961
  var valid_617962 = header.getOrDefault("X-Amz-Credential")
  valid_617962 = validateParameter(valid_617962, JString, required = false,
                                 default = nil)
  if valid_617962 != nil:
    section.add "X-Amz-Credential", valid_617962
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_617963 = formData.getOrDefault("DBInstanceIdentifier")
  valid_617963 = validateParameter(valid_617963, JString, required = true,
                                 default = nil)
  if valid_617963 != nil:
    section.add "DBInstanceIdentifier", valid_617963
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617964: Call_PostDeleteDBInstance_617951; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a previously provisioned instance. 
  ## 
  let valid = call_617964.validator(path, query, header, formData, body, _)
  let scheme = call_617964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617964.url(scheme.get, call_617964.host, call_617964.base,
                         call_617964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617964, url, valid, _)

proc call*(call_617965: Call_PostDeleteDBInstance_617951;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_617966 = newJObject()
  var formData_617967 = newJObject()
  add(formData_617967, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_617966, "Action", newJString(Action))
  add(query_617966, "Version", newJString(Version))
  result = call_617965.call(nil, query_617966, nil, formData_617967, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_617951(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_617952, base: "/",
    url: url_PostDeleteDBInstance_617953, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_617935 = ref object of OpenApiRestCall_616850
proc url_GetDeleteDBInstance_617937(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_617936(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## Deletes a previously provisioned instance. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  section = newJObject()
  var valid_617938 = query.getOrDefault("Action")
  valid_617938 = validateParameter(valid_617938, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_617938 != nil:
    section.add "Action", valid_617938
  var valid_617939 = query.getOrDefault("Version")
  valid_617939 = validateParameter(valid_617939, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617939 != nil:
    section.add "Version", valid_617939
  var valid_617940 = query.getOrDefault("DBInstanceIdentifier")
  valid_617940 = validateParameter(valid_617940, JString, required = true,
                                 default = nil)
  if valid_617940 != nil:
    section.add "DBInstanceIdentifier", valid_617940
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617941 = header.getOrDefault("X-Amz-Date")
  valid_617941 = validateParameter(valid_617941, JString, required = false,
                                 default = nil)
  if valid_617941 != nil:
    section.add "X-Amz-Date", valid_617941
  var valid_617942 = header.getOrDefault("X-Amz-Security-Token")
  valid_617942 = validateParameter(valid_617942, JString, required = false,
                                 default = nil)
  if valid_617942 != nil:
    section.add "X-Amz-Security-Token", valid_617942
  var valid_617943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617943 = validateParameter(valid_617943, JString, required = false,
                                 default = nil)
  if valid_617943 != nil:
    section.add "X-Amz-Content-Sha256", valid_617943
  var valid_617944 = header.getOrDefault("X-Amz-Algorithm")
  valid_617944 = validateParameter(valid_617944, JString, required = false,
                                 default = nil)
  if valid_617944 != nil:
    section.add "X-Amz-Algorithm", valid_617944
  var valid_617945 = header.getOrDefault("X-Amz-Signature")
  valid_617945 = validateParameter(valid_617945, JString, required = false,
                                 default = nil)
  if valid_617945 != nil:
    section.add "X-Amz-Signature", valid_617945
  var valid_617946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617946 = validateParameter(valid_617946, JString, required = false,
                                 default = nil)
  if valid_617946 != nil:
    section.add "X-Amz-SignedHeaders", valid_617946
  var valid_617947 = header.getOrDefault("X-Amz-Credential")
  valid_617947 = validateParameter(valid_617947, JString, required = false,
                                 default = nil)
  if valid_617947 != nil:
    section.add "X-Amz-Credential", valid_617947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617948: Call_GetDeleteDBInstance_617935; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a previously provisioned instance. 
  ## 
  let valid = call_617948.validator(path, query, header, formData, body, _)
  let scheme = call_617948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617948.url(scheme.get, call_617948.host, call_617948.base,
                         call_617948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617948, url, valid, _)

proc call*(call_617949: Call_GetDeleteDBInstance_617935;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned instance. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  var query_617950 = newJObject()
  add(query_617950, "Action", newJString(Action))
  add(query_617950, "Version", newJString(Version))
  add(query_617950, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_617949.call(nil, query_617950, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_617935(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_617936, base: "/",
    url: url_GetDeleteDBInstance_617937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_617984 = ref object of OpenApiRestCall_616850
proc url_PostDeleteDBSubnetGroup_617986(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_617985(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617987 = query.getOrDefault("Action")
  valid_617987 = validateParameter(valid_617987, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_617987 != nil:
    section.add "Action", valid_617987
  var valid_617988 = query.getOrDefault("Version")
  valid_617988 = validateParameter(valid_617988, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617988 != nil:
    section.add "Version", valid_617988
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617989 = header.getOrDefault("X-Amz-Date")
  valid_617989 = validateParameter(valid_617989, JString, required = false,
                                 default = nil)
  if valid_617989 != nil:
    section.add "X-Amz-Date", valid_617989
  var valid_617990 = header.getOrDefault("X-Amz-Security-Token")
  valid_617990 = validateParameter(valid_617990, JString, required = false,
                                 default = nil)
  if valid_617990 != nil:
    section.add "X-Amz-Security-Token", valid_617990
  var valid_617991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617991 = validateParameter(valid_617991, JString, required = false,
                                 default = nil)
  if valid_617991 != nil:
    section.add "X-Amz-Content-Sha256", valid_617991
  var valid_617992 = header.getOrDefault("X-Amz-Algorithm")
  valid_617992 = validateParameter(valid_617992, JString, required = false,
                                 default = nil)
  if valid_617992 != nil:
    section.add "X-Amz-Algorithm", valid_617992
  var valid_617993 = header.getOrDefault("X-Amz-Signature")
  valid_617993 = validateParameter(valid_617993, JString, required = false,
                                 default = nil)
  if valid_617993 != nil:
    section.add "X-Amz-Signature", valid_617993
  var valid_617994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617994 = validateParameter(valid_617994, JString, required = false,
                                 default = nil)
  if valid_617994 != nil:
    section.add "X-Amz-SignedHeaders", valid_617994
  var valid_617995 = header.getOrDefault("X-Amz-Credential")
  valid_617995 = validateParameter(valid_617995, JString, required = false,
                                 default = nil)
  if valid_617995 != nil:
    section.add "X-Amz-Credential", valid_617995
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_617996 = formData.getOrDefault("DBSubnetGroupName")
  valid_617996 = validateParameter(valid_617996, JString, required = true,
                                 default = nil)
  if valid_617996 != nil:
    section.add "DBSubnetGroupName", valid_617996
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617997: Call_PostDeleteDBSubnetGroup_617984; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_617997.validator(path, query, header, formData, body, _)
  let scheme = call_617997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617997.url(scheme.get, call_617997.host, call_617997.base,
                         call_617997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617997, url, valid, _)

proc call*(call_617998: Call_PostDeleteDBSubnetGroup_617984;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_617999 = newJObject()
  var formData_618000 = newJObject()
  add(formData_618000, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_617999, "Action", newJString(Action))
  add(query_617999, "Version", newJString(Version))
  result = call_617998.call(nil, query_617999, nil, formData_618000, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_617984(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_617985, base: "/",
    url: url_PostDeleteDBSubnetGroup_617986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_617968 = ref object of OpenApiRestCall_616850
proc url_GetDeleteDBSubnetGroup_617970(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_617969(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617971 = query.getOrDefault("Action")
  valid_617971 = validateParameter(valid_617971, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_617971 != nil:
    section.add "Action", valid_617971
  var valid_617972 = query.getOrDefault("DBSubnetGroupName")
  valid_617972 = validateParameter(valid_617972, JString, required = true,
                                 default = nil)
  if valid_617972 != nil:
    section.add "DBSubnetGroupName", valid_617972
  var valid_617973 = query.getOrDefault("Version")
  valid_617973 = validateParameter(valid_617973, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_617973 != nil:
    section.add "Version", valid_617973
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617974 = header.getOrDefault("X-Amz-Date")
  valid_617974 = validateParameter(valid_617974, JString, required = false,
                                 default = nil)
  if valid_617974 != nil:
    section.add "X-Amz-Date", valid_617974
  var valid_617975 = header.getOrDefault("X-Amz-Security-Token")
  valid_617975 = validateParameter(valid_617975, JString, required = false,
                                 default = nil)
  if valid_617975 != nil:
    section.add "X-Amz-Security-Token", valid_617975
  var valid_617976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617976 = validateParameter(valid_617976, JString, required = false,
                                 default = nil)
  if valid_617976 != nil:
    section.add "X-Amz-Content-Sha256", valid_617976
  var valid_617977 = header.getOrDefault("X-Amz-Algorithm")
  valid_617977 = validateParameter(valid_617977, JString, required = false,
                                 default = nil)
  if valid_617977 != nil:
    section.add "X-Amz-Algorithm", valid_617977
  var valid_617978 = header.getOrDefault("X-Amz-Signature")
  valid_617978 = validateParameter(valid_617978, JString, required = false,
                                 default = nil)
  if valid_617978 != nil:
    section.add "X-Amz-Signature", valid_617978
  var valid_617979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617979 = validateParameter(valid_617979, JString, required = false,
                                 default = nil)
  if valid_617979 != nil:
    section.add "X-Amz-SignedHeaders", valid_617979
  var valid_617980 = header.getOrDefault("X-Amz-Credential")
  valid_617980 = validateParameter(valid_617980, JString, required = false,
                                 default = nil)
  if valid_617980 != nil:
    section.add "X-Amz-Credential", valid_617980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617981: Call_GetDeleteDBSubnetGroup_617968; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_617981.validator(path, query, header, formData, body, _)
  let scheme = call_617981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617981.url(scheme.get, call_617981.host, call_617981.base,
                         call_617981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617981, url, valid, _)

proc call*(call_617982: Call_GetDeleteDBSubnetGroup_617968;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_617983 = newJObject()
  add(query_617983, "Action", newJString(Action))
  add(query_617983, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_617983, "Version", newJString(Version))
  result = call_617982.call(nil, query_617983, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_617968(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_617969, base: "/",
    url: url_GetDeleteDBSubnetGroup_617970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeCertificates_618020 = ref object of OpenApiRestCall_616850
proc url_PostDescribeCertificates_618022(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeCertificates_618021(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_618023 = query.getOrDefault("Action")
  valid_618023 = validateParameter(valid_618023, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_618023 != nil:
    section.add "Action", valid_618023
  var valid_618024 = query.getOrDefault("Version")
  valid_618024 = validateParameter(valid_618024, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618024 != nil:
    section.add "Version", valid_618024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618025 = header.getOrDefault("X-Amz-Date")
  valid_618025 = validateParameter(valid_618025, JString, required = false,
                                 default = nil)
  if valid_618025 != nil:
    section.add "X-Amz-Date", valid_618025
  var valid_618026 = header.getOrDefault("X-Amz-Security-Token")
  valid_618026 = validateParameter(valid_618026, JString, required = false,
                                 default = nil)
  if valid_618026 != nil:
    section.add "X-Amz-Security-Token", valid_618026
  var valid_618027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618027 = validateParameter(valid_618027, JString, required = false,
                                 default = nil)
  if valid_618027 != nil:
    section.add "X-Amz-Content-Sha256", valid_618027
  var valid_618028 = header.getOrDefault("X-Amz-Algorithm")
  valid_618028 = validateParameter(valid_618028, JString, required = false,
                                 default = nil)
  if valid_618028 != nil:
    section.add "X-Amz-Algorithm", valid_618028
  var valid_618029 = header.getOrDefault("X-Amz-Signature")
  valid_618029 = validateParameter(valid_618029, JString, required = false,
                                 default = nil)
  if valid_618029 != nil:
    section.add "X-Amz-Signature", valid_618029
  var valid_618030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618030 = validateParameter(valid_618030, JString, required = false,
                                 default = nil)
  if valid_618030 != nil:
    section.add "X-Amz-SignedHeaders", valid_618030
  var valid_618031 = header.getOrDefault("X-Amz-Credential")
  valid_618031 = validateParameter(valid_618031, JString, required = false,
                                 default = nil)
  if valid_618031 != nil:
    section.add "X-Amz-Credential", valid_618031
  result.add "header", section
  ## parameters in `formData` object:
  ##   CertificateIdentifier: JString
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  section = newJObject()
  var valid_618032 = formData.getOrDefault("CertificateIdentifier")
  valid_618032 = validateParameter(valid_618032, JString, required = false,
                                 default = nil)
  if valid_618032 != nil:
    section.add "CertificateIdentifier", valid_618032
  var valid_618033 = formData.getOrDefault("Filters")
  valid_618033 = validateParameter(valid_618033, JArray, required = false,
                                 default = nil)
  if valid_618033 != nil:
    section.add "Filters", valid_618033
  var valid_618034 = formData.getOrDefault("Marker")
  valid_618034 = validateParameter(valid_618034, JString, required = false,
                                 default = nil)
  if valid_618034 != nil:
    section.add "Marker", valid_618034
  var valid_618035 = formData.getOrDefault("MaxRecords")
  valid_618035 = validateParameter(valid_618035, JInt, required = false, default = nil)
  if valid_618035 != nil:
    section.add "MaxRecords", valid_618035
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618036: Call_PostDescribeCertificates_618020; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account.
  ## 
  let valid = call_618036.validator(path, query, header, formData, body, _)
  let scheme = call_618036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618036.url(scheme.get, call_618036.host, call_618036.base,
                         call_618036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618036, url, valid, _)

proc call*(call_618037: Call_PostDescribeCertificates_618020;
          CertificateIdentifier: string = "";
          Action: string = "DescribeCertificates"; Filters: JsonNode = nil;
          Marker: string = ""; MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account.
  ##   CertificateIdentifier: string
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  ##   Version: string (required)
  var query_618038 = newJObject()
  var formData_618039 = newJObject()
  add(formData_618039, "CertificateIdentifier", newJString(CertificateIdentifier))
  add(query_618038, "Action", newJString(Action))
  if Filters != nil:
    formData_618039.add "Filters", Filters
  add(formData_618039, "Marker", newJString(Marker))
  add(formData_618039, "MaxRecords", newJInt(MaxRecords))
  add(query_618038, "Version", newJString(Version))
  result = call_618037.call(nil, query_618038, nil, formData_618039, nil)

var postDescribeCertificates* = Call_PostDescribeCertificates_618020(
    name: "postDescribeCertificates", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_PostDescribeCertificates_618021, base: "/",
    url: url_PostDescribeCertificates_618022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeCertificates_618001 = ref object of OpenApiRestCall_616850
proc url_GetDescribeCertificates_618003(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeCertificates_618002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  ##   CertificateIdentifier: JString
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_618004 = query.getOrDefault("MaxRecords")
  valid_618004 = validateParameter(valid_618004, JInt, required = false, default = nil)
  if valid_618004 != nil:
    section.add "MaxRecords", valid_618004
  var valid_618005 = query.getOrDefault("CertificateIdentifier")
  valid_618005 = validateParameter(valid_618005, JString, required = false,
                                 default = nil)
  if valid_618005 != nil:
    section.add "CertificateIdentifier", valid_618005
  var valid_618006 = query.getOrDefault("Filters")
  valid_618006 = validateParameter(valid_618006, JArray, required = false,
                                 default = nil)
  if valid_618006 != nil:
    section.add "Filters", valid_618006
  var valid_618007 = query.getOrDefault("Action")
  valid_618007 = validateParameter(valid_618007, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_618007 != nil:
    section.add "Action", valid_618007
  var valid_618008 = query.getOrDefault("Marker")
  valid_618008 = validateParameter(valid_618008, JString, required = false,
                                 default = nil)
  if valid_618008 != nil:
    section.add "Marker", valid_618008
  var valid_618009 = query.getOrDefault("Version")
  valid_618009 = validateParameter(valid_618009, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618009 != nil:
    section.add "Version", valid_618009
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618010 = header.getOrDefault("X-Amz-Date")
  valid_618010 = validateParameter(valid_618010, JString, required = false,
                                 default = nil)
  if valid_618010 != nil:
    section.add "X-Amz-Date", valid_618010
  var valid_618011 = header.getOrDefault("X-Amz-Security-Token")
  valid_618011 = validateParameter(valid_618011, JString, required = false,
                                 default = nil)
  if valid_618011 != nil:
    section.add "X-Amz-Security-Token", valid_618011
  var valid_618012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618012 = validateParameter(valid_618012, JString, required = false,
                                 default = nil)
  if valid_618012 != nil:
    section.add "X-Amz-Content-Sha256", valid_618012
  var valid_618013 = header.getOrDefault("X-Amz-Algorithm")
  valid_618013 = validateParameter(valid_618013, JString, required = false,
                                 default = nil)
  if valid_618013 != nil:
    section.add "X-Amz-Algorithm", valid_618013
  var valid_618014 = header.getOrDefault("X-Amz-Signature")
  valid_618014 = validateParameter(valid_618014, JString, required = false,
                                 default = nil)
  if valid_618014 != nil:
    section.add "X-Amz-Signature", valid_618014
  var valid_618015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618015 = validateParameter(valid_618015, JString, required = false,
                                 default = nil)
  if valid_618015 != nil:
    section.add "X-Amz-SignedHeaders", valid_618015
  var valid_618016 = header.getOrDefault("X-Amz-Credential")
  valid_618016 = validateParameter(valid_618016, JString, required = false,
                                 default = nil)
  if valid_618016 != nil:
    section.add "X-Amz-Credential", valid_618016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618017: Call_GetDescribeCertificates_618001; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account.
  ## 
  let valid = call_618017.validator(path, query, header, formData, body, _)
  let scheme = call_618017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618017.url(scheme.get, call_618017.host, call_618017.base,
                         call_618017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618017, url, valid, _)

proc call*(call_618018: Call_GetDescribeCertificates_618001; MaxRecords: int = 0;
          CertificateIdentifier: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeCertificates"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account.
  ##   MaxRecords: int
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  ##   CertificateIdentifier: string
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_618019 = newJObject()
  add(query_618019, "MaxRecords", newJInt(MaxRecords))
  add(query_618019, "CertificateIdentifier", newJString(CertificateIdentifier))
  if Filters != nil:
    query_618019.add "Filters", Filters
  add(query_618019, "Action", newJString(Action))
  add(query_618019, "Marker", newJString(Marker))
  add(query_618019, "Version", newJString(Version))
  result = call_618018.call(nil, query_618019, nil, nil, nil)

var getDescribeCertificates* = Call_GetDescribeCertificates_618001(
    name: "getDescribeCertificates", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_GetDescribeCertificates_618002, base: "/",
    url: url_GetDescribeCertificates_618003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_618059 = ref object of OpenApiRestCall_616850
proc url_PostDescribeDBClusterParameterGroups_618061(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterParameterGroups_618060(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618062 = query.getOrDefault("Action")
  valid_618062 = validateParameter(valid_618062, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_618062 != nil:
    section.add "Action", valid_618062
  var valid_618063 = query.getOrDefault("Version")
  valid_618063 = validateParameter(valid_618063, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618063 != nil:
    section.add "Version", valid_618063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618064 = header.getOrDefault("X-Amz-Date")
  valid_618064 = validateParameter(valid_618064, JString, required = false,
                                 default = nil)
  if valid_618064 != nil:
    section.add "X-Amz-Date", valid_618064
  var valid_618065 = header.getOrDefault("X-Amz-Security-Token")
  valid_618065 = validateParameter(valid_618065, JString, required = false,
                                 default = nil)
  if valid_618065 != nil:
    section.add "X-Amz-Security-Token", valid_618065
  var valid_618066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618066 = validateParameter(valid_618066, JString, required = false,
                                 default = nil)
  if valid_618066 != nil:
    section.add "X-Amz-Content-Sha256", valid_618066
  var valid_618067 = header.getOrDefault("X-Amz-Algorithm")
  valid_618067 = validateParameter(valid_618067, JString, required = false,
                                 default = nil)
  if valid_618067 != nil:
    section.add "X-Amz-Algorithm", valid_618067
  var valid_618068 = header.getOrDefault("X-Amz-Signature")
  valid_618068 = validateParameter(valid_618068, JString, required = false,
                                 default = nil)
  if valid_618068 != nil:
    section.add "X-Amz-Signature", valid_618068
  var valid_618069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618069 = validateParameter(valid_618069, JString, required = false,
                                 default = nil)
  if valid_618069 != nil:
    section.add "X-Amz-SignedHeaders", valid_618069
  var valid_618070 = header.getOrDefault("X-Amz-Credential")
  valid_618070 = validateParameter(valid_618070, JString, required = false,
                                 default = nil)
  if valid_618070 != nil:
    section.add "X-Amz-Credential", valid_618070
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_618071 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_618071 = validateParameter(valid_618071, JString, required = false,
                                 default = nil)
  if valid_618071 != nil:
    section.add "DBClusterParameterGroupName", valid_618071
  var valid_618072 = formData.getOrDefault("Filters")
  valid_618072 = validateParameter(valid_618072, JArray, required = false,
                                 default = nil)
  if valid_618072 != nil:
    section.add "Filters", valid_618072
  var valid_618073 = formData.getOrDefault("Marker")
  valid_618073 = validateParameter(valid_618073, JString, required = false,
                                 default = nil)
  if valid_618073 != nil:
    section.add "Marker", valid_618073
  var valid_618074 = formData.getOrDefault("MaxRecords")
  valid_618074 = validateParameter(valid_618074, JInt, required = false, default = nil)
  if valid_618074 != nil:
    section.add "MaxRecords", valid_618074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618075: Call_PostDescribeDBClusterParameterGroups_618059;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ## 
  let valid = call_618075.validator(path, query, header, formData, body, _)
  let scheme = call_618075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618075.url(scheme.get, call_618075.host, call_618075.base,
                         call_618075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618075, url, valid, _)

proc call*(call_618076: Call_PostDescribeDBClusterParameterGroups_618059;
          Action: string = "DescribeDBClusterParameterGroups";
          DBClusterParameterGroupName: string = ""; Filters: JsonNode = nil;
          Marker: string = ""; MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_618077 = newJObject()
  var formData_618078 = newJObject()
  add(query_618077, "Action", newJString(Action))
  add(formData_618078, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_618078.add "Filters", Filters
  add(formData_618078, "Marker", newJString(Marker))
  add(formData_618078, "MaxRecords", newJInt(MaxRecords))
  add(query_618077, "Version", newJString(Version))
  result = call_618076.call(nil, query_618077, nil, formData_618078, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_618059(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_618060, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_618061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_618040 = ref object of OpenApiRestCall_616850
proc url_GetDescribeDBClusterParameterGroups_618042(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterParameterGroups_618041(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_618043 = query.getOrDefault("MaxRecords")
  valid_618043 = validateParameter(valid_618043, JInt, required = false, default = nil)
  if valid_618043 != nil:
    section.add "MaxRecords", valid_618043
  var valid_618044 = query.getOrDefault("DBClusterParameterGroupName")
  valid_618044 = validateParameter(valid_618044, JString, required = false,
                                 default = nil)
  if valid_618044 != nil:
    section.add "DBClusterParameterGroupName", valid_618044
  var valid_618045 = query.getOrDefault("Filters")
  valid_618045 = validateParameter(valid_618045, JArray, required = false,
                                 default = nil)
  if valid_618045 != nil:
    section.add "Filters", valid_618045
  var valid_618046 = query.getOrDefault("Action")
  valid_618046 = validateParameter(valid_618046, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_618046 != nil:
    section.add "Action", valid_618046
  var valid_618047 = query.getOrDefault("Marker")
  valid_618047 = validateParameter(valid_618047, JString, required = false,
                                 default = nil)
  if valid_618047 != nil:
    section.add "Marker", valid_618047
  var valid_618048 = query.getOrDefault("Version")
  valid_618048 = validateParameter(valid_618048, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618048 != nil:
    section.add "Version", valid_618048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618049 = header.getOrDefault("X-Amz-Date")
  valid_618049 = validateParameter(valid_618049, JString, required = false,
                                 default = nil)
  if valid_618049 != nil:
    section.add "X-Amz-Date", valid_618049
  var valid_618050 = header.getOrDefault("X-Amz-Security-Token")
  valid_618050 = validateParameter(valid_618050, JString, required = false,
                                 default = nil)
  if valid_618050 != nil:
    section.add "X-Amz-Security-Token", valid_618050
  var valid_618051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618051 = validateParameter(valid_618051, JString, required = false,
                                 default = nil)
  if valid_618051 != nil:
    section.add "X-Amz-Content-Sha256", valid_618051
  var valid_618052 = header.getOrDefault("X-Amz-Algorithm")
  valid_618052 = validateParameter(valid_618052, JString, required = false,
                                 default = nil)
  if valid_618052 != nil:
    section.add "X-Amz-Algorithm", valid_618052
  var valid_618053 = header.getOrDefault("X-Amz-Signature")
  valid_618053 = validateParameter(valid_618053, JString, required = false,
                                 default = nil)
  if valid_618053 != nil:
    section.add "X-Amz-Signature", valid_618053
  var valid_618054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618054 = validateParameter(valid_618054, JString, required = false,
                                 default = nil)
  if valid_618054 != nil:
    section.add "X-Amz-SignedHeaders", valid_618054
  var valid_618055 = header.getOrDefault("X-Amz-Credential")
  valid_618055 = validateParameter(valid_618055, JString, required = false,
                                 default = nil)
  if valid_618055 != nil:
    section.add "X-Amz-Credential", valid_618055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618056: Call_GetDescribeDBClusterParameterGroups_618040;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ## 
  let valid = call_618056.validator(path, query, header, formData, body, _)
  let scheme = call_618056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618056.url(scheme.get, call_618056.host, call_618056.base,
                         call_618056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618056, url, valid, _)

proc call*(call_618057: Call_GetDescribeDBClusterParameterGroups_618040;
          MaxRecords: int = 0; DBClusterParameterGroupName: string = "";
          Filters: JsonNode = nil;
          Action: string = "DescribeDBClusterParameterGroups"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_618058 = newJObject()
  add(query_618058, "MaxRecords", newJInt(MaxRecords))
  add(query_618058, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_618058.add "Filters", Filters
  add(query_618058, "Action", newJString(Action))
  add(query_618058, "Marker", newJString(Marker))
  add(query_618058, "Version", newJString(Version))
  result = call_618057.call(nil, query_618058, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_618040(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_618041, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_618042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_618099 = ref object of OpenApiRestCall_616850
proc url_PostDescribeDBClusterParameters_618101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterParameters_618100(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618102 = query.getOrDefault("Action")
  valid_618102 = validateParameter(valid_618102, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_618102 != nil:
    section.add "Action", valid_618102
  var valid_618103 = query.getOrDefault("Version")
  valid_618103 = validateParameter(valid_618103, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618103 != nil:
    section.add "Version", valid_618103
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618104 = header.getOrDefault("X-Amz-Date")
  valid_618104 = validateParameter(valid_618104, JString, required = false,
                                 default = nil)
  if valid_618104 != nil:
    section.add "X-Amz-Date", valid_618104
  var valid_618105 = header.getOrDefault("X-Amz-Security-Token")
  valid_618105 = validateParameter(valid_618105, JString, required = false,
                                 default = nil)
  if valid_618105 != nil:
    section.add "X-Amz-Security-Token", valid_618105
  var valid_618106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618106 = validateParameter(valid_618106, JString, required = false,
                                 default = nil)
  if valid_618106 != nil:
    section.add "X-Amz-Content-Sha256", valid_618106
  var valid_618107 = header.getOrDefault("X-Amz-Algorithm")
  valid_618107 = validateParameter(valid_618107, JString, required = false,
                                 default = nil)
  if valid_618107 != nil:
    section.add "X-Amz-Algorithm", valid_618107
  var valid_618108 = header.getOrDefault("X-Amz-Signature")
  valid_618108 = validateParameter(valid_618108, JString, required = false,
                                 default = nil)
  if valid_618108 != nil:
    section.add "X-Amz-Signature", valid_618108
  var valid_618109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618109 = validateParameter(valid_618109, JString, required = false,
                                 default = nil)
  if valid_618109 != nil:
    section.add "X-Amz-SignedHeaders", valid_618109
  var valid_618110 = header.getOrDefault("X-Amz-Credential")
  valid_618110 = validateParameter(valid_618110, JString, required = false,
                                 default = nil)
  if valid_618110 != nil:
    section.add "X-Amz-Credential", valid_618110
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Source: JString
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_618111 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_618111 = validateParameter(valid_618111, JString, required = true,
                                 default = nil)
  if valid_618111 != nil:
    section.add "DBClusterParameterGroupName", valid_618111
  var valid_618112 = formData.getOrDefault("Filters")
  valid_618112 = validateParameter(valid_618112, JArray, required = false,
                                 default = nil)
  if valid_618112 != nil:
    section.add "Filters", valid_618112
  var valid_618113 = formData.getOrDefault("Marker")
  valid_618113 = validateParameter(valid_618113, JString, required = false,
                                 default = nil)
  if valid_618113 != nil:
    section.add "Marker", valid_618113
  var valid_618114 = formData.getOrDefault("MaxRecords")
  valid_618114 = validateParameter(valid_618114, JInt, required = false, default = nil)
  if valid_618114 != nil:
    section.add "MaxRecords", valid_618114
  var valid_618115 = formData.getOrDefault("Source")
  valid_618115 = validateParameter(valid_618115, JString, required = false,
                                 default = nil)
  if valid_618115 != nil:
    section.add "Source", valid_618115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618116: Call_PostDescribeDBClusterParameters_618099;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ## 
  let valid = call_618116.validator(path, query, header, formData, body, _)
  let scheme = call_618116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618116.url(scheme.get, call_618116.host, call_618116.base,
                         call_618116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618116, url, valid, _)

proc call*(call_618117: Call_PostDescribeDBClusterParameters_618099;
          DBClusterParameterGroupName: string;
          Action: string = "DescribeDBClusterParameters"; Filters: JsonNode = nil;
          Marker: string = ""; MaxRecords: int = 0; Version: string = "2014-10-31";
          Source: string = ""): Recallable =
  ## postDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  var query_618118 = newJObject()
  var formData_618119 = newJObject()
  add(query_618118, "Action", newJString(Action))
  add(formData_618119, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_618119.add "Filters", Filters
  add(formData_618119, "Marker", newJString(Marker))
  add(formData_618119, "MaxRecords", newJInt(MaxRecords))
  add(query_618118, "Version", newJString(Version))
  add(formData_618119, "Source", newJString(Source))
  result = call_618117.call(nil, query_618118, nil, formData_618119, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_618099(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_618100, base: "/",
    url: url_PostDescribeDBClusterParameters_618101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_618079 = ref object of OpenApiRestCall_616850
proc url_GetDescribeDBClusterParameters_618081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterParameters_618080(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Source: JString
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   Version: JString (required)
  section = newJObject()
  var valid_618082 = query.getOrDefault("MaxRecords")
  valid_618082 = validateParameter(valid_618082, JInt, required = false, default = nil)
  if valid_618082 != nil:
    section.add "MaxRecords", valid_618082
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_618083 = query.getOrDefault("DBClusterParameterGroupName")
  valid_618083 = validateParameter(valid_618083, JString, required = true,
                                 default = nil)
  if valid_618083 != nil:
    section.add "DBClusterParameterGroupName", valid_618083
  var valid_618084 = query.getOrDefault("Filters")
  valid_618084 = validateParameter(valid_618084, JArray, required = false,
                                 default = nil)
  if valid_618084 != nil:
    section.add "Filters", valid_618084
  var valid_618085 = query.getOrDefault("Action")
  valid_618085 = validateParameter(valid_618085, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_618085 != nil:
    section.add "Action", valid_618085
  var valid_618086 = query.getOrDefault("Marker")
  valid_618086 = validateParameter(valid_618086, JString, required = false,
                                 default = nil)
  if valid_618086 != nil:
    section.add "Marker", valid_618086
  var valid_618087 = query.getOrDefault("Source")
  valid_618087 = validateParameter(valid_618087, JString, required = false,
                                 default = nil)
  if valid_618087 != nil:
    section.add "Source", valid_618087
  var valid_618088 = query.getOrDefault("Version")
  valid_618088 = validateParameter(valid_618088, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618088 != nil:
    section.add "Version", valid_618088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618089 = header.getOrDefault("X-Amz-Date")
  valid_618089 = validateParameter(valid_618089, JString, required = false,
                                 default = nil)
  if valid_618089 != nil:
    section.add "X-Amz-Date", valid_618089
  var valid_618090 = header.getOrDefault("X-Amz-Security-Token")
  valid_618090 = validateParameter(valid_618090, JString, required = false,
                                 default = nil)
  if valid_618090 != nil:
    section.add "X-Amz-Security-Token", valid_618090
  var valid_618091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618091 = validateParameter(valid_618091, JString, required = false,
                                 default = nil)
  if valid_618091 != nil:
    section.add "X-Amz-Content-Sha256", valid_618091
  var valid_618092 = header.getOrDefault("X-Amz-Algorithm")
  valid_618092 = validateParameter(valid_618092, JString, required = false,
                                 default = nil)
  if valid_618092 != nil:
    section.add "X-Amz-Algorithm", valid_618092
  var valid_618093 = header.getOrDefault("X-Amz-Signature")
  valid_618093 = validateParameter(valid_618093, JString, required = false,
                                 default = nil)
  if valid_618093 != nil:
    section.add "X-Amz-Signature", valid_618093
  var valid_618094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618094 = validateParameter(valid_618094, JString, required = false,
                                 default = nil)
  if valid_618094 != nil:
    section.add "X-Amz-SignedHeaders", valid_618094
  var valid_618095 = header.getOrDefault("X-Amz-Credential")
  valid_618095 = validateParameter(valid_618095, JString, required = false,
                                 default = nil)
  if valid_618095 != nil:
    section.add "X-Amz-Credential", valid_618095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618096: Call_GetDescribeDBClusterParameters_618079;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ## 
  let valid = call_618096.validator(path, query, header, formData, body, _)
  let scheme = call_618096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618096.url(scheme.get, call_618096.host, call_618096.base,
                         call_618096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618096, url, valid, _)

proc call*(call_618097: Call_GetDescribeDBClusterParameters_618079;
          DBClusterParameterGroupName: string; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBClusterParameters";
          Marker: string = ""; Source: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   Version: string (required)
  var query_618098 = newJObject()
  add(query_618098, "MaxRecords", newJInt(MaxRecords))
  add(query_618098, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_618098.add "Filters", Filters
  add(query_618098, "Action", newJString(Action))
  add(query_618098, "Marker", newJString(Marker))
  add(query_618098, "Source", newJString(Source))
  add(query_618098, "Version", newJString(Version))
  result = call_618097.call(nil, query_618098, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_618079(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_618080, base: "/",
    url: url_GetDescribeDBClusterParameters_618081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_618136 = ref object of OpenApiRestCall_616850
proc url_PostDescribeDBClusterSnapshotAttributes_618138(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_618137(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618139 = query.getOrDefault("Action")
  valid_618139 = validateParameter(valid_618139, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_618139 != nil:
    section.add "Action", valid_618139
  var valid_618140 = query.getOrDefault("Version")
  valid_618140 = validateParameter(valid_618140, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618140 != nil:
    section.add "Version", valid_618140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618141 = header.getOrDefault("X-Amz-Date")
  valid_618141 = validateParameter(valid_618141, JString, required = false,
                                 default = nil)
  if valid_618141 != nil:
    section.add "X-Amz-Date", valid_618141
  var valid_618142 = header.getOrDefault("X-Amz-Security-Token")
  valid_618142 = validateParameter(valid_618142, JString, required = false,
                                 default = nil)
  if valid_618142 != nil:
    section.add "X-Amz-Security-Token", valid_618142
  var valid_618143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618143 = validateParameter(valid_618143, JString, required = false,
                                 default = nil)
  if valid_618143 != nil:
    section.add "X-Amz-Content-Sha256", valid_618143
  var valid_618144 = header.getOrDefault("X-Amz-Algorithm")
  valid_618144 = validateParameter(valid_618144, JString, required = false,
                                 default = nil)
  if valid_618144 != nil:
    section.add "X-Amz-Algorithm", valid_618144
  var valid_618145 = header.getOrDefault("X-Amz-Signature")
  valid_618145 = validateParameter(valid_618145, JString, required = false,
                                 default = nil)
  if valid_618145 != nil:
    section.add "X-Amz-Signature", valid_618145
  var valid_618146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618146 = validateParameter(valid_618146, JString, required = false,
                                 default = nil)
  if valid_618146 != nil:
    section.add "X-Amz-SignedHeaders", valid_618146
  var valid_618147 = header.getOrDefault("X-Amz-Credential")
  valid_618147 = validateParameter(valid_618147, JString, required = false,
                                 default = nil)
  if valid_618147 != nil:
    section.add "X-Amz-Credential", valid_618147
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_618148 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_618148 = validateParameter(valid_618148, JString, required = true,
                                 default = nil)
  if valid_618148 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_618148
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618149: Call_PostDescribeDBClusterSnapshotAttributes_618136;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_618149.validator(path, query, header, formData, body, _)
  let scheme = call_618149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618149.url(scheme.get, call_618149.host, call_618149.base,
                         call_618149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618149, url, valid, _)

proc call*(call_618150: Call_PostDescribeDBClusterSnapshotAttributes_618136;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_618151 = newJObject()
  var formData_618152 = newJObject()
  add(formData_618152, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_618151, "Action", newJString(Action))
  add(query_618151, "Version", newJString(Version))
  result = call_618150.call(nil, query_618151, nil, formData_618152, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_618136(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_618137, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_618138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_618120 = ref object of OpenApiRestCall_616850
proc url_GetDescribeDBClusterSnapshotAttributes_618122(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_618121(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618123 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_618123 = validateParameter(valid_618123, JString, required = true,
                                 default = nil)
  if valid_618123 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_618123
  var valid_618124 = query.getOrDefault("Action")
  valid_618124 = validateParameter(valid_618124, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_618124 != nil:
    section.add "Action", valid_618124
  var valid_618125 = query.getOrDefault("Version")
  valid_618125 = validateParameter(valid_618125, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618125 != nil:
    section.add "Version", valid_618125
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618126 = header.getOrDefault("X-Amz-Date")
  valid_618126 = validateParameter(valid_618126, JString, required = false,
                                 default = nil)
  if valid_618126 != nil:
    section.add "X-Amz-Date", valid_618126
  var valid_618127 = header.getOrDefault("X-Amz-Security-Token")
  valid_618127 = validateParameter(valid_618127, JString, required = false,
                                 default = nil)
  if valid_618127 != nil:
    section.add "X-Amz-Security-Token", valid_618127
  var valid_618128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618128 = validateParameter(valid_618128, JString, required = false,
                                 default = nil)
  if valid_618128 != nil:
    section.add "X-Amz-Content-Sha256", valid_618128
  var valid_618129 = header.getOrDefault("X-Amz-Algorithm")
  valid_618129 = validateParameter(valid_618129, JString, required = false,
                                 default = nil)
  if valid_618129 != nil:
    section.add "X-Amz-Algorithm", valid_618129
  var valid_618130 = header.getOrDefault("X-Amz-Signature")
  valid_618130 = validateParameter(valid_618130, JString, required = false,
                                 default = nil)
  if valid_618130 != nil:
    section.add "X-Amz-Signature", valid_618130
  var valid_618131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618131 = validateParameter(valid_618131, JString, required = false,
                                 default = nil)
  if valid_618131 != nil:
    section.add "X-Amz-SignedHeaders", valid_618131
  var valid_618132 = header.getOrDefault("X-Amz-Credential")
  valid_618132 = validateParameter(valid_618132, JString, required = false,
                                 default = nil)
  if valid_618132 != nil:
    section.add "X-Amz-Credential", valid_618132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618133: Call_GetDescribeDBClusterSnapshotAttributes_618120;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_618133.validator(path, query, header, formData, body, _)
  let scheme = call_618133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618133.url(scheme.get, call_618133.host, call_618133.base,
                         call_618133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618133, url, valid, _)

proc call*(call_618134: Call_GetDescribeDBClusterSnapshotAttributes_618120;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_618135 = newJObject()
  add(query_618135, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_618135, "Action", newJString(Action))
  add(query_618135, "Version", newJString(Version))
  result = call_618134.call(nil, query_618135, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_618120(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_618121, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_618122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_618176 = ref object of OpenApiRestCall_616850
proc url_PostDescribeDBClusterSnapshots_618178(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterSnapshots_618177(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618179 = query.getOrDefault("Action")
  valid_618179 = validateParameter(valid_618179, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_618179 != nil:
    section.add "Action", valid_618179
  var valid_618180 = query.getOrDefault("Version")
  valid_618180 = validateParameter(valid_618180, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618180 != nil:
    section.add "Version", valid_618180
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618181 = header.getOrDefault("X-Amz-Date")
  valid_618181 = validateParameter(valid_618181, JString, required = false,
                                 default = nil)
  if valid_618181 != nil:
    section.add "X-Amz-Date", valid_618181
  var valid_618182 = header.getOrDefault("X-Amz-Security-Token")
  valid_618182 = validateParameter(valid_618182, JString, required = false,
                                 default = nil)
  if valid_618182 != nil:
    section.add "X-Amz-Security-Token", valid_618182
  var valid_618183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618183 = validateParameter(valid_618183, JString, required = false,
                                 default = nil)
  if valid_618183 != nil:
    section.add "X-Amz-Content-Sha256", valid_618183
  var valid_618184 = header.getOrDefault("X-Amz-Algorithm")
  valid_618184 = validateParameter(valid_618184, JString, required = false,
                                 default = nil)
  if valid_618184 != nil:
    section.add "X-Amz-Algorithm", valid_618184
  var valid_618185 = header.getOrDefault("X-Amz-Signature")
  valid_618185 = validateParameter(valid_618185, JString, required = false,
                                 default = nil)
  if valid_618185 != nil:
    section.add "X-Amz-Signature", valid_618185
  var valid_618186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618186 = validateParameter(valid_618186, JString, required = false,
                                 default = nil)
  if valid_618186 != nil:
    section.add "X-Amz-SignedHeaders", valid_618186
  var valid_618187 = header.getOrDefault("X-Amz-Credential")
  valid_618187 = validateParameter(valid_618187, JString, required = false,
                                 default = nil)
  if valid_618187 != nil:
    section.add "X-Amz-Credential", valid_618187
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   SnapshotType: JString
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_618188 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_618188 = validateParameter(valid_618188, JString, required = false,
                                 default = nil)
  if valid_618188 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_618188
  var valid_618189 = formData.getOrDefault("SnapshotType")
  valid_618189 = validateParameter(valid_618189, JString, required = false,
                                 default = nil)
  if valid_618189 != nil:
    section.add "SnapshotType", valid_618189
  var valid_618190 = formData.getOrDefault("IncludeShared")
  valid_618190 = validateParameter(valid_618190, JBool, required = false, default = nil)
  if valid_618190 != nil:
    section.add "IncludeShared", valid_618190
  var valid_618191 = formData.getOrDefault("IncludePublic")
  valid_618191 = validateParameter(valid_618191, JBool, required = false, default = nil)
  if valid_618191 != nil:
    section.add "IncludePublic", valid_618191
  var valid_618192 = formData.getOrDefault("Filters")
  valid_618192 = validateParameter(valid_618192, JArray, required = false,
                                 default = nil)
  if valid_618192 != nil:
    section.add "Filters", valid_618192
  var valid_618193 = formData.getOrDefault("Marker")
  valid_618193 = validateParameter(valid_618193, JString, required = false,
                                 default = nil)
  if valid_618193 != nil:
    section.add "Marker", valid_618193
  var valid_618194 = formData.getOrDefault("MaxRecords")
  valid_618194 = validateParameter(valid_618194, JInt, required = false, default = nil)
  if valid_618194 != nil:
    section.add "MaxRecords", valid_618194
  var valid_618195 = formData.getOrDefault("DBClusterIdentifier")
  valid_618195 = validateParameter(valid_618195, JString, required = false,
                                 default = nil)
  if valid_618195 != nil:
    section.add "DBClusterIdentifier", valid_618195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618196: Call_PostDescribeDBClusterSnapshots_618176;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_618196.validator(path, query, header, formData, body, _)
  let scheme = call_618196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618196.url(scheme.get, call_618196.host, call_618196.base,
                         call_618196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618196, url, valid, _)

proc call*(call_618197: Call_PostDescribeDBClusterSnapshots_618176;
          DBClusterSnapshotIdentifier: string = ""; SnapshotType: string = "";
          IncludeShared: bool = false; IncludePublic: bool = false;
          Action: string = "DescribeDBClusterSnapshots"; Filters: JsonNode = nil;
          Marker: string = ""; MaxRecords: int = 0; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshots
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   SnapshotType: string
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_618198 = newJObject()
  var formData_618199 = newJObject()
  add(formData_618199, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_618199, "SnapshotType", newJString(SnapshotType))
  add(formData_618199, "IncludeShared", newJBool(IncludeShared))
  add(formData_618199, "IncludePublic", newJBool(IncludePublic))
  add(query_618198, "Action", newJString(Action))
  if Filters != nil:
    formData_618199.add "Filters", Filters
  add(formData_618199, "Marker", newJString(Marker))
  add(formData_618199, "MaxRecords", newJInt(MaxRecords))
  add(formData_618199, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_618198, "Version", newJString(Version))
  result = call_618197.call(nil, query_618198, nil, formData_618199, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_618176(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_618177, base: "/",
    url: url_PostDescribeDBClusterSnapshots_618178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_618153 = ref object of OpenApiRestCall_616850
proc url_GetDescribeDBClusterSnapshots_618155(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterSnapshots_618154(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SnapshotType: JString
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Version: JString (required)
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  section = newJObject()
  var valid_618156 = query.getOrDefault("MaxRecords")
  valid_618156 = validateParameter(valid_618156, JInt, required = false, default = nil)
  if valid_618156 != nil:
    section.add "MaxRecords", valid_618156
  var valid_618157 = query.getOrDefault("IncludePublic")
  valid_618157 = validateParameter(valid_618157, JBool, required = false, default = nil)
  if valid_618157 != nil:
    section.add "IncludePublic", valid_618157
  var valid_618158 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_618158 = validateParameter(valid_618158, JString, required = false,
                                 default = nil)
  if valid_618158 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_618158
  var valid_618159 = query.getOrDefault("DBClusterIdentifier")
  valid_618159 = validateParameter(valid_618159, JString, required = false,
                                 default = nil)
  if valid_618159 != nil:
    section.add "DBClusterIdentifier", valid_618159
  var valid_618160 = query.getOrDefault("Filters")
  valid_618160 = validateParameter(valid_618160, JArray, required = false,
                                 default = nil)
  if valid_618160 != nil:
    section.add "Filters", valid_618160
  var valid_618161 = query.getOrDefault("Action")
  valid_618161 = validateParameter(valid_618161, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_618161 != nil:
    section.add "Action", valid_618161
  var valid_618162 = query.getOrDefault("Marker")
  valid_618162 = validateParameter(valid_618162, JString, required = false,
                                 default = nil)
  if valid_618162 != nil:
    section.add "Marker", valid_618162
  var valid_618163 = query.getOrDefault("SnapshotType")
  valid_618163 = validateParameter(valid_618163, JString, required = false,
                                 default = nil)
  if valid_618163 != nil:
    section.add "SnapshotType", valid_618163
  var valid_618164 = query.getOrDefault("Version")
  valid_618164 = validateParameter(valid_618164, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618164 != nil:
    section.add "Version", valid_618164
  var valid_618165 = query.getOrDefault("IncludeShared")
  valid_618165 = validateParameter(valid_618165, JBool, required = false, default = nil)
  if valid_618165 != nil:
    section.add "IncludeShared", valid_618165
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618166 = header.getOrDefault("X-Amz-Date")
  valid_618166 = validateParameter(valid_618166, JString, required = false,
                                 default = nil)
  if valid_618166 != nil:
    section.add "X-Amz-Date", valid_618166
  var valid_618167 = header.getOrDefault("X-Amz-Security-Token")
  valid_618167 = validateParameter(valid_618167, JString, required = false,
                                 default = nil)
  if valid_618167 != nil:
    section.add "X-Amz-Security-Token", valid_618167
  var valid_618168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618168 = validateParameter(valid_618168, JString, required = false,
                                 default = nil)
  if valid_618168 != nil:
    section.add "X-Amz-Content-Sha256", valid_618168
  var valid_618169 = header.getOrDefault("X-Amz-Algorithm")
  valid_618169 = validateParameter(valid_618169, JString, required = false,
                                 default = nil)
  if valid_618169 != nil:
    section.add "X-Amz-Algorithm", valid_618169
  var valid_618170 = header.getOrDefault("X-Amz-Signature")
  valid_618170 = validateParameter(valid_618170, JString, required = false,
                                 default = nil)
  if valid_618170 != nil:
    section.add "X-Amz-Signature", valid_618170
  var valid_618171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618171 = validateParameter(valid_618171, JString, required = false,
                                 default = nil)
  if valid_618171 != nil:
    section.add "X-Amz-SignedHeaders", valid_618171
  var valid_618172 = header.getOrDefault("X-Amz-Credential")
  valid_618172 = validateParameter(valid_618172, JString, required = false,
                                 default = nil)
  if valid_618172 != nil:
    section.add "X-Amz-Credential", valid_618172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618173: Call_GetDescribeDBClusterSnapshots_618153;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_618173.validator(path, query, header, formData, body, _)
  let scheme = call_618173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618173.url(scheme.get, call_618173.host, call_618173.base,
                         call_618173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618173, url, valid, _)

proc call*(call_618174: Call_GetDescribeDBClusterSnapshots_618153;
          MaxRecords: int = 0; IncludePublic: bool = false;
          DBClusterSnapshotIdentifier: string = "";
          DBClusterIdentifier: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeDBClusterSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2014-10-31";
          IncludeShared: bool = false): Recallable =
  ## getDescribeDBClusterSnapshots
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SnapshotType: string
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Version: string (required)
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  var query_618175 = newJObject()
  add(query_618175, "MaxRecords", newJInt(MaxRecords))
  add(query_618175, "IncludePublic", newJBool(IncludePublic))
  add(query_618175, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_618175, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Filters != nil:
    query_618175.add "Filters", Filters
  add(query_618175, "Action", newJString(Action))
  add(query_618175, "Marker", newJString(Marker))
  add(query_618175, "SnapshotType", newJString(SnapshotType))
  add(query_618175, "Version", newJString(Version))
  add(query_618175, "IncludeShared", newJBool(IncludeShared))
  result = call_618174.call(nil, query_618175, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_618153(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_618154, base: "/",
    url: url_GetDescribeDBClusterSnapshots_618155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_618219 = ref object of OpenApiRestCall_616850
proc url_PostDescribeDBClusters_618221(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusters_618220(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_618222 = query.getOrDefault("Action")
  valid_618222 = validateParameter(valid_618222, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_618222 != nil:
    section.add "Action", valid_618222
  var valid_618223 = query.getOrDefault("Version")
  valid_618223 = validateParameter(valid_618223, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618223 != nil:
    section.add "Version", valid_618223
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618224 = header.getOrDefault("X-Amz-Date")
  valid_618224 = validateParameter(valid_618224, JString, required = false,
                                 default = nil)
  if valid_618224 != nil:
    section.add "X-Amz-Date", valid_618224
  var valid_618225 = header.getOrDefault("X-Amz-Security-Token")
  valid_618225 = validateParameter(valid_618225, JString, required = false,
                                 default = nil)
  if valid_618225 != nil:
    section.add "X-Amz-Security-Token", valid_618225
  var valid_618226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618226 = validateParameter(valid_618226, JString, required = false,
                                 default = nil)
  if valid_618226 != nil:
    section.add "X-Amz-Content-Sha256", valid_618226
  var valid_618227 = header.getOrDefault("X-Amz-Algorithm")
  valid_618227 = validateParameter(valid_618227, JString, required = false,
                                 default = nil)
  if valid_618227 != nil:
    section.add "X-Amz-Algorithm", valid_618227
  var valid_618228 = header.getOrDefault("X-Amz-Signature")
  valid_618228 = validateParameter(valid_618228, JString, required = false,
                                 default = nil)
  if valid_618228 != nil:
    section.add "X-Amz-Signature", valid_618228
  var valid_618229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618229 = validateParameter(valid_618229, JString, required = false,
                                 default = nil)
  if valid_618229 != nil:
    section.add "X-Amz-SignedHeaders", valid_618229
  var valid_618230 = header.getOrDefault("X-Amz-Credential")
  valid_618230 = validateParameter(valid_618230, JString, required = false,
                                 default = nil)
  if valid_618230 != nil:
    section.add "X-Amz-Credential", valid_618230
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_618231 = formData.getOrDefault("Filters")
  valid_618231 = validateParameter(valid_618231, JArray, required = false,
                                 default = nil)
  if valid_618231 != nil:
    section.add "Filters", valid_618231
  var valid_618232 = formData.getOrDefault("Marker")
  valid_618232 = validateParameter(valid_618232, JString, required = false,
                                 default = nil)
  if valid_618232 != nil:
    section.add "Marker", valid_618232
  var valid_618233 = formData.getOrDefault("MaxRecords")
  valid_618233 = validateParameter(valid_618233, JInt, required = false, default = nil)
  if valid_618233 != nil:
    section.add "MaxRecords", valid_618233
  var valid_618234 = formData.getOrDefault("DBClusterIdentifier")
  valid_618234 = validateParameter(valid_618234, JString, required = false,
                                 default = nil)
  if valid_618234 != nil:
    section.add "DBClusterIdentifier", valid_618234
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618235: Call_PostDescribeDBClusters_618219; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ## 
  let valid = call_618235.validator(path, query, header, formData, body, _)
  let scheme = call_618235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618235.url(scheme.get, call_618235.host, call_618235.base,
                         call_618235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618235, url, valid, _)

proc call*(call_618236: Call_PostDescribeDBClusters_618219;
          Action: string = "DescribeDBClusters"; Filters: JsonNode = nil;
          Marker: string = ""; MaxRecords: int = 0; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_618237 = newJObject()
  var formData_618238 = newJObject()
  add(query_618237, "Action", newJString(Action))
  if Filters != nil:
    formData_618238.add "Filters", Filters
  add(formData_618238, "Marker", newJString(Marker))
  add(formData_618238, "MaxRecords", newJInt(MaxRecords))
  add(formData_618238, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_618237, "Version", newJString(Version))
  result = call_618236.call(nil, query_618237, nil, formData_618238, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_618219(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_618220, base: "/",
    url: url_PostDescribeDBClusters_618221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_618200 = ref object of OpenApiRestCall_616850
proc url_GetDescribeDBClusters_618202(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusters_618201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_618203 = query.getOrDefault("MaxRecords")
  valid_618203 = validateParameter(valid_618203, JInt, required = false, default = nil)
  if valid_618203 != nil:
    section.add "MaxRecords", valid_618203
  var valid_618204 = query.getOrDefault("DBClusterIdentifier")
  valid_618204 = validateParameter(valid_618204, JString, required = false,
                                 default = nil)
  if valid_618204 != nil:
    section.add "DBClusterIdentifier", valid_618204
  var valid_618205 = query.getOrDefault("Filters")
  valid_618205 = validateParameter(valid_618205, JArray, required = false,
                                 default = nil)
  if valid_618205 != nil:
    section.add "Filters", valid_618205
  var valid_618206 = query.getOrDefault("Action")
  valid_618206 = validateParameter(valid_618206, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_618206 != nil:
    section.add "Action", valid_618206
  var valid_618207 = query.getOrDefault("Marker")
  valid_618207 = validateParameter(valid_618207, JString, required = false,
                                 default = nil)
  if valid_618207 != nil:
    section.add "Marker", valid_618207
  var valid_618208 = query.getOrDefault("Version")
  valid_618208 = validateParameter(valid_618208, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618208 != nil:
    section.add "Version", valid_618208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618209 = header.getOrDefault("X-Amz-Date")
  valid_618209 = validateParameter(valid_618209, JString, required = false,
                                 default = nil)
  if valid_618209 != nil:
    section.add "X-Amz-Date", valid_618209
  var valid_618210 = header.getOrDefault("X-Amz-Security-Token")
  valid_618210 = validateParameter(valid_618210, JString, required = false,
                                 default = nil)
  if valid_618210 != nil:
    section.add "X-Amz-Security-Token", valid_618210
  var valid_618211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618211 = validateParameter(valid_618211, JString, required = false,
                                 default = nil)
  if valid_618211 != nil:
    section.add "X-Amz-Content-Sha256", valid_618211
  var valid_618212 = header.getOrDefault("X-Amz-Algorithm")
  valid_618212 = validateParameter(valid_618212, JString, required = false,
                                 default = nil)
  if valid_618212 != nil:
    section.add "X-Amz-Algorithm", valid_618212
  var valid_618213 = header.getOrDefault("X-Amz-Signature")
  valid_618213 = validateParameter(valid_618213, JString, required = false,
                                 default = nil)
  if valid_618213 != nil:
    section.add "X-Amz-Signature", valid_618213
  var valid_618214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618214 = validateParameter(valid_618214, JString, required = false,
                                 default = nil)
  if valid_618214 != nil:
    section.add "X-Amz-SignedHeaders", valid_618214
  var valid_618215 = header.getOrDefault("X-Amz-Credential")
  valid_618215 = validateParameter(valid_618215, JString, required = false,
                                 default = nil)
  if valid_618215 != nil:
    section.add "X-Amz-Credential", valid_618215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618216: Call_GetDescribeDBClusters_618200; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ## 
  let valid = call_618216.validator(path, query, header, formData, body, _)
  let scheme = call_618216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618216.url(scheme.get, call_618216.host, call_618216.base,
                         call_618216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618216, url, valid, _)

proc call*(call_618217: Call_GetDescribeDBClusters_618200; MaxRecords: int = 0;
          DBClusterIdentifier: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeDBClusters"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_618218 = newJObject()
  add(query_618218, "MaxRecords", newJInt(MaxRecords))
  add(query_618218, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Filters != nil:
    query_618218.add "Filters", Filters
  add(query_618218, "Action", newJString(Action))
  add(query_618218, "Marker", newJString(Marker))
  add(query_618218, "Version", newJString(Version))
  result = call_618217.call(nil, query_618218, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_618200(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_618201, base: "/",
    url: url_GetDescribeDBClusters_618202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_618263 = ref object of OpenApiRestCall_616850
proc url_PostDescribeDBEngineVersions_618265(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_618264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618266 = query.getOrDefault("Action")
  valid_618266 = validateParameter(valid_618266, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_618266 != nil:
    section.add "Action", valid_618266
  var valid_618267 = query.getOrDefault("Version")
  valid_618267 = validateParameter(valid_618267, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618267 != nil:
    section.add "Version", valid_618267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618268 = header.getOrDefault("X-Amz-Date")
  valid_618268 = validateParameter(valid_618268, JString, required = false,
                                 default = nil)
  if valid_618268 != nil:
    section.add "X-Amz-Date", valid_618268
  var valid_618269 = header.getOrDefault("X-Amz-Security-Token")
  valid_618269 = validateParameter(valid_618269, JString, required = false,
                                 default = nil)
  if valid_618269 != nil:
    section.add "X-Amz-Security-Token", valid_618269
  var valid_618270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618270 = validateParameter(valid_618270, JString, required = false,
                                 default = nil)
  if valid_618270 != nil:
    section.add "X-Amz-Content-Sha256", valid_618270
  var valid_618271 = header.getOrDefault("X-Amz-Algorithm")
  valid_618271 = validateParameter(valid_618271, JString, required = false,
                                 default = nil)
  if valid_618271 != nil:
    section.add "X-Amz-Algorithm", valid_618271
  var valid_618272 = header.getOrDefault("X-Amz-Signature")
  valid_618272 = validateParameter(valid_618272, JString, required = false,
                                 default = nil)
  if valid_618272 != nil:
    section.add "X-Amz-Signature", valid_618272
  var valid_618273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618273 = validateParameter(valid_618273, JString, required = false,
                                 default = nil)
  if valid_618273 != nil:
    section.add "X-Amz-SignedHeaders", valid_618273
  var valid_618274 = header.getOrDefault("X-Amz-Credential")
  valid_618274 = validateParameter(valid_618274, JString, required = false,
                                 default = nil)
  if valid_618274 != nil:
    section.add "X-Amz-Credential", valid_618274
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListSupportedCharacterSets: JBool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Engine: JString
  ##         : The database engine to return.
  ##   ListSupportedTimezones: JBool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   DBParameterGroupFamily: JString
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: JString
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   DefaultOnly: JBool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  section = newJObject()
  var valid_618275 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_618275 = validateParameter(valid_618275, JBool, required = false, default = nil)
  if valid_618275 != nil:
    section.add "ListSupportedCharacterSets", valid_618275
  var valid_618276 = formData.getOrDefault("Engine")
  valid_618276 = validateParameter(valid_618276, JString, required = false,
                                 default = nil)
  if valid_618276 != nil:
    section.add "Engine", valid_618276
  var valid_618277 = formData.getOrDefault("ListSupportedTimezones")
  valid_618277 = validateParameter(valid_618277, JBool, required = false, default = nil)
  if valid_618277 != nil:
    section.add "ListSupportedTimezones", valid_618277
  var valid_618278 = formData.getOrDefault("DBParameterGroupFamily")
  valid_618278 = validateParameter(valid_618278, JString, required = false,
                                 default = nil)
  if valid_618278 != nil:
    section.add "DBParameterGroupFamily", valid_618278
  var valid_618279 = formData.getOrDefault("Filters")
  valid_618279 = validateParameter(valid_618279, JArray, required = false,
                                 default = nil)
  if valid_618279 != nil:
    section.add "Filters", valid_618279
  var valid_618280 = formData.getOrDefault("Marker")
  valid_618280 = validateParameter(valid_618280, JString, required = false,
                                 default = nil)
  if valid_618280 != nil:
    section.add "Marker", valid_618280
  var valid_618281 = formData.getOrDefault("MaxRecords")
  valid_618281 = validateParameter(valid_618281, JInt, required = false, default = nil)
  if valid_618281 != nil:
    section.add "MaxRecords", valid_618281
  var valid_618282 = formData.getOrDefault("EngineVersion")
  valid_618282 = validateParameter(valid_618282, JString, required = false,
                                 default = nil)
  if valid_618282 != nil:
    section.add "EngineVersion", valid_618282
  var valid_618283 = formData.getOrDefault("DefaultOnly")
  valid_618283 = validateParameter(valid_618283, JBool, required = false, default = nil)
  if valid_618283 != nil:
    section.add "DefaultOnly", valid_618283
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618284: Call_PostDescribeDBEngineVersions_618263;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the available engines.
  ## 
  let valid = call_618284.validator(path, query, header, formData, body, _)
  let scheme = call_618284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618284.url(scheme.get, call_618284.host, call_618284.base,
                         call_618284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618284, url, valid, _)

proc call*(call_618285: Call_PostDescribeDBEngineVersions_618263;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          ListSupportedTimezones: bool = false;
          Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; Filters: JsonNode = nil;
          Marker: string = ""; MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2014-10-31"; DefaultOnly: bool = false): Recallable =
  ## postDescribeDBEngineVersions
  ## Returns a list of the available engines.
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Engine: string
  ##         : The database engine to return.
  ##   ListSupportedTimezones: bool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   Version: string (required)
  ##   DefaultOnly: bool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  var query_618286 = newJObject()
  var formData_618287 = newJObject()
  add(formData_618287, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_618287, "Engine", newJString(Engine))
  add(formData_618287, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_618286, "Action", newJString(Action))
  add(formData_618287, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_618287.add "Filters", Filters
  add(formData_618287, "Marker", newJString(Marker))
  add(formData_618287, "MaxRecords", newJInt(MaxRecords))
  add(formData_618287, "EngineVersion", newJString(EngineVersion))
  add(query_618286, "Version", newJString(Version))
  add(formData_618287, "DefaultOnly", newJBool(DefaultOnly))
  result = call_618285.call(nil, query_618286, nil, formData_618287, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_618263(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_618264, base: "/",
    url: url_PostDescribeDBEngineVersions_618265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_618239 = ref object of OpenApiRestCall_616850
proc url_GetDescribeDBEngineVersions_618241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_618240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns a list of the available engines.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ListSupportedCharacterSets: JBool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ListSupportedTimezones: JBool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: JString
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   DefaultOnly: JBool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  ##   Engine: JString
  ##         : The database engine to return.
  ##   Version: JString (required)
  ##   DBParameterGroupFamily: JString
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  section = newJObject()
  var valid_618242 = query.getOrDefault("ListSupportedCharacterSets")
  valid_618242 = validateParameter(valid_618242, JBool, required = false, default = nil)
  if valid_618242 != nil:
    section.add "ListSupportedCharacterSets", valid_618242
  var valid_618243 = query.getOrDefault("MaxRecords")
  valid_618243 = validateParameter(valid_618243, JInt, required = false, default = nil)
  if valid_618243 != nil:
    section.add "MaxRecords", valid_618243
  var valid_618244 = query.getOrDefault("Filters")
  valid_618244 = validateParameter(valid_618244, JArray, required = false,
                                 default = nil)
  if valid_618244 != nil:
    section.add "Filters", valid_618244
  var valid_618245 = query.getOrDefault("ListSupportedTimezones")
  valid_618245 = validateParameter(valid_618245, JBool, required = false, default = nil)
  if valid_618245 != nil:
    section.add "ListSupportedTimezones", valid_618245
  var valid_618246 = query.getOrDefault("Action")
  valid_618246 = validateParameter(valid_618246, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_618246 != nil:
    section.add "Action", valid_618246
  var valid_618247 = query.getOrDefault("Marker")
  valid_618247 = validateParameter(valid_618247, JString, required = false,
                                 default = nil)
  if valid_618247 != nil:
    section.add "Marker", valid_618247
  var valid_618248 = query.getOrDefault("EngineVersion")
  valid_618248 = validateParameter(valid_618248, JString, required = false,
                                 default = nil)
  if valid_618248 != nil:
    section.add "EngineVersion", valid_618248
  var valid_618249 = query.getOrDefault("DefaultOnly")
  valid_618249 = validateParameter(valid_618249, JBool, required = false, default = nil)
  if valid_618249 != nil:
    section.add "DefaultOnly", valid_618249
  var valid_618250 = query.getOrDefault("Engine")
  valid_618250 = validateParameter(valid_618250, JString, required = false,
                                 default = nil)
  if valid_618250 != nil:
    section.add "Engine", valid_618250
  var valid_618251 = query.getOrDefault("Version")
  valid_618251 = validateParameter(valid_618251, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618251 != nil:
    section.add "Version", valid_618251
  var valid_618252 = query.getOrDefault("DBParameterGroupFamily")
  valid_618252 = validateParameter(valid_618252, JString, required = false,
                                 default = nil)
  if valid_618252 != nil:
    section.add "DBParameterGroupFamily", valid_618252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618253 = header.getOrDefault("X-Amz-Date")
  valid_618253 = validateParameter(valid_618253, JString, required = false,
                                 default = nil)
  if valid_618253 != nil:
    section.add "X-Amz-Date", valid_618253
  var valid_618254 = header.getOrDefault("X-Amz-Security-Token")
  valid_618254 = validateParameter(valid_618254, JString, required = false,
                                 default = nil)
  if valid_618254 != nil:
    section.add "X-Amz-Security-Token", valid_618254
  var valid_618255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618255 = validateParameter(valid_618255, JString, required = false,
                                 default = nil)
  if valid_618255 != nil:
    section.add "X-Amz-Content-Sha256", valid_618255
  var valid_618256 = header.getOrDefault("X-Amz-Algorithm")
  valid_618256 = validateParameter(valid_618256, JString, required = false,
                                 default = nil)
  if valid_618256 != nil:
    section.add "X-Amz-Algorithm", valid_618256
  var valid_618257 = header.getOrDefault("X-Amz-Signature")
  valid_618257 = validateParameter(valid_618257, JString, required = false,
                                 default = nil)
  if valid_618257 != nil:
    section.add "X-Amz-Signature", valid_618257
  var valid_618258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618258 = validateParameter(valid_618258, JString, required = false,
                                 default = nil)
  if valid_618258 != nil:
    section.add "X-Amz-SignedHeaders", valid_618258
  var valid_618259 = header.getOrDefault("X-Amz-Credential")
  valid_618259 = validateParameter(valid_618259, JString, required = false,
                                 default = nil)
  if valid_618259 != nil:
    section.add "X-Amz-Credential", valid_618259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618260: Call_GetDescribeDBEngineVersions_618239;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the available engines.
  ## 
  let valid = call_618260.validator(path, query, header, formData, body, _)
  let scheme = call_618260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618260.url(scheme.get, call_618260.host, call_618260.base,
                         call_618260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618260, url, valid, _)

proc call*(call_618261: Call_GetDescribeDBEngineVersions_618239;
          ListSupportedCharacterSets: bool = false; MaxRecords: int = 0;
          Filters: JsonNode = nil; ListSupportedTimezones: bool = false;
          Action: string = "DescribeDBEngineVersions"; Marker: string = "";
          EngineVersion: string = ""; DefaultOnly: bool = false; Engine: string = "";
          Version: string = "2014-10-31"; DBParameterGroupFamily: string = ""): Recallable =
  ## getDescribeDBEngineVersions
  ## Returns a list of the available engines.
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ListSupportedTimezones: bool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: string
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   DefaultOnly: bool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  ##   Engine: string
  ##         : The database engine to return.
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  var query_618262 = newJObject()
  add(query_618262, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_618262, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_618262.add "Filters", Filters
  add(query_618262, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_618262, "Action", newJString(Action))
  add(query_618262, "Marker", newJString(Marker))
  add(query_618262, "EngineVersion", newJString(EngineVersion))
  add(query_618262, "DefaultOnly", newJBool(DefaultOnly))
  add(query_618262, "Engine", newJString(Engine))
  add(query_618262, "Version", newJString(Version))
  add(query_618262, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  result = call_618261.call(nil, query_618262, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_618239(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_618240, base: "/",
    url: url_GetDescribeDBEngineVersions_618241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_618307 = ref object of OpenApiRestCall_616850
proc url_PostDescribeDBInstances_618309(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_618308(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618310 = query.getOrDefault("Action")
  valid_618310 = validateParameter(valid_618310, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_618310 != nil:
    section.add "Action", valid_618310
  var valid_618311 = query.getOrDefault("Version")
  valid_618311 = validateParameter(valid_618311, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618311 != nil:
    section.add "Version", valid_618311
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618312 = header.getOrDefault("X-Amz-Date")
  valid_618312 = validateParameter(valid_618312, JString, required = false,
                                 default = nil)
  if valid_618312 != nil:
    section.add "X-Amz-Date", valid_618312
  var valid_618313 = header.getOrDefault("X-Amz-Security-Token")
  valid_618313 = validateParameter(valid_618313, JString, required = false,
                                 default = nil)
  if valid_618313 != nil:
    section.add "X-Amz-Security-Token", valid_618313
  var valid_618314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618314 = validateParameter(valid_618314, JString, required = false,
                                 default = nil)
  if valid_618314 != nil:
    section.add "X-Amz-Content-Sha256", valid_618314
  var valid_618315 = header.getOrDefault("X-Amz-Algorithm")
  valid_618315 = validateParameter(valid_618315, JString, required = false,
                                 default = nil)
  if valid_618315 != nil:
    section.add "X-Amz-Algorithm", valid_618315
  var valid_618316 = header.getOrDefault("X-Amz-Signature")
  valid_618316 = validateParameter(valid_618316, JString, required = false,
                                 default = nil)
  if valid_618316 != nil:
    section.add "X-Amz-Signature", valid_618316
  var valid_618317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618317 = validateParameter(valid_618317, JString, required = false,
                                 default = nil)
  if valid_618317 != nil:
    section.add "X-Amz-SignedHeaders", valid_618317
  var valid_618318 = header.getOrDefault("X-Amz-Credential")
  valid_618318 = validateParameter(valid_618318, JString, required = false,
                                 default = nil)
  if valid_618318 != nil:
    section.add "X-Amz-Credential", valid_618318
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_618319 = formData.getOrDefault("DBInstanceIdentifier")
  valid_618319 = validateParameter(valid_618319, JString, required = false,
                                 default = nil)
  if valid_618319 != nil:
    section.add "DBInstanceIdentifier", valid_618319
  var valid_618320 = formData.getOrDefault("Filters")
  valid_618320 = validateParameter(valid_618320, JArray, required = false,
                                 default = nil)
  if valid_618320 != nil:
    section.add "Filters", valid_618320
  var valid_618321 = formData.getOrDefault("Marker")
  valid_618321 = validateParameter(valid_618321, JString, required = false,
                                 default = nil)
  if valid_618321 != nil:
    section.add "Marker", valid_618321
  var valid_618322 = formData.getOrDefault("MaxRecords")
  valid_618322 = validateParameter(valid_618322, JInt, required = false, default = nil)
  if valid_618322 != nil:
    section.add "MaxRecords", valid_618322
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618323: Call_PostDescribeDBInstances_618307; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_618323.validator(path, query, header, formData, body, _)
  let scheme = call_618323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618323.url(scheme.get, call_618323.host, call_618323.base,
                         call_618323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618323, url, valid, _)

proc call*(call_618324: Call_PostDescribeDBInstances_618307;
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Filters: JsonNode = nil; Marker: string = ""; MaxRecords: int = 0;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_618325 = newJObject()
  var formData_618326 = newJObject()
  add(formData_618326, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_618325, "Action", newJString(Action))
  if Filters != nil:
    formData_618326.add "Filters", Filters
  add(formData_618326, "Marker", newJString(Marker))
  add(formData_618326, "MaxRecords", newJInt(MaxRecords))
  add(query_618325, "Version", newJString(Version))
  result = call_618324.call(nil, query_618325, nil, formData_618326, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_618307(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_618308, base: "/",
    url: url_PostDescribeDBInstances_618309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_618288 = ref object of OpenApiRestCall_616850
proc url_GetDescribeDBInstances_618290(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_618289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  var valid_618291 = query.getOrDefault("MaxRecords")
  valid_618291 = validateParameter(valid_618291, JInt, required = false, default = nil)
  if valid_618291 != nil:
    section.add "MaxRecords", valid_618291
  var valid_618292 = query.getOrDefault("Filters")
  valid_618292 = validateParameter(valid_618292, JArray, required = false,
                                 default = nil)
  if valid_618292 != nil:
    section.add "Filters", valid_618292
  var valid_618293 = query.getOrDefault("Action")
  valid_618293 = validateParameter(valid_618293, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_618293 != nil:
    section.add "Action", valid_618293
  var valid_618294 = query.getOrDefault("Marker")
  valid_618294 = validateParameter(valid_618294, JString, required = false,
                                 default = nil)
  if valid_618294 != nil:
    section.add "Marker", valid_618294
  var valid_618295 = query.getOrDefault("Version")
  valid_618295 = validateParameter(valid_618295, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618295 != nil:
    section.add "Version", valid_618295
  var valid_618296 = query.getOrDefault("DBInstanceIdentifier")
  valid_618296 = validateParameter(valid_618296, JString, required = false,
                                 default = nil)
  if valid_618296 != nil:
    section.add "DBInstanceIdentifier", valid_618296
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618297 = header.getOrDefault("X-Amz-Date")
  valid_618297 = validateParameter(valid_618297, JString, required = false,
                                 default = nil)
  if valid_618297 != nil:
    section.add "X-Amz-Date", valid_618297
  var valid_618298 = header.getOrDefault("X-Amz-Security-Token")
  valid_618298 = validateParameter(valid_618298, JString, required = false,
                                 default = nil)
  if valid_618298 != nil:
    section.add "X-Amz-Security-Token", valid_618298
  var valid_618299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618299 = validateParameter(valid_618299, JString, required = false,
                                 default = nil)
  if valid_618299 != nil:
    section.add "X-Amz-Content-Sha256", valid_618299
  var valid_618300 = header.getOrDefault("X-Amz-Algorithm")
  valid_618300 = validateParameter(valid_618300, JString, required = false,
                                 default = nil)
  if valid_618300 != nil:
    section.add "X-Amz-Algorithm", valid_618300
  var valid_618301 = header.getOrDefault("X-Amz-Signature")
  valid_618301 = validateParameter(valid_618301, JString, required = false,
                                 default = nil)
  if valid_618301 != nil:
    section.add "X-Amz-Signature", valid_618301
  var valid_618302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618302 = validateParameter(valid_618302, JString, required = false,
                                 default = nil)
  if valid_618302 != nil:
    section.add "X-Amz-SignedHeaders", valid_618302
  var valid_618303 = header.getOrDefault("X-Amz-Credential")
  valid_618303 = validateParameter(valid_618303, JString, required = false,
                                 default = nil)
  if valid_618303 != nil:
    section.add "X-Amz-Credential", valid_618303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618304: Call_GetDescribeDBInstances_618288; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_618304.validator(path, query, header, formData, body, _)
  let scheme = call_618304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618304.url(scheme.get, call_618304.host, call_618304.base,
                         call_618304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618304, url, valid, _)

proc call*(call_618305: Call_GetDescribeDBInstances_618288; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBInstances";
          Marker: string = ""; Version: string = "2014-10-31";
          DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  var query_618306 = newJObject()
  add(query_618306, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_618306.add "Filters", Filters
  add(query_618306, "Action", newJString(Action))
  add(query_618306, "Marker", newJString(Marker))
  add(query_618306, "Version", newJString(Version))
  add(query_618306, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_618305.call(nil, query_618306, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_618288(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_618289, base: "/",
    url: url_GetDescribeDBInstances_618290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_618346 = ref object of OpenApiRestCall_616850
proc url_PostDescribeDBSubnetGroups_618348(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_618347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618349 = query.getOrDefault("Action")
  valid_618349 = validateParameter(valid_618349, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_618349 != nil:
    section.add "Action", valid_618349
  var valid_618350 = query.getOrDefault("Version")
  valid_618350 = validateParameter(valid_618350, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618350 != nil:
    section.add "Version", valid_618350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618351 = header.getOrDefault("X-Amz-Date")
  valid_618351 = validateParameter(valid_618351, JString, required = false,
                                 default = nil)
  if valid_618351 != nil:
    section.add "X-Amz-Date", valid_618351
  var valid_618352 = header.getOrDefault("X-Amz-Security-Token")
  valid_618352 = validateParameter(valid_618352, JString, required = false,
                                 default = nil)
  if valid_618352 != nil:
    section.add "X-Amz-Security-Token", valid_618352
  var valid_618353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618353 = validateParameter(valid_618353, JString, required = false,
                                 default = nil)
  if valid_618353 != nil:
    section.add "X-Amz-Content-Sha256", valid_618353
  var valid_618354 = header.getOrDefault("X-Amz-Algorithm")
  valid_618354 = validateParameter(valid_618354, JString, required = false,
                                 default = nil)
  if valid_618354 != nil:
    section.add "X-Amz-Algorithm", valid_618354
  var valid_618355 = header.getOrDefault("X-Amz-Signature")
  valid_618355 = validateParameter(valid_618355, JString, required = false,
                                 default = nil)
  if valid_618355 != nil:
    section.add "X-Amz-Signature", valid_618355
  var valid_618356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618356 = validateParameter(valid_618356, JString, required = false,
                                 default = nil)
  if valid_618356 != nil:
    section.add "X-Amz-SignedHeaders", valid_618356
  var valid_618357 = header.getOrDefault("X-Amz-Credential")
  valid_618357 = validateParameter(valid_618357, JString, required = false,
                                 default = nil)
  if valid_618357 != nil:
    section.add "X-Amz-Credential", valid_618357
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##                    : The name of the subnet group to return details for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_618358 = formData.getOrDefault("DBSubnetGroupName")
  valid_618358 = validateParameter(valid_618358, JString, required = false,
                                 default = nil)
  if valid_618358 != nil:
    section.add "DBSubnetGroupName", valid_618358
  var valid_618359 = formData.getOrDefault("Filters")
  valid_618359 = validateParameter(valid_618359, JArray, required = false,
                                 default = nil)
  if valid_618359 != nil:
    section.add "Filters", valid_618359
  var valid_618360 = formData.getOrDefault("Marker")
  valid_618360 = validateParameter(valid_618360, JString, required = false,
                                 default = nil)
  if valid_618360 != nil:
    section.add "Marker", valid_618360
  var valid_618361 = formData.getOrDefault("MaxRecords")
  valid_618361 = validateParameter(valid_618361, JInt, required = false, default = nil)
  if valid_618361 != nil:
    section.add "MaxRecords", valid_618361
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618362: Call_PostDescribeDBSubnetGroups_618346;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_618362.validator(path, query, header, formData, body, _)
  let scheme = call_618362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618362.url(scheme.get, call_618362.host, call_618362.base,
                         call_618362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618362, url, valid, _)

proc call*(call_618363: Call_PostDescribeDBSubnetGroups_618346;
          DBSubnetGroupName: string = ""; Action: string = "DescribeDBSubnetGroups";
          Filters: JsonNode = nil; Marker: string = ""; MaxRecords: int = 0;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBSubnetGroups
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ##   DBSubnetGroupName: string
  ##                    : The name of the subnet group to return details for.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_618364 = newJObject()
  var formData_618365 = newJObject()
  add(formData_618365, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_618364, "Action", newJString(Action))
  if Filters != nil:
    formData_618365.add "Filters", Filters
  add(formData_618365, "Marker", newJString(Marker))
  add(formData_618365, "MaxRecords", newJInt(MaxRecords))
  add(query_618364, "Version", newJString(Version))
  result = call_618363.call(nil, query_618364, nil, formData_618365, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_618346(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_618347, base: "/",
    url: url_PostDescribeDBSubnetGroups_618348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_618327 = ref object of OpenApiRestCall_616850
proc url_GetDescribeDBSubnetGroups_618329(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_618328(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBSubnetGroupName: JString
  ##                    : The name of the subnet group to return details for.
  ##   Version: JString (required)
  section = newJObject()
  var valid_618330 = query.getOrDefault("MaxRecords")
  valid_618330 = validateParameter(valid_618330, JInt, required = false, default = nil)
  if valid_618330 != nil:
    section.add "MaxRecords", valid_618330
  var valid_618331 = query.getOrDefault("Filters")
  valid_618331 = validateParameter(valid_618331, JArray, required = false,
                                 default = nil)
  if valid_618331 != nil:
    section.add "Filters", valid_618331
  var valid_618332 = query.getOrDefault("Action")
  valid_618332 = validateParameter(valid_618332, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_618332 != nil:
    section.add "Action", valid_618332
  var valid_618333 = query.getOrDefault("Marker")
  valid_618333 = validateParameter(valid_618333, JString, required = false,
                                 default = nil)
  if valid_618333 != nil:
    section.add "Marker", valid_618333
  var valid_618334 = query.getOrDefault("DBSubnetGroupName")
  valid_618334 = validateParameter(valid_618334, JString, required = false,
                                 default = nil)
  if valid_618334 != nil:
    section.add "DBSubnetGroupName", valid_618334
  var valid_618335 = query.getOrDefault("Version")
  valid_618335 = validateParameter(valid_618335, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618335 != nil:
    section.add "Version", valid_618335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618336 = header.getOrDefault("X-Amz-Date")
  valid_618336 = validateParameter(valid_618336, JString, required = false,
                                 default = nil)
  if valid_618336 != nil:
    section.add "X-Amz-Date", valid_618336
  var valid_618337 = header.getOrDefault("X-Amz-Security-Token")
  valid_618337 = validateParameter(valid_618337, JString, required = false,
                                 default = nil)
  if valid_618337 != nil:
    section.add "X-Amz-Security-Token", valid_618337
  var valid_618338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618338 = validateParameter(valid_618338, JString, required = false,
                                 default = nil)
  if valid_618338 != nil:
    section.add "X-Amz-Content-Sha256", valid_618338
  var valid_618339 = header.getOrDefault("X-Amz-Algorithm")
  valid_618339 = validateParameter(valid_618339, JString, required = false,
                                 default = nil)
  if valid_618339 != nil:
    section.add "X-Amz-Algorithm", valid_618339
  var valid_618340 = header.getOrDefault("X-Amz-Signature")
  valid_618340 = validateParameter(valid_618340, JString, required = false,
                                 default = nil)
  if valid_618340 != nil:
    section.add "X-Amz-Signature", valid_618340
  var valid_618341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618341 = validateParameter(valid_618341, JString, required = false,
                                 default = nil)
  if valid_618341 != nil:
    section.add "X-Amz-SignedHeaders", valid_618341
  var valid_618342 = header.getOrDefault("X-Amz-Credential")
  valid_618342 = validateParameter(valid_618342, JString, required = false,
                                 default = nil)
  if valid_618342 != nil:
    section.add "X-Amz-Credential", valid_618342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618343: Call_GetDescribeDBSubnetGroups_618327;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_618343.validator(path, query, header, formData, body, _)
  let scheme = call_618343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618343.url(scheme.get, call_618343.host, call_618343.base,
                         call_618343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618343, url, valid, _)

proc call*(call_618344: Call_GetDescribeDBSubnetGroups_618327; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSubnetGroups";
          Marker: string = ""; DBSubnetGroupName: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBSubnetGroups
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBSubnetGroupName: string
  ##                    : The name of the subnet group to return details for.
  ##   Version: string (required)
  var query_618345 = newJObject()
  add(query_618345, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_618345.add "Filters", Filters
  add(query_618345, "Action", newJString(Action))
  add(query_618345, "Marker", newJString(Marker))
  add(query_618345, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_618345, "Version", newJString(Version))
  result = call_618344.call(nil, query_618345, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_618327(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_618328, base: "/",
    url: url_GetDescribeDBSubnetGroups_618329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_618385 = ref object of OpenApiRestCall_616850
proc url_PostDescribeEngineDefaultClusterParameters_618387(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultClusterParameters_618386(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618388 = query.getOrDefault("Action")
  valid_618388 = validateParameter(valid_618388, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_618388 != nil:
    section.add "Action", valid_618388
  var valid_618389 = query.getOrDefault("Version")
  valid_618389 = validateParameter(valid_618389, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618389 != nil:
    section.add "Version", valid_618389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618390 = header.getOrDefault("X-Amz-Date")
  valid_618390 = validateParameter(valid_618390, JString, required = false,
                                 default = nil)
  if valid_618390 != nil:
    section.add "X-Amz-Date", valid_618390
  var valid_618391 = header.getOrDefault("X-Amz-Security-Token")
  valid_618391 = validateParameter(valid_618391, JString, required = false,
                                 default = nil)
  if valid_618391 != nil:
    section.add "X-Amz-Security-Token", valid_618391
  var valid_618392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618392 = validateParameter(valid_618392, JString, required = false,
                                 default = nil)
  if valid_618392 != nil:
    section.add "X-Amz-Content-Sha256", valid_618392
  var valid_618393 = header.getOrDefault("X-Amz-Algorithm")
  valid_618393 = validateParameter(valid_618393, JString, required = false,
                                 default = nil)
  if valid_618393 != nil:
    section.add "X-Amz-Algorithm", valid_618393
  var valid_618394 = header.getOrDefault("X-Amz-Signature")
  valid_618394 = validateParameter(valid_618394, JString, required = false,
                                 default = nil)
  if valid_618394 != nil:
    section.add "X-Amz-Signature", valid_618394
  var valid_618395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618395 = validateParameter(valid_618395, JString, required = false,
                                 default = nil)
  if valid_618395 != nil:
    section.add "X-Amz-SignedHeaders", valid_618395
  var valid_618396 = header.getOrDefault("X-Amz-Credential")
  valid_618396 = validateParameter(valid_618396, JString, required = false,
                                 default = nil)
  if valid_618396 != nil:
    section.add "X-Amz-Credential", valid_618396
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_618397 = formData.getOrDefault("DBParameterGroupFamily")
  valid_618397 = validateParameter(valid_618397, JString, required = true,
                                 default = nil)
  if valid_618397 != nil:
    section.add "DBParameterGroupFamily", valid_618397
  var valid_618398 = formData.getOrDefault("Filters")
  valid_618398 = validateParameter(valid_618398, JArray, required = false,
                                 default = nil)
  if valid_618398 != nil:
    section.add "Filters", valid_618398
  var valid_618399 = formData.getOrDefault("Marker")
  valid_618399 = validateParameter(valid_618399, JString, required = false,
                                 default = nil)
  if valid_618399 != nil:
    section.add "Marker", valid_618399
  var valid_618400 = formData.getOrDefault("MaxRecords")
  valid_618400 = validateParameter(valid_618400, JInt, required = false, default = nil)
  if valid_618400 != nil:
    section.add "MaxRecords", valid_618400
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618401: Call_PostDescribeEngineDefaultClusterParameters_618385;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_618401.validator(path, query, header, formData, body, _)
  let scheme = call_618401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618401.url(scheme.get, call_618401.host, call_618401.base,
                         call_618401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618401, url, valid, _)

proc call*(call_618402: Call_PostDescribeEngineDefaultClusterParameters_618385;
          DBParameterGroupFamily: string;
          Action: string = "DescribeEngineDefaultClusterParameters";
          Filters: JsonNode = nil; Marker: string = ""; MaxRecords: int = 0;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_618403 = newJObject()
  var formData_618404 = newJObject()
  add(query_618403, "Action", newJString(Action))
  add(formData_618404, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_618404.add "Filters", Filters
  add(formData_618404, "Marker", newJString(Marker))
  add(formData_618404, "MaxRecords", newJInt(MaxRecords))
  add(query_618403, "Version", newJString(Version))
  result = call_618402.call(nil, query_618403, nil, formData_618404, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_618385(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_618386,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_618387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_618366 = ref object of OpenApiRestCall_616850
proc url_GetDescribeEngineDefaultClusterParameters_618368(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultClusterParameters_618367(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  section = newJObject()
  var valid_618369 = query.getOrDefault("MaxRecords")
  valid_618369 = validateParameter(valid_618369, JInt, required = false, default = nil)
  if valid_618369 != nil:
    section.add "MaxRecords", valid_618369
  var valid_618370 = query.getOrDefault("Filters")
  valid_618370 = validateParameter(valid_618370, JArray, required = false,
                                 default = nil)
  if valid_618370 != nil:
    section.add "Filters", valid_618370
  var valid_618371 = query.getOrDefault("Action")
  valid_618371 = validateParameter(valid_618371, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_618371 != nil:
    section.add "Action", valid_618371
  var valid_618372 = query.getOrDefault("Marker")
  valid_618372 = validateParameter(valid_618372, JString, required = false,
                                 default = nil)
  if valid_618372 != nil:
    section.add "Marker", valid_618372
  var valid_618373 = query.getOrDefault("Version")
  valid_618373 = validateParameter(valid_618373, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618373 != nil:
    section.add "Version", valid_618373
  var valid_618374 = query.getOrDefault("DBParameterGroupFamily")
  valid_618374 = validateParameter(valid_618374, JString, required = true,
                                 default = nil)
  if valid_618374 != nil:
    section.add "DBParameterGroupFamily", valid_618374
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618375 = header.getOrDefault("X-Amz-Date")
  valid_618375 = validateParameter(valid_618375, JString, required = false,
                                 default = nil)
  if valid_618375 != nil:
    section.add "X-Amz-Date", valid_618375
  var valid_618376 = header.getOrDefault("X-Amz-Security-Token")
  valid_618376 = validateParameter(valid_618376, JString, required = false,
                                 default = nil)
  if valid_618376 != nil:
    section.add "X-Amz-Security-Token", valid_618376
  var valid_618377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618377 = validateParameter(valid_618377, JString, required = false,
                                 default = nil)
  if valid_618377 != nil:
    section.add "X-Amz-Content-Sha256", valid_618377
  var valid_618378 = header.getOrDefault("X-Amz-Algorithm")
  valid_618378 = validateParameter(valid_618378, JString, required = false,
                                 default = nil)
  if valid_618378 != nil:
    section.add "X-Amz-Algorithm", valid_618378
  var valid_618379 = header.getOrDefault("X-Amz-Signature")
  valid_618379 = validateParameter(valid_618379, JString, required = false,
                                 default = nil)
  if valid_618379 != nil:
    section.add "X-Amz-Signature", valid_618379
  var valid_618380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618380 = validateParameter(valid_618380, JString, required = false,
                                 default = nil)
  if valid_618380 != nil:
    section.add "X-Amz-SignedHeaders", valid_618380
  var valid_618381 = header.getOrDefault("X-Amz-Credential")
  valid_618381 = validateParameter(valid_618381, JString, required = false,
                                 default = nil)
  if valid_618381 != nil:
    section.add "X-Amz-Credential", valid_618381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618382: Call_GetDescribeEngineDefaultClusterParameters_618366;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_618382.validator(path, query, header, formData, body, _)
  let scheme = call_618382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618382.url(scheme.get, call_618382.host, call_618382.base,
                         call_618382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618382, url, valid, _)

proc call*(call_618383: Call_GetDescribeEngineDefaultClusterParameters_618366;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Filters: JsonNode = nil;
          Action: string = "DescribeEngineDefaultClusterParameters";
          Marker: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  var query_618384 = newJObject()
  add(query_618384, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_618384.add "Filters", Filters
  add(query_618384, "Action", newJString(Action))
  add(query_618384, "Marker", newJString(Marker))
  add(query_618384, "Version", newJString(Version))
  add(query_618384, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  result = call_618383.call(nil, query_618384, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_618366(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_618367,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_618368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_618422 = ref object of OpenApiRestCall_616850
proc url_PostDescribeEventCategories_618424(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_618423(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618425 = query.getOrDefault("Action")
  valid_618425 = validateParameter(valid_618425, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_618425 != nil:
    section.add "Action", valid_618425
  var valid_618426 = query.getOrDefault("Version")
  valid_618426 = validateParameter(valid_618426, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618426 != nil:
    section.add "Version", valid_618426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618427 = header.getOrDefault("X-Amz-Date")
  valid_618427 = validateParameter(valid_618427, JString, required = false,
                                 default = nil)
  if valid_618427 != nil:
    section.add "X-Amz-Date", valid_618427
  var valid_618428 = header.getOrDefault("X-Amz-Security-Token")
  valid_618428 = validateParameter(valid_618428, JString, required = false,
                                 default = nil)
  if valid_618428 != nil:
    section.add "X-Amz-Security-Token", valid_618428
  var valid_618429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618429 = validateParameter(valid_618429, JString, required = false,
                                 default = nil)
  if valid_618429 != nil:
    section.add "X-Amz-Content-Sha256", valid_618429
  var valid_618430 = header.getOrDefault("X-Amz-Algorithm")
  valid_618430 = validateParameter(valid_618430, JString, required = false,
                                 default = nil)
  if valid_618430 != nil:
    section.add "X-Amz-Algorithm", valid_618430
  var valid_618431 = header.getOrDefault("X-Amz-Signature")
  valid_618431 = validateParameter(valid_618431, JString, required = false,
                                 default = nil)
  if valid_618431 != nil:
    section.add "X-Amz-Signature", valid_618431
  var valid_618432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618432 = validateParameter(valid_618432, JString, required = false,
                                 default = nil)
  if valid_618432 != nil:
    section.add "X-Amz-SignedHeaders", valid_618432
  var valid_618433 = header.getOrDefault("X-Amz-Credential")
  valid_618433 = validateParameter(valid_618433, JString, required = false,
                                 default = nil)
  if valid_618433 != nil:
    section.add "X-Amz-Credential", valid_618433
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  section = newJObject()
  var valid_618434 = formData.getOrDefault("Filters")
  valid_618434 = validateParameter(valid_618434, JArray, required = false,
                                 default = nil)
  if valid_618434 != nil:
    section.add "Filters", valid_618434
  var valid_618435 = formData.getOrDefault("SourceType")
  valid_618435 = validateParameter(valid_618435, JString, required = false,
                                 default = nil)
  if valid_618435 != nil:
    section.add "SourceType", valid_618435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618436: Call_PostDescribeEventCategories_618422;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_618436.validator(path, query, header, formData, body, _)
  let scheme = call_618436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618436.url(scheme.get, call_618436.host, call_618436.base,
                         call_618436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618436, url, valid, _)

proc call*(call_618437: Call_PostDescribeEventCategories_618422;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Version: string (required)
  ##   SourceType: string
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  var query_618438 = newJObject()
  var formData_618439 = newJObject()
  add(query_618438, "Action", newJString(Action))
  if Filters != nil:
    formData_618439.add "Filters", Filters
  add(query_618438, "Version", newJString(Version))
  add(formData_618439, "SourceType", newJString(SourceType))
  result = call_618437.call(nil, query_618438, nil, formData_618439, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_618422(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_618423, base: "/",
    url: url_PostDescribeEventCategories_618424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_618405 = ref object of OpenApiRestCall_616850
proc url_GetDescribeEventCategories_618407(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_618406(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_618408 = query.getOrDefault("SourceType")
  valid_618408 = validateParameter(valid_618408, JString, required = false,
                                 default = nil)
  if valid_618408 != nil:
    section.add "SourceType", valid_618408
  var valid_618409 = query.getOrDefault("Filters")
  valid_618409 = validateParameter(valid_618409, JArray, required = false,
                                 default = nil)
  if valid_618409 != nil:
    section.add "Filters", valid_618409
  var valid_618410 = query.getOrDefault("Action")
  valid_618410 = validateParameter(valid_618410, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_618410 != nil:
    section.add "Action", valid_618410
  var valid_618411 = query.getOrDefault("Version")
  valid_618411 = validateParameter(valid_618411, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618411 != nil:
    section.add "Version", valid_618411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618412 = header.getOrDefault("X-Amz-Date")
  valid_618412 = validateParameter(valid_618412, JString, required = false,
                                 default = nil)
  if valid_618412 != nil:
    section.add "X-Amz-Date", valid_618412
  var valid_618413 = header.getOrDefault("X-Amz-Security-Token")
  valid_618413 = validateParameter(valid_618413, JString, required = false,
                                 default = nil)
  if valid_618413 != nil:
    section.add "X-Amz-Security-Token", valid_618413
  var valid_618414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618414 = validateParameter(valid_618414, JString, required = false,
                                 default = nil)
  if valid_618414 != nil:
    section.add "X-Amz-Content-Sha256", valid_618414
  var valid_618415 = header.getOrDefault("X-Amz-Algorithm")
  valid_618415 = validateParameter(valid_618415, JString, required = false,
                                 default = nil)
  if valid_618415 != nil:
    section.add "X-Amz-Algorithm", valid_618415
  var valid_618416 = header.getOrDefault("X-Amz-Signature")
  valid_618416 = validateParameter(valid_618416, JString, required = false,
                                 default = nil)
  if valid_618416 != nil:
    section.add "X-Amz-Signature", valid_618416
  var valid_618417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618417 = validateParameter(valid_618417, JString, required = false,
                                 default = nil)
  if valid_618417 != nil:
    section.add "X-Amz-SignedHeaders", valid_618417
  var valid_618418 = header.getOrDefault("X-Amz-Credential")
  valid_618418 = validateParameter(valid_618418, JString, required = false,
                                 default = nil)
  if valid_618418 != nil:
    section.add "X-Amz-Credential", valid_618418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618419: Call_GetDescribeEventCategories_618405;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_618419.validator(path, query, header, formData, body, _)
  let scheme = call_618419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618419.url(scheme.get, call_618419.host, call_618419.base,
                         call_618419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618419, url, valid, _)

proc call*(call_618420: Call_GetDescribeEventCategories_618405;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-10-31"): Recallable =
  ## getDescribeEventCategories
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ##   SourceType: string
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_618421 = newJObject()
  add(query_618421, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_618421.add "Filters", Filters
  add(query_618421, "Action", newJString(Action))
  add(query_618421, "Version", newJString(Version))
  result = call_618420.call(nil, query_618421, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_618405(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_618406, base: "/",
    url: url_GetDescribeEventCategories_618407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_618464 = ref object of OpenApiRestCall_616850
proc url_PostDescribeEvents_618466(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_618465(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618467 = query.getOrDefault("Action")
  valid_618467 = validateParameter(valid_618467, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_618467 != nil:
    section.add "Action", valid_618467
  var valid_618468 = query.getOrDefault("Version")
  valid_618468 = validateParameter(valid_618468, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618468 != nil:
    section.add "Version", valid_618468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618469 = header.getOrDefault("X-Amz-Date")
  valid_618469 = validateParameter(valid_618469, JString, required = false,
                                 default = nil)
  if valid_618469 != nil:
    section.add "X-Amz-Date", valid_618469
  var valid_618470 = header.getOrDefault("X-Amz-Security-Token")
  valid_618470 = validateParameter(valid_618470, JString, required = false,
                                 default = nil)
  if valid_618470 != nil:
    section.add "X-Amz-Security-Token", valid_618470
  var valid_618471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618471 = validateParameter(valid_618471, JString, required = false,
                                 default = nil)
  if valid_618471 != nil:
    section.add "X-Amz-Content-Sha256", valid_618471
  var valid_618472 = header.getOrDefault("X-Amz-Algorithm")
  valid_618472 = validateParameter(valid_618472, JString, required = false,
                                 default = nil)
  if valid_618472 != nil:
    section.add "X-Amz-Algorithm", valid_618472
  var valid_618473 = header.getOrDefault("X-Amz-Signature")
  valid_618473 = validateParameter(valid_618473, JString, required = false,
                                 default = nil)
  if valid_618473 != nil:
    section.add "X-Amz-Signature", valid_618473
  var valid_618474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618474 = validateParameter(valid_618474, JString, required = false,
                                 default = nil)
  if valid_618474 != nil:
    section.add "X-Amz-SignedHeaders", valid_618474
  var valid_618475 = header.getOrDefault("X-Amz-Credential")
  valid_618475 = validateParameter(valid_618475, JString, required = false,
                                 default = nil)
  if valid_618475 != nil:
    section.add "X-Amz-Credential", valid_618475
  result.add "header", section
  ## parameters in `formData` object:
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   StartTime: JString
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Duration: JInt
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   EndTime: JString
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   SourceIdentifier: JString
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   SourceType: JString
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  section = newJObject()
  var valid_618476 = formData.getOrDefault("EventCategories")
  valid_618476 = validateParameter(valid_618476, JArray, required = false,
                                 default = nil)
  if valid_618476 != nil:
    section.add "EventCategories", valid_618476
  var valid_618477 = formData.getOrDefault("Marker")
  valid_618477 = validateParameter(valid_618477, JString, required = false,
                                 default = nil)
  if valid_618477 != nil:
    section.add "Marker", valid_618477
  var valid_618478 = formData.getOrDefault("StartTime")
  valid_618478 = validateParameter(valid_618478, JString, required = false,
                                 default = nil)
  if valid_618478 != nil:
    section.add "StartTime", valid_618478
  var valid_618479 = formData.getOrDefault("Duration")
  valid_618479 = validateParameter(valid_618479, JInt, required = false, default = nil)
  if valid_618479 != nil:
    section.add "Duration", valid_618479
  var valid_618480 = formData.getOrDefault("Filters")
  valid_618480 = validateParameter(valid_618480, JArray, required = false,
                                 default = nil)
  if valid_618480 != nil:
    section.add "Filters", valid_618480
  var valid_618481 = formData.getOrDefault("EndTime")
  valid_618481 = validateParameter(valid_618481, JString, required = false,
                                 default = nil)
  if valid_618481 != nil:
    section.add "EndTime", valid_618481
  var valid_618482 = formData.getOrDefault("SourceIdentifier")
  valid_618482 = validateParameter(valid_618482, JString, required = false,
                                 default = nil)
  if valid_618482 != nil:
    section.add "SourceIdentifier", valid_618482
  var valid_618483 = formData.getOrDefault("MaxRecords")
  valid_618483 = validateParameter(valid_618483, JInt, required = false, default = nil)
  if valid_618483 != nil:
    section.add "MaxRecords", valid_618483
  var valid_618484 = formData.getOrDefault("SourceType")
  valid_618484 = validateParameter(valid_618484, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_618484 != nil:
    section.add "SourceType", valid_618484
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618485: Call_PostDescribeEvents_618464; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_618485.validator(path, query, header, formData, body, _)
  let scheme = call_618485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618485.url(scheme.get, call_618485.host, call_618485.base,
                         call_618485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618485, url, valid, _)

proc call*(call_618486: Call_PostDescribeEvents_618464;
          EventCategories: JsonNode = nil; Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; Filters: JsonNode = nil;
          EndTime: string = ""; SourceIdentifier: string = ""; MaxRecords: int = 0;
          Version: string = "2014-10-31"; SourceType: string = "db-instance"): Recallable =
  ## postDescribeEvents
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   StartTime: string
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Action: string (required)
  ##   Duration: int
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   EndTime: string
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   SourceIdentifier: string
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  ##   SourceType: string
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  var query_618487 = newJObject()
  var formData_618488 = newJObject()
  if EventCategories != nil:
    formData_618488.add "EventCategories", EventCategories
  add(formData_618488, "Marker", newJString(Marker))
  add(formData_618488, "StartTime", newJString(StartTime))
  add(query_618487, "Action", newJString(Action))
  add(formData_618488, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_618488.add "Filters", Filters
  add(formData_618488, "EndTime", newJString(EndTime))
  add(formData_618488, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_618488, "MaxRecords", newJInt(MaxRecords))
  add(query_618487, "Version", newJString(Version))
  add(formData_618488, "SourceType", newJString(SourceType))
  result = call_618486.call(nil, query_618487, nil, formData_618488, nil)

var postDescribeEvents* = Call_PostDescribeEvents_618464(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_618465, base: "/",
    url: url_PostDescribeEvents_618466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_618440 = ref object of OpenApiRestCall_616850
proc url_GetDescribeEvents_618442(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_618441(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   StartTime: JString
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   SourceIdentifier: JString
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Duration: JInt
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   EndTime: JString
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_618443 = query.getOrDefault("SourceType")
  valid_618443 = validateParameter(valid_618443, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_618443 != nil:
    section.add "SourceType", valid_618443
  var valid_618444 = query.getOrDefault("MaxRecords")
  valid_618444 = validateParameter(valid_618444, JInt, required = false, default = nil)
  if valid_618444 != nil:
    section.add "MaxRecords", valid_618444
  var valid_618445 = query.getOrDefault("StartTime")
  valid_618445 = validateParameter(valid_618445, JString, required = false,
                                 default = nil)
  if valid_618445 != nil:
    section.add "StartTime", valid_618445
  var valid_618446 = query.getOrDefault("Filters")
  valid_618446 = validateParameter(valid_618446, JArray, required = false,
                                 default = nil)
  if valid_618446 != nil:
    section.add "Filters", valid_618446
  var valid_618447 = query.getOrDefault("Action")
  valid_618447 = validateParameter(valid_618447, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_618447 != nil:
    section.add "Action", valid_618447
  var valid_618448 = query.getOrDefault("SourceIdentifier")
  valid_618448 = validateParameter(valid_618448, JString, required = false,
                                 default = nil)
  if valid_618448 != nil:
    section.add "SourceIdentifier", valid_618448
  var valid_618449 = query.getOrDefault("Marker")
  valid_618449 = validateParameter(valid_618449, JString, required = false,
                                 default = nil)
  if valid_618449 != nil:
    section.add "Marker", valid_618449
  var valid_618450 = query.getOrDefault("EventCategories")
  valid_618450 = validateParameter(valid_618450, JArray, required = false,
                                 default = nil)
  if valid_618450 != nil:
    section.add "EventCategories", valid_618450
  var valid_618451 = query.getOrDefault("Duration")
  valid_618451 = validateParameter(valid_618451, JInt, required = false, default = nil)
  if valid_618451 != nil:
    section.add "Duration", valid_618451
  var valid_618452 = query.getOrDefault("EndTime")
  valid_618452 = validateParameter(valid_618452, JString, required = false,
                                 default = nil)
  if valid_618452 != nil:
    section.add "EndTime", valid_618452
  var valid_618453 = query.getOrDefault("Version")
  valid_618453 = validateParameter(valid_618453, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618453 != nil:
    section.add "Version", valid_618453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618454 = header.getOrDefault("X-Amz-Date")
  valid_618454 = validateParameter(valid_618454, JString, required = false,
                                 default = nil)
  if valid_618454 != nil:
    section.add "X-Amz-Date", valid_618454
  var valid_618455 = header.getOrDefault("X-Amz-Security-Token")
  valid_618455 = validateParameter(valid_618455, JString, required = false,
                                 default = nil)
  if valid_618455 != nil:
    section.add "X-Amz-Security-Token", valid_618455
  var valid_618456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618456 = validateParameter(valid_618456, JString, required = false,
                                 default = nil)
  if valid_618456 != nil:
    section.add "X-Amz-Content-Sha256", valid_618456
  var valid_618457 = header.getOrDefault("X-Amz-Algorithm")
  valid_618457 = validateParameter(valid_618457, JString, required = false,
                                 default = nil)
  if valid_618457 != nil:
    section.add "X-Amz-Algorithm", valid_618457
  var valid_618458 = header.getOrDefault("X-Amz-Signature")
  valid_618458 = validateParameter(valid_618458, JString, required = false,
                                 default = nil)
  if valid_618458 != nil:
    section.add "X-Amz-Signature", valid_618458
  var valid_618459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618459 = validateParameter(valid_618459, JString, required = false,
                                 default = nil)
  if valid_618459 != nil:
    section.add "X-Amz-SignedHeaders", valid_618459
  var valid_618460 = header.getOrDefault("X-Amz-Credential")
  valid_618460 = validateParameter(valid_618460, JString, required = false,
                                 default = nil)
  if valid_618460 != nil:
    section.add "X-Amz-Credential", valid_618460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618461: Call_GetDescribeEvents_618440; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_618461.validator(path, query, header, formData, body, _)
  let scheme = call_618461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618461.url(scheme.get, call_618461.host, call_618461.base,
                         call_618461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618461, url, valid, _)

proc call*(call_618462: Call_GetDescribeEvents_618440;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEvents"; SourceIdentifier: string = "";
          Marker: string = ""; EventCategories: JsonNode = nil; Duration: int = 0;
          EndTime: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeEvents
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ##   SourceType: string
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   StartTime: string
  ##            : <p> The beginning of the time interval to retrieve events for, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   SourceIdentifier: string
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EventCategories: JArray
  ##                  : A list of event categories that trigger notifications for an event notification subscription.
  ##   Duration: int
  ##           : <p>The number of minutes to retrieve events for.</p> <p>Default: 60</p>
  ##   EndTime: string
  ##          : <p> The end of the time interval for which to retrieve events, specified in ISO 8601 format. </p> <p>Example: 2009-07-08T18:00Z</p>
  ##   Version: string (required)
  var query_618463 = newJObject()
  add(query_618463, "SourceType", newJString(SourceType))
  add(query_618463, "MaxRecords", newJInt(MaxRecords))
  add(query_618463, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_618463.add "Filters", Filters
  add(query_618463, "Action", newJString(Action))
  add(query_618463, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_618463, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_618463.add "EventCategories", EventCategories
  add(query_618463, "Duration", newJInt(Duration))
  add(query_618463, "EndTime", newJString(EndTime))
  add(query_618463, "Version", newJString(Version))
  result = call_618462.call(nil, query_618463, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_618440(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_618441,
    base: "/", url: url_GetDescribeEvents_618442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_618512 = ref object of OpenApiRestCall_616850
proc url_PostDescribeOrderableDBInstanceOptions_618514(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_618513(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618515 = query.getOrDefault("Action")
  valid_618515 = validateParameter(valid_618515, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_618515 != nil:
    section.add "Action", valid_618515
  var valid_618516 = query.getOrDefault("Version")
  valid_618516 = validateParameter(valid_618516, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618516 != nil:
    section.add "Version", valid_618516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618517 = header.getOrDefault("X-Amz-Date")
  valid_618517 = validateParameter(valid_618517, JString, required = false,
                                 default = nil)
  if valid_618517 != nil:
    section.add "X-Amz-Date", valid_618517
  var valid_618518 = header.getOrDefault("X-Amz-Security-Token")
  valid_618518 = validateParameter(valid_618518, JString, required = false,
                                 default = nil)
  if valid_618518 != nil:
    section.add "X-Amz-Security-Token", valid_618518
  var valid_618519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618519 = validateParameter(valid_618519, JString, required = false,
                                 default = nil)
  if valid_618519 != nil:
    section.add "X-Amz-Content-Sha256", valid_618519
  var valid_618520 = header.getOrDefault("X-Amz-Algorithm")
  valid_618520 = validateParameter(valid_618520, JString, required = false,
                                 default = nil)
  if valid_618520 != nil:
    section.add "X-Amz-Algorithm", valid_618520
  var valid_618521 = header.getOrDefault("X-Amz-Signature")
  valid_618521 = validateParameter(valid_618521, JString, required = false,
                                 default = nil)
  if valid_618521 != nil:
    section.add "X-Amz-Signature", valid_618521
  var valid_618522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618522 = validateParameter(valid_618522, JString, required = false,
                                 default = nil)
  if valid_618522 != nil:
    section.add "X-Amz-SignedHeaders", valid_618522
  var valid_618523 = header.getOrDefault("X-Amz-Credential")
  valid_618523 = validateParameter(valid_618523, JString, required = false,
                                 default = nil)
  if valid_618523 != nil:
    section.add "X-Amz-Credential", valid_618523
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  section = newJObject()
  var valid_618524 = formData.getOrDefault("DBInstanceClass")
  valid_618524 = validateParameter(valid_618524, JString, required = false,
                                 default = nil)
  if valid_618524 != nil:
    section.add "DBInstanceClass", valid_618524
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_618525 = formData.getOrDefault("Engine")
  valid_618525 = validateParameter(valid_618525, JString, required = true,
                                 default = nil)
  if valid_618525 != nil:
    section.add "Engine", valid_618525
  var valid_618526 = formData.getOrDefault("Vpc")
  valid_618526 = validateParameter(valid_618526, JBool, required = false, default = nil)
  if valid_618526 != nil:
    section.add "Vpc", valid_618526
  var valid_618527 = formData.getOrDefault("Filters")
  valid_618527 = validateParameter(valid_618527, JArray, required = false,
                                 default = nil)
  if valid_618527 != nil:
    section.add "Filters", valid_618527
  var valid_618528 = formData.getOrDefault("LicenseModel")
  valid_618528 = validateParameter(valid_618528, JString, required = false,
                                 default = nil)
  if valid_618528 != nil:
    section.add "LicenseModel", valid_618528
  var valid_618529 = formData.getOrDefault("Marker")
  valid_618529 = validateParameter(valid_618529, JString, required = false,
                                 default = nil)
  if valid_618529 != nil:
    section.add "Marker", valid_618529
  var valid_618530 = formData.getOrDefault("MaxRecords")
  valid_618530 = validateParameter(valid_618530, JInt, required = false, default = nil)
  if valid_618530 != nil:
    section.add "MaxRecords", valid_618530
  var valid_618531 = formData.getOrDefault("EngineVersion")
  valid_618531 = validateParameter(valid_618531, JString, required = false,
                                 default = nil)
  if valid_618531 != nil:
    section.add "EngineVersion", valid_618531
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618532: Call_PostDescribeOrderableDBInstanceOptions_618512;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  let valid = call_618532.validator(path, query, header, formData, body, _)
  let scheme = call_618532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618532.url(scheme.get, call_618532.host, call_618532.base,
                         call_618532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618532, url, valid, _)

proc call*(call_618533: Call_PostDescribeOrderableDBInstanceOptions_618512;
          Engine: string; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          Filters: JsonNode = nil; LicenseModel: string = ""; Marker: string = "";
          MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable instance options for the specified engine.
  ##   DBInstanceClass: string
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   Action: string (required)
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: string (required)
  var query_618534 = newJObject()
  var formData_618535 = newJObject()
  add(formData_618535, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_618535, "Engine", newJString(Engine))
  add(query_618534, "Action", newJString(Action))
  add(formData_618535, "Vpc", newJBool(Vpc))
  if Filters != nil:
    formData_618535.add "Filters", Filters
  add(formData_618535, "LicenseModel", newJString(LicenseModel))
  add(formData_618535, "Marker", newJString(Marker))
  add(formData_618535, "MaxRecords", newJInt(MaxRecords))
  add(formData_618535, "EngineVersion", newJString(EngineVersion))
  add(query_618534, "Version", newJString(Version))
  result = call_618533.call(nil, query_618534, nil, formData_618535, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_618512(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_618513, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_618514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_618489 = ref object of OpenApiRestCall_616850
proc url_GetDescribeOrderableDBInstanceOptions_618491(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_618490(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   DBInstanceClass: JString
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   Version: JString (required)
  section = newJObject()
  var valid_618492 = query.getOrDefault("MaxRecords")
  valid_618492 = validateParameter(valid_618492, JInt, required = false, default = nil)
  if valid_618492 != nil:
    section.add "MaxRecords", valid_618492
  var valid_618493 = query.getOrDefault("Filters")
  valid_618493 = validateParameter(valid_618493, JArray, required = false,
                                 default = nil)
  if valid_618493 != nil:
    section.add "Filters", valid_618493
  var valid_618494 = query.getOrDefault("LicenseModel")
  valid_618494 = validateParameter(valid_618494, JString, required = false,
                                 default = nil)
  if valid_618494 != nil:
    section.add "LicenseModel", valid_618494
  var valid_618495 = query.getOrDefault("DBInstanceClass")
  valid_618495 = validateParameter(valid_618495, JString, required = false,
                                 default = nil)
  if valid_618495 != nil:
    section.add "DBInstanceClass", valid_618495
  var valid_618496 = query.getOrDefault("Action")
  valid_618496 = validateParameter(valid_618496, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_618496 != nil:
    section.add "Action", valid_618496
  var valid_618497 = query.getOrDefault("Marker")
  valid_618497 = validateParameter(valid_618497, JString, required = false,
                                 default = nil)
  if valid_618497 != nil:
    section.add "Marker", valid_618497
  var valid_618498 = query.getOrDefault("EngineVersion")
  valid_618498 = validateParameter(valid_618498, JString, required = false,
                                 default = nil)
  if valid_618498 != nil:
    section.add "EngineVersion", valid_618498
  var valid_618499 = query.getOrDefault("Vpc")
  valid_618499 = validateParameter(valid_618499, JBool, required = false, default = nil)
  if valid_618499 != nil:
    section.add "Vpc", valid_618499
  var valid_618500 = query.getOrDefault("Engine")
  valid_618500 = validateParameter(valid_618500, JString, required = true,
                                 default = nil)
  if valid_618500 != nil:
    section.add "Engine", valid_618500
  var valid_618501 = query.getOrDefault("Version")
  valid_618501 = validateParameter(valid_618501, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618501 != nil:
    section.add "Version", valid_618501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618502 = header.getOrDefault("X-Amz-Date")
  valid_618502 = validateParameter(valid_618502, JString, required = false,
                                 default = nil)
  if valid_618502 != nil:
    section.add "X-Amz-Date", valid_618502
  var valid_618503 = header.getOrDefault("X-Amz-Security-Token")
  valid_618503 = validateParameter(valid_618503, JString, required = false,
                                 default = nil)
  if valid_618503 != nil:
    section.add "X-Amz-Security-Token", valid_618503
  var valid_618504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618504 = validateParameter(valid_618504, JString, required = false,
                                 default = nil)
  if valid_618504 != nil:
    section.add "X-Amz-Content-Sha256", valid_618504
  var valid_618505 = header.getOrDefault("X-Amz-Algorithm")
  valid_618505 = validateParameter(valid_618505, JString, required = false,
                                 default = nil)
  if valid_618505 != nil:
    section.add "X-Amz-Algorithm", valid_618505
  var valid_618506 = header.getOrDefault("X-Amz-Signature")
  valid_618506 = validateParameter(valid_618506, JString, required = false,
                                 default = nil)
  if valid_618506 != nil:
    section.add "X-Amz-Signature", valid_618506
  var valid_618507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618507 = validateParameter(valid_618507, JString, required = false,
                                 default = nil)
  if valid_618507 != nil:
    section.add "X-Amz-SignedHeaders", valid_618507
  var valid_618508 = header.getOrDefault("X-Amz-Credential")
  valid_618508 = validateParameter(valid_618508, JString, required = false,
                                 default = nil)
  if valid_618508 != nil:
    section.add "X-Amz-Credential", valid_618508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618509: Call_GetDescribeOrderableDBInstanceOptions_618489;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  let valid = call_618509.validator(path, query, header, formData, body, _)
  let scheme = call_618509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618509.url(scheme.get, call_618509.host, call_618509.base,
                         call_618509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618509, url, valid, _)

proc call*(call_618510: Call_GetDescribeOrderableDBInstanceOptions_618489;
          Engine: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          LicenseModel: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = ""; Vpc: bool = false;
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable instance options for the specified engine.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   DBInstanceClass: string
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   Version: string (required)
  var query_618511 = newJObject()
  add(query_618511, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_618511.add "Filters", Filters
  add(query_618511, "LicenseModel", newJString(LicenseModel))
  add(query_618511, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_618511, "Action", newJString(Action))
  add(query_618511, "Marker", newJString(Marker))
  add(query_618511, "EngineVersion", newJString(EngineVersion))
  add(query_618511, "Vpc", newJBool(Vpc))
  add(query_618511, "Engine", newJString(Engine))
  add(query_618511, "Version", newJString(Version))
  result = call_618510.call(nil, query_618511, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_618489(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_618490, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_618491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_618555 = ref object of OpenApiRestCall_616850
proc url_PostDescribePendingMaintenanceActions_618557(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribePendingMaintenanceActions_618556(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618558 = query.getOrDefault("Action")
  valid_618558 = validateParameter(valid_618558, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_618558 != nil:
    section.add "Action", valid_618558
  var valid_618559 = query.getOrDefault("Version")
  valid_618559 = validateParameter(valid_618559, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618559 != nil:
    section.add "Version", valid_618559
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618560 = header.getOrDefault("X-Amz-Date")
  valid_618560 = validateParameter(valid_618560, JString, required = false,
                                 default = nil)
  if valid_618560 != nil:
    section.add "X-Amz-Date", valid_618560
  var valid_618561 = header.getOrDefault("X-Amz-Security-Token")
  valid_618561 = validateParameter(valid_618561, JString, required = false,
                                 default = nil)
  if valid_618561 != nil:
    section.add "X-Amz-Security-Token", valid_618561
  var valid_618562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618562 = validateParameter(valid_618562, JString, required = false,
                                 default = nil)
  if valid_618562 != nil:
    section.add "X-Amz-Content-Sha256", valid_618562
  var valid_618563 = header.getOrDefault("X-Amz-Algorithm")
  valid_618563 = validateParameter(valid_618563, JString, required = false,
                                 default = nil)
  if valid_618563 != nil:
    section.add "X-Amz-Algorithm", valid_618563
  var valid_618564 = header.getOrDefault("X-Amz-Signature")
  valid_618564 = validateParameter(valid_618564, JString, required = false,
                                 default = nil)
  if valid_618564 != nil:
    section.add "X-Amz-Signature", valid_618564
  var valid_618565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618565 = validateParameter(valid_618565, JString, required = false,
                                 default = nil)
  if valid_618565 != nil:
    section.add "X-Amz-SignedHeaders", valid_618565
  var valid_618566 = header.getOrDefault("X-Amz-Credential")
  valid_618566 = validateParameter(valid_618566, JString, required = false,
                                 default = nil)
  if valid_618566 != nil:
    section.add "X-Amz-Credential", valid_618566
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_618567 = formData.getOrDefault("ResourceIdentifier")
  valid_618567 = validateParameter(valid_618567, JString, required = false,
                                 default = nil)
  if valid_618567 != nil:
    section.add "ResourceIdentifier", valid_618567
  var valid_618568 = formData.getOrDefault("Filters")
  valid_618568 = validateParameter(valid_618568, JArray, required = false,
                                 default = nil)
  if valid_618568 != nil:
    section.add "Filters", valid_618568
  var valid_618569 = formData.getOrDefault("Marker")
  valid_618569 = validateParameter(valid_618569, JString, required = false,
                                 default = nil)
  if valid_618569 != nil:
    section.add "Marker", valid_618569
  var valid_618570 = formData.getOrDefault("MaxRecords")
  valid_618570 = validateParameter(valid_618570, JInt, required = false, default = nil)
  if valid_618570 != nil:
    section.add "MaxRecords", valid_618570
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618571: Call_PostDescribePendingMaintenanceActions_618555;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ## 
  let valid = call_618571.validator(path, query, header, formData, body, _)
  let scheme = call_618571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618571.url(scheme.get, call_618571.host, call_618571.base,
                         call_618571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618571, url, valid, _)

proc call*(call_618572: Call_PostDescribePendingMaintenanceActions_618555;
          Action: string = "DescribePendingMaintenanceActions";
          ResourceIdentifier: string = ""; Filters: JsonNode = nil; Marker: string = "";
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ##   Action: string (required)
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_618573 = newJObject()
  var formData_618574 = newJObject()
  add(query_618573, "Action", newJString(Action))
  add(formData_618574, "ResourceIdentifier", newJString(ResourceIdentifier))
  if Filters != nil:
    formData_618574.add "Filters", Filters
  add(formData_618574, "Marker", newJString(Marker))
  add(formData_618574, "MaxRecords", newJInt(MaxRecords))
  add(query_618573, "Version", newJString(Version))
  result = call_618572.call(nil, query_618573, nil, formData_618574, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_618555(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_618556, base: "/",
    url: url_PostDescribePendingMaintenanceActions_618557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_618536 = ref object of OpenApiRestCall_616850
proc url_GetDescribePendingMaintenanceActions_618538(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribePendingMaintenanceActions_618537(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_618539 = query.getOrDefault("MaxRecords")
  valid_618539 = validateParameter(valid_618539, JInt, required = false, default = nil)
  if valid_618539 != nil:
    section.add "MaxRecords", valid_618539
  var valid_618540 = query.getOrDefault("Filters")
  valid_618540 = validateParameter(valid_618540, JArray, required = false,
                                 default = nil)
  if valid_618540 != nil:
    section.add "Filters", valid_618540
  var valid_618541 = query.getOrDefault("ResourceIdentifier")
  valid_618541 = validateParameter(valid_618541, JString, required = false,
                                 default = nil)
  if valid_618541 != nil:
    section.add "ResourceIdentifier", valid_618541
  var valid_618542 = query.getOrDefault("Action")
  valid_618542 = validateParameter(valid_618542, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_618542 != nil:
    section.add "Action", valid_618542
  var valid_618543 = query.getOrDefault("Marker")
  valid_618543 = validateParameter(valid_618543, JString, required = false,
                                 default = nil)
  if valid_618543 != nil:
    section.add "Marker", valid_618543
  var valid_618544 = query.getOrDefault("Version")
  valid_618544 = validateParameter(valid_618544, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618544 != nil:
    section.add "Version", valid_618544
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618545 = header.getOrDefault("X-Amz-Date")
  valid_618545 = validateParameter(valid_618545, JString, required = false,
                                 default = nil)
  if valid_618545 != nil:
    section.add "X-Amz-Date", valid_618545
  var valid_618546 = header.getOrDefault("X-Amz-Security-Token")
  valid_618546 = validateParameter(valid_618546, JString, required = false,
                                 default = nil)
  if valid_618546 != nil:
    section.add "X-Amz-Security-Token", valid_618546
  var valid_618547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618547 = validateParameter(valid_618547, JString, required = false,
                                 default = nil)
  if valid_618547 != nil:
    section.add "X-Amz-Content-Sha256", valid_618547
  var valid_618548 = header.getOrDefault("X-Amz-Algorithm")
  valid_618548 = validateParameter(valid_618548, JString, required = false,
                                 default = nil)
  if valid_618548 != nil:
    section.add "X-Amz-Algorithm", valid_618548
  var valid_618549 = header.getOrDefault("X-Amz-Signature")
  valid_618549 = validateParameter(valid_618549, JString, required = false,
                                 default = nil)
  if valid_618549 != nil:
    section.add "X-Amz-Signature", valid_618549
  var valid_618550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618550 = validateParameter(valid_618550, JString, required = false,
                                 default = nil)
  if valid_618550 != nil:
    section.add "X-Amz-SignedHeaders", valid_618550
  var valid_618551 = header.getOrDefault("X-Amz-Credential")
  valid_618551 = validateParameter(valid_618551, JString, required = false,
                                 default = nil)
  if valid_618551 != nil:
    section.add "X-Amz-Credential", valid_618551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618552: Call_GetDescribePendingMaintenanceActions_618536;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ## 
  let valid = call_618552.validator(path, query, header, formData, body, _)
  let scheme = call_618552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618552.url(scheme.get, call_618552.host, call_618552.base,
                         call_618552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618552, url, valid, _)

proc call*(call_618553: Call_GetDescribePendingMaintenanceActions_618536;
          MaxRecords: int = 0; Filters: JsonNode = nil; ResourceIdentifier: string = "";
          Action: string = "DescribePendingMaintenanceActions"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_618554 = newJObject()
  add(query_618554, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_618554.add "Filters", Filters
  add(query_618554, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_618554, "Action", newJString(Action))
  add(query_618554, "Marker", newJString(Marker))
  add(query_618554, "Version", newJString(Version))
  result = call_618553.call(nil, query_618554, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_618536(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_618537, base: "/",
    url: url_GetDescribePendingMaintenanceActions_618538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_618592 = ref object of OpenApiRestCall_616850
proc url_PostFailoverDBCluster_618594(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostFailoverDBCluster_618593(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618595 = query.getOrDefault("Action")
  valid_618595 = validateParameter(valid_618595, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_618595 != nil:
    section.add "Action", valid_618595
  var valid_618596 = query.getOrDefault("Version")
  valid_618596 = validateParameter(valid_618596, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618596 != nil:
    section.add "Version", valid_618596
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618597 = header.getOrDefault("X-Amz-Date")
  valid_618597 = validateParameter(valid_618597, JString, required = false,
                                 default = nil)
  if valid_618597 != nil:
    section.add "X-Amz-Date", valid_618597
  var valid_618598 = header.getOrDefault("X-Amz-Security-Token")
  valid_618598 = validateParameter(valid_618598, JString, required = false,
                                 default = nil)
  if valid_618598 != nil:
    section.add "X-Amz-Security-Token", valid_618598
  var valid_618599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618599 = validateParameter(valid_618599, JString, required = false,
                                 default = nil)
  if valid_618599 != nil:
    section.add "X-Amz-Content-Sha256", valid_618599
  var valid_618600 = header.getOrDefault("X-Amz-Algorithm")
  valid_618600 = validateParameter(valid_618600, JString, required = false,
                                 default = nil)
  if valid_618600 != nil:
    section.add "X-Amz-Algorithm", valid_618600
  var valid_618601 = header.getOrDefault("X-Amz-Signature")
  valid_618601 = validateParameter(valid_618601, JString, required = false,
                                 default = nil)
  if valid_618601 != nil:
    section.add "X-Amz-Signature", valid_618601
  var valid_618602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618602 = validateParameter(valid_618602, JString, required = false,
                                 default = nil)
  if valid_618602 != nil:
    section.add "X-Amz-SignedHeaders", valid_618602
  var valid_618603 = header.getOrDefault("X-Amz-Credential")
  valid_618603 = validateParameter(valid_618603, JString, required = false,
                                 default = nil)
  if valid_618603 != nil:
    section.add "X-Amz-Credential", valid_618603
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_618604 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_618604 = validateParameter(valid_618604, JString, required = false,
                                 default = nil)
  if valid_618604 != nil:
    section.add "TargetDBInstanceIdentifier", valid_618604
  var valid_618605 = formData.getOrDefault("DBClusterIdentifier")
  valid_618605 = validateParameter(valid_618605, JString, required = false,
                                 default = nil)
  if valid_618605 != nil:
    section.add "DBClusterIdentifier", valid_618605
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618606: Call_PostFailoverDBCluster_618592; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_618606.validator(path, query, header, formData, body, _)
  let scheme = call_618606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618606.url(scheme.get, call_618606.host, call_618606.base,
                         call_618606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618606, url, valid, _)

proc call*(call_618607: Call_PostFailoverDBCluster_618592;
          Action: string = "FailoverDBCluster";
          TargetDBInstanceIdentifier: string = ""; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postFailoverDBCluster
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ##   Action: string (required)
  ##   TargetDBInstanceIdentifier: string
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>A cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_618608 = newJObject()
  var formData_618609 = newJObject()
  add(query_618608, "Action", newJString(Action))
  add(formData_618609, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_618609, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_618608, "Version", newJString(Version))
  result = call_618607.call(nil, query_618608, nil, formData_618609, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_618592(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_618593, base: "/",
    url: url_PostFailoverDBCluster_618594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_618575 = ref object of OpenApiRestCall_616850
proc url_GetFailoverDBCluster_618577(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFailoverDBCluster_618576(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString
  ##                      : <p>A cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Action: JString (required)
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_618578 = query.getOrDefault("DBClusterIdentifier")
  valid_618578 = validateParameter(valid_618578, JString, required = false,
                                 default = nil)
  if valid_618578 != nil:
    section.add "DBClusterIdentifier", valid_618578
  var valid_618579 = query.getOrDefault("Action")
  valid_618579 = validateParameter(valid_618579, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_618579 != nil:
    section.add "Action", valid_618579
  var valid_618580 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_618580 = validateParameter(valid_618580, JString, required = false,
                                 default = nil)
  if valid_618580 != nil:
    section.add "TargetDBInstanceIdentifier", valid_618580
  var valid_618581 = query.getOrDefault("Version")
  valid_618581 = validateParameter(valid_618581, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618581 != nil:
    section.add "Version", valid_618581
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618582 = header.getOrDefault("X-Amz-Date")
  valid_618582 = validateParameter(valid_618582, JString, required = false,
                                 default = nil)
  if valid_618582 != nil:
    section.add "X-Amz-Date", valid_618582
  var valid_618583 = header.getOrDefault("X-Amz-Security-Token")
  valid_618583 = validateParameter(valid_618583, JString, required = false,
                                 default = nil)
  if valid_618583 != nil:
    section.add "X-Amz-Security-Token", valid_618583
  var valid_618584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618584 = validateParameter(valid_618584, JString, required = false,
                                 default = nil)
  if valid_618584 != nil:
    section.add "X-Amz-Content-Sha256", valid_618584
  var valid_618585 = header.getOrDefault("X-Amz-Algorithm")
  valid_618585 = validateParameter(valid_618585, JString, required = false,
                                 default = nil)
  if valid_618585 != nil:
    section.add "X-Amz-Algorithm", valid_618585
  var valid_618586 = header.getOrDefault("X-Amz-Signature")
  valid_618586 = validateParameter(valid_618586, JString, required = false,
                                 default = nil)
  if valid_618586 != nil:
    section.add "X-Amz-Signature", valid_618586
  var valid_618587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618587 = validateParameter(valid_618587, JString, required = false,
                                 default = nil)
  if valid_618587 != nil:
    section.add "X-Amz-SignedHeaders", valid_618587
  var valid_618588 = header.getOrDefault("X-Amz-Credential")
  valid_618588 = validateParameter(valid_618588, JString, required = false,
                                 default = nil)
  if valid_618588 != nil:
    section.add "X-Amz-Credential", valid_618588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618589: Call_GetFailoverDBCluster_618575; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_618589.validator(path, query, header, formData, body, _)
  let scheme = call_618589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618589.url(scheme.get, call_618589.host, call_618589.base,
                         call_618589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618589, url, valid, _)

proc call*(call_618590: Call_GetFailoverDBCluster_618575;
          DBClusterIdentifier: string = ""; Action: string = "FailoverDBCluster";
          TargetDBInstanceIdentifier: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getFailoverDBCluster
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>A cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   TargetDBInstanceIdentifier: string
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   Version: string (required)
  var query_618591 = newJObject()
  add(query_618591, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_618591, "Action", newJString(Action))
  add(query_618591, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_618591, "Version", newJString(Version))
  result = call_618590.call(nil, query_618591, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_618575(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_618576, base: "/",
    url: url_GetFailoverDBCluster_618577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_618627 = ref object of OpenApiRestCall_616850
proc url_PostListTagsForResource_618629(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_618628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618630 = query.getOrDefault("Action")
  valid_618630 = validateParameter(valid_618630, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_618630 != nil:
    section.add "Action", valid_618630
  var valid_618631 = query.getOrDefault("Version")
  valid_618631 = validateParameter(valid_618631, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618631 != nil:
    section.add "Version", valid_618631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618632 = header.getOrDefault("X-Amz-Date")
  valid_618632 = validateParameter(valid_618632, JString, required = false,
                                 default = nil)
  if valid_618632 != nil:
    section.add "X-Amz-Date", valid_618632
  var valid_618633 = header.getOrDefault("X-Amz-Security-Token")
  valid_618633 = validateParameter(valid_618633, JString, required = false,
                                 default = nil)
  if valid_618633 != nil:
    section.add "X-Amz-Security-Token", valid_618633
  var valid_618634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618634 = validateParameter(valid_618634, JString, required = false,
                                 default = nil)
  if valid_618634 != nil:
    section.add "X-Amz-Content-Sha256", valid_618634
  var valid_618635 = header.getOrDefault("X-Amz-Algorithm")
  valid_618635 = validateParameter(valid_618635, JString, required = false,
                                 default = nil)
  if valid_618635 != nil:
    section.add "X-Amz-Algorithm", valid_618635
  var valid_618636 = header.getOrDefault("X-Amz-Signature")
  valid_618636 = validateParameter(valid_618636, JString, required = false,
                                 default = nil)
  if valid_618636 != nil:
    section.add "X-Amz-Signature", valid_618636
  var valid_618637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618637 = validateParameter(valid_618637, JString, required = false,
                                 default = nil)
  if valid_618637 != nil:
    section.add "X-Amz-SignedHeaders", valid_618637
  var valid_618638 = header.getOrDefault("X-Amz-Credential")
  valid_618638 = validateParameter(valid_618638, JString, required = false,
                                 default = nil)
  if valid_618638 != nil:
    section.add "X-Amz-Credential", valid_618638
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_618639 = formData.getOrDefault("Filters")
  valid_618639 = validateParameter(valid_618639, JArray, required = false,
                                 default = nil)
  if valid_618639 != nil:
    section.add "Filters", valid_618639
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_618640 = formData.getOrDefault("ResourceName")
  valid_618640 = validateParameter(valid_618640, JString, required = true,
                                 default = nil)
  if valid_618640 != nil:
    section.add "ResourceName", valid_618640
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618641: Call_PostListTagsForResource_618627; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_618641.validator(path, query, header, formData, body, _)
  let scheme = call_618641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618641.url(scheme.get, call_618641.host, call_618641.base,
                         call_618641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618641, url, valid, _)

proc call*(call_618642: Call_PostListTagsForResource_618627; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postListTagsForResource
  ## Lists all tags on an Amazon DocumentDB resource.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_618643 = newJObject()
  var formData_618644 = newJObject()
  add(query_618643, "Action", newJString(Action))
  if Filters != nil:
    formData_618644.add "Filters", Filters
  add(formData_618644, "ResourceName", newJString(ResourceName))
  add(query_618643, "Version", newJString(Version))
  result = call_618642.call(nil, query_618643, nil, formData_618644, nil)

var postListTagsForResource* = Call_PostListTagsForResource_618627(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_618628, base: "/",
    url: url_PostListTagsForResource_618629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_618610 = ref object of OpenApiRestCall_616850
proc url_GetListTagsForResource_618612(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_618611(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Version: JString (required)
  section = newJObject()
  var valid_618613 = query.getOrDefault("Filters")
  valid_618613 = validateParameter(valid_618613, JArray, required = false,
                                 default = nil)
  if valid_618613 != nil:
    section.add "Filters", valid_618613
  var valid_618614 = query.getOrDefault("Action")
  valid_618614 = validateParameter(valid_618614, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_618614 != nil:
    section.add "Action", valid_618614
  var valid_618615 = query.getOrDefault("ResourceName")
  valid_618615 = validateParameter(valid_618615, JString, required = true,
                                 default = nil)
  if valid_618615 != nil:
    section.add "ResourceName", valid_618615
  var valid_618616 = query.getOrDefault("Version")
  valid_618616 = validateParameter(valid_618616, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618616 != nil:
    section.add "Version", valid_618616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618617 = header.getOrDefault("X-Amz-Date")
  valid_618617 = validateParameter(valid_618617, JString, required = false,
                                 default = nil)
  if valid_618617 != nil:
    section.add "X-Amz-Date", valid_618617
  var valid_618618 = header.getOrDefault("X-Amz-Security-Token")
  valid_618618 = validateParameter(valid_618618, JString, required = false,
                                 default = nil)
  if valid_618618 != nil:
    section.add "X-Amz-Security-Token", valid_618618
  var valid_618619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618619 = validateParameter(valid_618619, JString, required = false,
                                 default = nil)
  if valid_618619 != nil:
    section.add "X-Amz-Content-Sha256", valid_618619
  var valid_618620 = header.getOrDefault("X-Amz-Algorithm")
  valid_618620 = validateParameter(valid_618620, JString, required = false,
                                 default = nil)
  if valid_618620 != nil:
    section.add "X-Amz-Algorithm", valid_618620
  var valid_618621 = header.getOrDefault("X-Amz-Signature")
  valid_618621 = validateParameter(valid_618621, JString, required = false,
                                 default = nil)
  if valid_618621 != nil:
    section.add "X-Amz-Signature", valid_618621
  var valid_618622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618622 = validateParameter(valid_618622, JString, required = false,
                                 default = nil)
  if valid_618622 != nil:
    section.add "X-Amz-SignedHeaders", valid_618622
  var valid_618623 = header.getOrDefault("X-Amz-Credential")
  valid_618623 = validateParameter(valid_618623, JString, required = false,
                                 default = nil)
  if valid_618623 != nil:
    section.add "X-Amz-Credential", valid_618623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618624: Call_GetListTagsForResource_618610; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_618624.validator(path, query, header, formData, body, _)
  let scheme = call_618624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618624.url(scheme.get, call_618624.host, call_618624.base,
                         call_618624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618624, url, valid, _)

proc call*(call_618625: Call_GetListTagsForResource_618610; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-10-31"): Recallable =
  ## getListTagsForResource
  ## Lists all tags on an Amazon DocumentDB resource.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_618626 = newJObject()
  if Filters != nil:
    query_618626.add "Filters", Filters
  add(query_618626, "Action", newJString(Action))
  add(query_618626, "ResourceName", newJString(ResourceName))
  add(query_618626, "Version", newJString(Version))
  result = call_618625.call(nil, query_618626, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_618610(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_618611, base: "/",
    url: url_GetListTagsForResource_618612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_618674 = ref object of OpenApiRestCall_616850
proc url_PostModifyDBCluster_618676(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBCluster_618675(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618677 = query.getOrDefault("Action")
  valid_618677 = validateParameter(valid_618677, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_618677 != nil:
    section.add "Action", valid_618677
  var valid_618678 = query.getOrDefault("Version")
  valid_618678 = validateParameter(valid_618678, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618678 != nil:
    section.add "Version", valid_618678
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618679 = header.getOrDefault("X-Amz-Date")
  valid_618679 = validateParameter(valid_618679, JString, required = false,
                                 default = nil)
  if valid_618679 != nil:
    section.add "X-Amz-Date", valid_618679
  var valid_618680 = header.getOrDefault("X-Amz-Security-Token")
  valid_618680 = validateParameter(valid_618680, JString, required = false,
                                 default = nil)
  if valid_618680 != nil:
    section.add "X-Amz-Security-Token", valid_618680
  var valid_618681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618681 = validateParameter(valid_618681, JString, required = false,
                                 default = nil)
  if valid_618681 != nil:
    section.add "X-Amz-Content-Sha256", valid_618681
  var valid_618682 = header.getOrDefault("X-Amz-Algorithm")
  valid_618682 = validateParameter(valid_618682, JString, required = false,
                                 default = nil)
  if valid_618682 != nil:
    section.add "X-Amz-Algorithm", valid_618682
  var valid_618683 = header.getOrDefault("X-Amz-Signature")
  valid_618683 = validateParameter(valid_618683, JString, required = false,
                                 default = nil)
  if valid_618683 != nil:
    section.add "X-Amz-Signature", valid_618683
  var valid_618684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618684 = validateParameter(valid_618684, JString, required = false,
                                 default = nil)
  if valid_618684 != nil:
    section.add "X-Amz-SignedHeaders", valid_618684
  var valid_618685 = header.getOrDefault("X-Amz-Credential")
  valid_618685 = validateParameter(valid_618685, JString, required = false,
                                 default = nil)
  if valid_618685 != nil:
    section.add "X-Amz-Credential", valid_618685
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   Port: JInt
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  var valid_618686 = formData.getOrDefault("ApplyImmediately")
  valid_618686 = validateParameter(valid_618686, JBool, required = false, default = nil)
  if valid_618686 != nil:
    section.add "ApplyImmediately", valid_618686
  var valid_618687 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_618687 = validateParameter(valid_618687, JArray, required = false,
                                 default = nil)
  if valid_618687 != nil:
    section.add "VpcSecurityGroupIds", valid_618687
  var valid_618688 = formData.getOrDefault("BackupRetentionPeriod")
  valid_618688 = validateParameter(valid_618688, JInt, required = false, default = nil)
  if valid_618688 != nil:
    section.add "BackupRetentionPeriod", valid_618688
  var valid_618689 = formData.getOrDefault("MasterUserPassword")
  valid_618689 = validateParameter(valid_618689, JString, required = false,
                                 default = nil)
  if valid_618689 != nil:
    section.add "MasterUserPassword", valid_618689
  var valid_618690 = formData.getOrDefault("DeletionProtection")
  valid_618690 = validateParameter(valid_618690, JBool, required = false, default = nil)
  if valid_618690 != nil:
    section.add "DeletionProtection", valid_618690
  var valid_618691 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_618691 = validateParameter(valid_618691, JString, required = false,
                                 default = nil)
  if valid_618691 != nil:
    section.add "NewDBClusterIdentifier", valid_618691
  var valid_618692 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_618692 = validateParameter(valid_618692, JString, required = false,
                                 default = nil)
  if valid_618692 != nil:
    section.add "DBClusterParameterGroupName", valid_618692
  var valid_618693 = formData.getOrDefault("Port")
  valid_618693 = validateParameter(valid_618693, JInt, required = false, default = nil)
  if valid_618693 != nil:
    section.add "Port", valid_618693
  var valid_618694 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_618694 = validateParameter(valid_618694, JArray, required = false,
                                 default = nil)
  if valid_618694 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_618694
  var valid_618695 = formData.getOrDefault("PreferredBackupWindow")
  valid_618695 = validateParameter(valid_618695, JString, required = false,
                                 default = nil)
  if valid_618695 != nil:
    section.add "PreferredBackupWindow", valid_618695
  var valid_618696 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_618696 = validateParameter(valid_618696, JArray, required = false,
                                 default = nil)
  if valid_618696 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_618696
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_618697 = formData.getOrDefault("DBClusterIdentifier")
  valid_618697 = validateParameter(valid_618697, JString, required = true,
                                 default = nil)
  if valid_618697 != nil:
    section.add "DBClusterIdentifier", valid_618697
  var valid_618698 = formData.getOrDefault("EngineVersion")
  valid_618698 = validateParameter(valid_618698, JString, required = false,
                                 default = nil)
  if valid_618698 != nil:
    section.add "EngineVersion", valid_618698
  var valid_618699 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_618699 = validateParameter(valid_618699, JString, required = false,
                                 default = nil)
  if valid_618699 != nil:
    section.add "PreferredMaintenanceWindow", valid_618699
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618700: Call_PostModifyDBCluster_618674; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_618700.validator(path, query, header, formData, body, _)
  let scheme = call_618700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618700.url(scheme.get, call_618700.host, call_618700.base,
                         call_618700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618700, url, valid, _)

proc call*(call_618701: Call_PostModifyDBCluster_618674;
          DBClusterIdentifier: string; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          MasterUserPassword: string = ""; DeletionProtection: bool = false;
          NewDBClusterIdentifier: string = ""; Action: string = "ModifyDBCluster";
          DBClusterParameterGroupName: string = ""; Port: int = 0;
          CloudwatchLogsExportConfigurationDisableLogTypes: JsonNode = nil;
          PreferredBackupWindow: string = "";
          CloudwatchLogsExportConfigurationEnableLogTypes: JsonNode = nil;
          EngineVersion: string = ""; Version: string = "2014-10-31";
          PreferredMaintenanceWindow: string = ""): Recallable =
  ## postModifyDBCluster
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   Port: int
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_618702 = newJObject()
  var formData_618703 = newJObject()
  add(formData_618703, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_618703.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_618703, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_618703, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_618703, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_618703, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  add(query_618702, "Action", newJString(Action))
  add(formData_618703, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_618703, "Port", newJInt(Port))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_618703.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  add(formData_618703, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_618703.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_618703, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_618703, "EngineVersion", newJString(EngineVersion))
  add(query_618702, "Version", newJString(Version))
  add(formData_618703, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_618701.call(nil, query_618702, nil, formData_618703, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_618674(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_618675, base: "/",
    url: url_PostModifyDBCluster_618676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_618645 = ref object of OpenApiRestCall_616850
proc url_GetModifyDBCluster_618647(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBCluster_618646(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: JString (required)
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Port: JInt
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: JString (required)
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_618648 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_618648 = validateParameter(valid_618648, JString, required = false,
                                 default = nil)
  if valid_618648 != nil:
    section.add "PreferredMaintenanceWindow", valid_618648
  var valid_618649 = query.getOrDefault("DBClusterParameterGroupName")
  valid_618649 = validateParameter(valid_618649, JString, required = false,
                                 default = nil)
  if valid_618649 != nil:
    section.add "DBClusterParameterGroupName", valid_618649
  var valid_618650 = query.getOrDefault("MasterUserPassword")
  valid_618650 = validateParameter(valid_618650, JString, required = false,
                                 default = nil)
  if valid_618650 != nil:
    section.add "MasterUserPassword", valid_618650
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_618651 = query.getOrDefault("DBClusterIdentifier")
  valid_618651 = validateParameter(valid_618651, JString, required = true,
                                 default = nil)
  if valid_618651 != nil:
    section.add "DBClusterIdentifier", valid_618651
  var valid_618652 = query.getOrDefault("BackupRetentionPeriod")
  valid_618652 = validateParameter(valid_618652, JInt, required = false, default = nil)
  if valid_618652 != nil:
    section.add "BackupRetentionPeriod", valid_618652
  var valid_618653 = query.getOrDefault("VpcSecurityGroupIds")
  valid_618653 = validateParameter(valid_618653, JArray, required = false,
                                 default = nil)
  if valid_618653 != nil:
    section.add "VpcSecurityGroupIds", valid_618653
  var valid_618654 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_618654 = validateParameter(valid_618654, JArray, required = false,
                                 default = nil)
  if valid_618654 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_618654
  var valid_618655 = query.getOrDefault("NewDBClusterIdentifier")
  valid_618655 = validateParameter(valid_618655, JString, required = false,
                                 default = nil)
  if valid_618655 != nil:
    section.add "NewDBClusterIdentifier", valid_618655
  var valid_618656 = query.getOrDefault("DeletionProtection")
  valid_618656 = validateParameter(valid_618656, JBool, required = false, default = nil)
  if valid_618656 != nil:
    section.add "DeletionProtection", valid_618656
  var valid_618657 = query.getOrDefault("Action")
  valid_618657 = validateParameter(valid_618657, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_618657 != nil:
    section.add "Action", valid_618657
  var valid_618658 = query.getOrDefault("EngineVersion")
  valid_618658 = validateParameter(valid_618658, JString, required = false,
                                 default = nil)
  if valid_618658 != nil:
    section.add "EngineVersion", valid_618658
  var valid_618659 = query.getOrDefault("Port")
  valid_618659 = validateParameter(valid_618659, JInt, required = false, default = nil)
  if valid_618659 != nil:
    section.add "Port", valid_618659
  var valid_618660 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_618660 = validateParameter(valid_618660, JArray, required = false,
                                 default = nil)
  if valid_618660 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_618660
  var valid_618661 = query.getOrDefault("PreferredBackupWindow")
  valid_618661 = validateParameter(valid_618661, JString, required = false,
                                 default = nil)
  if valid_618661 != nil:
    section.add "PreferredBackupWindow", valid_618661
  var valid_618662 = query.getOrDefault("Version")
  valid_618662 = validateParameter(valid_618662, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618662 != nil:
    section.add "Version", valid_618662
  var valid_618663 = query.getOrDefault("ApplyImmediately")
  valid_618663 = validateParameter(valid_618663, JBool, required = false, default = nil)
  if valid_618663 != nil:
    section.add "ApplyImmediately", valid_618663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618664 = header.getOrDefault("X-Amz-Date")
  valid_618664 = validateParameter(valid_618664, JString, required = false,
                                 default = nil)
  if valid_618664 != nil:
    section.add "X-Amz-Date", valid_618664
  var valid_618665 = header.getOrDefault("X-Amz-Security-Token")
  valid_618665 = validateParameter(valid_618665, JString, required = false,
                                 default = nil)
  if valid_618665 != nil:
    section.add "X-Amz-Security-Token", valid_618665
  var valid_618666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618666 = validateParameter(valid_618666, JString, required = false,
                                 default = nil)
  if valid_618666 != nil:
    section.add "X-Amz-Content-Sha256", valid_618666
  var valid_618667 = header.getOrDefault("X-Amz-Algorithm")
  valid_618667 = validateParameter(valid_618667, JString, required = false,
                                 default = nil)
  if valid_618667 != nil:
    section.add "X-Amz-Algorithm", valid_618667
  var valid_618668 = header.getOrDefault("X-Amz-Signature")
  valid_618668 = validateParameter(valid_618668, JString, required = false,
                                 default = nil)
  if valid_618668 != nil:
    section.add "X-Amz-Signature", valid_618668
  var valid_618669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618669 = validateParameter(valid_618669, JString, required = false,
                                 default = nil)
  if valid_618669 != nil:
    section.add "X-Amz-SignedHeaders", valid_618669
  var valid_618670 = header.getOrDefault("X-Amz-Credential")
  valid_618670 = validateParameter(valid_618670, JString, required = false,
                                 default = nil)
  if valid_618670 != nil:
    section.add "X-Amz-Credential", valid_618670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618671: Call_GetModifyDBCluster_618645; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_618671.validator(path, query, header, formData, body, _)
  let scheme = call_618671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618671.url(scheme.get, call_618671.host, call_618671.base,
                         call_618671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618671, url, valid, _)

proc call*(call_618672: Call_GetModifyDBCluster_618645;
          DBClusterIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBClusterParameterGroupName: string = ""; MasterUserPassword: string = "";
          BackupRetentionPeriod: int = 0; VpcSecurityGroupIds: JsonNode = nil;
          CloudwatchLogsExportConfigurationDisableLogTypes: JsonNode = nil;
          NewDBClusterIdentifier: string = ""; DeletionProtection: bool = false;
          Action: string = "ModifyDBCluster"; EngineVersion: string = ""; Port: int = 0;
          CloudwatchLogsExportConfigurationEnableLogTypes: JsonNode = nil;
          PreferredBackupWindow: string = ""; Version: string = "2014-10-31";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBCluster
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: string (required)
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Port: int
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  var query_618673 = newJObject()
  add(query_618673, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_618673, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_618673, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_618673, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_618673, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if VpcSecurityGroupIds != nil:
    query_618673.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_618673.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_618673, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_618673, "DeletionProtection", newJBool(DeletionProtection))
  add(query_618673, "Action", newJString(Action))
  add(query_618673, "EngineVersion", newJString(EngineVersion))
  add(query_618673, "Port", newJInt(Port))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_618673.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  add(query_618673, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_618673, "Version", newJString(Version))
  add(query_618673, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_618672.call(nil, query_618673, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_618645(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_618646,
    base: "/", url: url_GetModifyDBCluster_618647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_618721 = ref object of OpenApiRestCall_616850
proc url_PostModifyDBClusterParameterGroup_618723(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBClusterParameterGroup_618722(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618724 = query.getOrDefault("Action")
  valid_618724 = validateParameter(valid_618724, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_618724 != nil:
    section.add "Action", valid_618724
  var valid_618725 = query.getOrDefault("Version")
  valid_618725 = validateParameter(valid_618725, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618725 != nil:
    section.add "Version", valid_618725
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618726 = header.getOrDefault("X-Amz-Date")
  valid_618726 = validateParameter(valid_618726, JString, required = false,
                                 default = nil)
  if valid_618726 != nil:
    section.add "X-Amz-Date", valid_618726
  var valid_618727 = header.getOrDefault("X-Amz-Security-Token")
  valid_618727 = validateParameter(valid_618727, JString, required = false,
                                 default = nil)
  if valid_618727 != nil:
    section.add "X-Amz-Security-Token", valid_618727
  var valid_618728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618728 = validateParameter(valid_618728, JString, required = false,
                                 default = nil)
  if valid_618728 != nil:
    section.add "X-Amz-Content-Sha256", valid_618728
  var valid_618729 = header.getOrDefault("X-Amz-Algorithm")
  valid_618729 = validateParameter(valid_618729, JString, required = false,
                                 default = nil)
  if valid_618729 != nil:
    section.add "X-Amz-Algorithm", valid_618729
  var valid_618730 = header.getOrDefault("X-Amz-Signature")
  valid_618730 = validateParameter(valid_618730, JString, required = false,
                                 default = nil)
  if valid_618730 != nil:
    section.add "X-Amz-Signature", valid_618730
  var valid_618731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618731 = validateParameter(valid_618731, JString, required = false,
                                 default = nil)
  if valid_618731 != nil:
    section.add "X-Amz-SignedHeaders", valid_618731
  var valid_618732 = header.getOrDefault("X-Amz-Credential")
  valid_618732 = validateParameter(valid_618732, JString, required = false,
                                 default = nil)
  if valid_618732 != nil:
    section.add "X-Amz-Credential", valid_618732
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_618733 = formData.getOrDefault("Parameters")
  valid_618733 = validateParameter(valid_618733, JArray, required = true, default = nil)
  if valid_618733 != nil:
    section.add "Parameters", valid_618733
  var valid_618734 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_618734 = validateParameter(valid_618734, JString, required = true,
                                 default = nil)
  if valid_618734 != nil:
    section.add "DBClusterParameterGroupName", valid_618734
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618735: Call_PostModifyDBClusterParameterGroup_618721;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_618735.validator(path, query, header, formData, body, _)
  let scheme = call_618735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618735.url(scheme.get, call_618735.host, call_618735.base,
                         call_618735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618735, url, valid, _)

proc call*(call_618736: Call_PostModifyDBClusterParameterGroup_618721;
          Parameters: JsonNode; DBClusterParameterGroupName: string;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the cluster parameter group to modify.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the cluster parameter group to modify.
  ##   Version: string (required)
  var query_618737 = newJObject()
  var formData_618738 = newJObject()
  if Parameters != nil:
    formData_618738.add "Parameters", Parameters
  add(query_618737, "Action", newJString(Action))
  add(formData_618738, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_618737, "Version", newJString(Version))
  result = call_618736.call(nil, query_618737, nil, formData_618738, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_618721(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_618722, base: "/",
    url: url_PostModifyDBClusterParameterGroup_618723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_618704 = ref object of OpenApiRestCall_616850
proc url_GetModifyDBClusterParameterGroup_618706(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBClusterParameterGroup_618705(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to modify.
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the cluster parameter group to modify.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_618707 = query.getOrDefault("DBClusterParameterGroupName")
  valid_618707 = validateParameter(valid_618707, JString, required = true,
                                 default = nil)
  if valid_618707 != nil:
    section.add "DBClusterParameterGroupName", valid_618707
  var valid_618708 = query.getOrDefault("Parameters")
  valid_618708 = validateParameter(valid_618708, JArray, required = true, default = nil)
  if valid_618708 != nil:
    section.add "Parameters", valid_618708
  var valid_618709 = query.getOrDefault("Action")
  valid_618709 = validateParameter(valid_618709, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_618709 != nil:
    section.add "Action", valid_618709
  var valid_618710 = query.getOrDefault("Version")
  valid_618710 = validateParameter(valid_618710, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618710 != nil:
    section.add "Version", valid_618710
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618711 = header.getOrDefault("X-Amz-Date")
  valid_618711 = validateParameter(valid_618711, JString, required = false,
                                 default = nil)
  if valid_618711 != nil:
    section.add "X-Amz-Date", valid_618711
  var valid_618712 = header.getOrDefault("X-Amz-Security-Token")
  valid_618712 = validateParameter(valid_618712, JString, required = false,
                                 default = nil)
  if valid_618712 != nil:
    section.add "X-Amz-Security-Token", valid_618712
  var valid_618713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618713 = validateParameter(valid_618713, JString, required = false,
                                 default = nil)
  if valid_618713 != nil:
    section.add "X-Amz-Content-Sha256", valid_618713
  var valid_618714 = header.getOrDefault("X-Amz-Algorithm")
  valid_618714 = validateParameter(valid_618714, JString, required = false,
                                 default = nil)
  if valid_618714 != nil:
    section.add "X-Amz-Algorithm", valid_618714
  var valid_618715 = header.getOrDefault("X-Amz-Signature")
  valid_618715 = validateParameter(valid_618715, JString, required = false,
                                 default = nil)
  if valid_618715 != nil:
    section.add "X-Amz-Signature", valid_618715
  var valid_618716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618716 = validateParameter(valid_618716, JString, required = false,
                                 default = nil)
  if valid_618716 != nil:
    section.add "X-Amz-SignedHeaders", valid_618716
  var valid_618717 = header.getOrDefault("X-Amz-Credential")
  valid_618717 = validateParameter(valid_618717, JString, required = false,
                                 default = nil)
  if valid_618717 != nil:
    section.add "X-Amz-Credential", valid_618717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618718: Call_GetModifyDBClusterParameterGroup_618704;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_618718.validator(path, query, header, formData, body, _)
  let scheme = call_618718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618718.url(scheme.get, call_618718.host, call_618718.base,
                         call_618718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618718, url, valid, _)

proc call*(call_618719: Call_GetModifyDBClusterParameterGroup_618704;
          DBClusterParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the cluster parameter group to modify.
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the cluster parameter group to modify.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_618720 = newJObject()
  add(query_618720, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_618720.add "Parameters", Parameters
  add(query_618720, "Action", newJString(Action))
  add(query_618720, "Version", newJString(Version))
  result = call_618719.call(nil, query_618720, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_618704(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_618705, base: "/",
    url: url_GetModifyDBClusterParameterGroup_618706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_618758 = ref object of OpenApiRestCall_616850
proc url_PostModifyDBClusterSnapshotAttribute_618760(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBClusterSnapshotAttribute_618759(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618761 = query.getOrDefault("Action")
  valid_618761 = validateParameter(valid_618761, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_618761 != nil:
    section.add "Action", valid_618761
  var valid_618762 = query.getOrDefault("Version")
  valid_618762 = validateParameter(valid_618762, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618762 != nil:
    section.add "Version", valid_618762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618763 = header.getOrDefault("X-Amz-Date")
  valid_618763 = validateParameter(valid_618763, JString, required = false,
                                 default = nil)
  if valid_618763 != nil:
    section.add "X-Amz-Date", valid_618763
  var valid_618764 = header.getOrDefault("X-Amz-Security-Token")
  valid_618764 = validateParameter(valid_618764, JString, required = false,
                                 default = nil)
  if valid_618764 != nil:
    section.add "X-Amz-Security-Token", valid_618764
  var valid_618765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618765 = validateParameter(valid_618765, JString, required = false,
                                 default = nil)
  if valid_618765 != nil:
    section.add "X-Amz-Content-Sha256", valid_618765
  var valid_618766 = header.getOrDefault("X-Amz-Algorithm")
  valid_618766 = validateParameter(valid_618766, JString, required = false,
                                 default = nil)
  if valid_618766 != nil:
    section.add "X-Amz-Algorithm", valid_618766
  var valid_618767 = header.getOrDefault("X-Amz-Signature")
  valid_618767 = validateParameter(valid_618767, JString, required = false,
                                 default = nil)
  if valid_618767 != nil:
    section.add "X-Amz-Signature", valid_618767
  var valid_618768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618768 = validateParameter(valid_618768, JString, required = false,
                                 default = nil)
  if valid_618768 != nil:
    section.add "X-Amz-SignedHeaders", valid_618768
  var valid_618769 = header.getOrDefault("X-Amz-Credential")
  valid_618769 = validateParameter(valid_618769, JString, required = false,
                                 default = nil)
  if valid_618769 != nil:
    section.add "X-Amz-Credential", valid_618769
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   AttributeName: JString (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_618770 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_618770 = validateParameter(valid_618770, JString, required = true,
                                 default = nil)
  if valid_618770 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_618770
  var valid_618771 = formData.getOrDefault("ValuesToRemove")
  valid_618771 = validateParameter(valid_618771, JArray, required = false,
                                 default = nil)
  if valid_618771 != nil:
    section.add "ValuesToRemove", valid_618771
  var valid_618772 = formData.getOrDefault("ValuesToAdd")
  valid_618772 = validateParameter(valid_618772, JArray, required = false,
                                 default = nil)
  if valid_618772 != nil:
    section.add "ValuesToAdd", valid_618772
  var valid_618773 = formData.getOrDefault("AttributeName")
  valid_618773 = validateParameter(valid_618773, JString, required = true,
                                 default = nil)
  if valid_618773 != nil:
    section.add "AttributeName", valid_618773
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618774: Call_PostModifyDBClusterSnapshotAttribute_618758;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_618774.validator(path, query, header, formData, body, _)
  let scheme = call_618774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618774.url(scheme.get, call_618774.host, call_618774.base,
                         call_618774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618774, url, valid, _)

proc call*(call_618775: Call_PostModifyDBClusterSnapshotAttribute_618758;
          DBClusterSnapshotIdentifier: string; AttributeName: string;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToRemove: JsonNode = nil; ValuesToAdd: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   Action: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Version: string (required)
  ##   AttributeName: string (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  var query_618776 = newJObject()
  var formData_618777 = newJObject()
  add(formData_618777, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_618776, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_618777.add "ValuesToRemove", ValuesToRemove
  if ValuesToAdd != nil:
    formData_618777.add "ValuesToAdd", ValuesToAdd
  add(query_618776, "Version", newJString(Version))
  add(formData_618777, "AttributeName", newJString(AttributeName))
  result = call_618775.call(nil, query_618776, nil, formData_618777, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_618758(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_618759, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_618760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_618739 = ref object of OpenApiRestCall_616850
proc url_GetModifyDBClusterSnapshotAttribute_618741(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBClusterSnapshotAttribute_618740(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeName: JString (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AttributeName` field"
  var valid_618742 = query.getOrDefault("AttributeName")
  valid_618742 = validateParameter(valid_618742, JString, required = true,
                                 default = nil)
  if valid_618742 != nil:
    section.add "AttributeName", valid_618742
  var valid_618743 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_618743 = validateParameter(valid_618743, JString, required = true,
                                 default = nil)
  if valid_618743 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_618743
  var valid_618744 = query.getOrDefault("ValuesToAdd")
  valid_618744 = validateParameter(valid_618744, JArray, required = false,
                                 default = nil)
  if valid_618744 != nil:
    section.add "ValuesToAdd", valid_618744
  var valid_618745 = query.getOrDefault("Action")
  valid_618745 = validateParameter(valid_618745, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_618745 != nil:
    section.add "Action", valid_618745
  var valid_618746 = query.getOrDefault("Version")
  valid_618746 = validateParameter(valid_618746, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618746 != nil:
    section.add "Version", valid_618746
  var valid_618747 = query.getOrDefault("ValuesToRemove")
  valid_618747 = validateParameter(valid_618747, JArray, required = false,
                                 default = nil)
  if valid_618747 != nil:
    section.add "ValuesToRemove", valid_618747
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618748 = header.getOrDefault("X-Amz-Date")
  valid_618748 = validateParameter(valid_618748, JString, required = false,
                                 default = nil)
  if valid_618748 != nil:
    section.add "X-Amz-Date", valid_618748
  var valid_618749 = header.getOrDefault("X-Amz-Security-Token")
  valid_618749 = validateParameter(valid_618749, JString, required = false,
                                 default = nil)
  if valid_618749 != nil:
    section.add "X-Amz-Security-Token", valid_618749
  var valid_618750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618750 = validateParameter(valid_618750, JString, required = false,
                                 default = nil)
  if valid_618750 != nil:
    section.add "X-Amz-Content-Sha256", valid_618750
  var valid_618751 = header.getOrDefault("X-Amz-Algorithm")
  valid_618751 = validateParameter(valid_618751, JString, required = false,
                                 default = nil)
  if valid_618751 != nil:
    section.add "X-Amz-Algorithm", valid_618751
  var valid_618752 = header.getOrDefault("X-Amz-Signature")
  valid_618752 = validateParameter(valid_618752, JString, required = false,
                                 default = nil)
  if valid_618752 != nil:
    section.add "X-Amz-Signature", valid_618752
  var valid_618753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618753 = validateParameter(valid_618753, JString, required = false,
                                 default = nil)
  if valid_618753 != nil:
    section.add "X-Amz-SignedHeaders", valid_618753
  var valid_618754 = header.getOrDefault("X-Amz-Credential")
  valid_618754 = validateParameter(valid_618754, JString, required = false,
                                 default = nil)
  if valid_618754 != nil:
    section.add "X-Amz-Credential", valid_618754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618755: Call_GetModifyDBClusterSnapshotAttribute_618739;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_618755.validator(path, query, header, formData, body, _)
  let scheme = call_618755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618755.url(scheme.get, call_618755.host, call_618755.base,
                         call_618755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618755, url, valid, _)

proc call*(call_618756: Call_GetModifyDBClusterSnapshotAttribute_618739;
          AttributeName: string; DBClusterSnapshotIdentifier: string;
          ValuesToAdd: JsonNode = nil;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          Version: string = "2014-10-31"; ValuesToRemove: JsonNode = nil): Recallable =
  ## getModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   AttributeName: string (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  var query_618757 = newJObject()
  add(query_618757, "AttributeName", newJString(AttributeName))
  add(query_618757, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if ValuesToAdd != nil:
    query_618757.add "ValuesToAdd", ValuesToAdd
  add(query_618757, "Action", newJString(Action))
  add(query_618757, "Version", newJString(Version))
  if ValuesToRemove != nil:
    query_618757.add "ValuesToRemove", ValuesToRemove
  result = call_618756.call(nil, query_618757, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_618739(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_618740, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_618741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_618801 = ref object of OpenApiRestCall_616850
proc url_PostModifyDBInstance_618803(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_618802(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618804 = query.getOrDefault("Action")
  valid_618804 = validateParameter(valid_618804, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_618804 != nil:
    section.add "Action", valid_618804
  var valid_618805 = query.getOrDefault("Version")
  valid_618805 = validateParameter(valid_618805, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618805 != nil:
    section.add "Version", valid_618805
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618806 = header.getOrDefault("X-Amz-Date")
  valid_618806 = validateParameter(valid_618806, JString, required = false,
                                 default = nil)
  if valid_618806 != nil:
    section.add "X-Amz-Date", valid_618806
  var valid_618807 = header.getOrDefault("X-Amz-Security-Token")
  valid_618807 = validateParameter(valid_618807, JString, required = false,
                                 default = nil)
  if valid_618807 != nil:
    section.add "X-Amz-Security-Token", valid_618807
  var valid_618808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618808 = validateParameter(valid_618808, JString, required = false,
                                 default = nil)
  if valid_618808 != nil:
    section.add "X-Amz-Content-Sha256", valid_618808
  var valid_618809 = header.getOrDefault("X-Amz-Algorithm")
  valid_618809 = validateParameter(valid_618809, JString, required = false,
                                 default = nil)
  if valid_618809 != nil:
    section.add "X-Amz-Algorithm", valid_618809
  var valid_618810 = header.getOrDefault("X-Amz-Signature")
  valid_618810 = validateParameter(valid_618810, JString, required = false,
                                 default = nil)
  if valid_618810 != nil:
    section.add "X-Amz-Signature", valid_618810
  var valid_618811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618811 = validateParameter(valid_618811, JString, required = false,
                                 default = nil)
  if valid_618811 != nil:
    section.add "X-Amz-SignedHeaders", valid_618811
  var valid_618812 = header.getOrDefault("X-Amz-Credential")
  valid_618812 = validateParameter(valid_618812, JString, required = false,
                                 default = nil)
  if valid_618812 != nil:
    section.add "X-Amz-Credential", valid_618812
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the instance. </p> <p> If this parameter is set to <code>false</code>, changes to the instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new instance identifier for the instance when renaming an instance. When you change the instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  section = newJObject()
  var valid_618813 = formData.getOrDefault("DBInstanceClass")
  valid_618813 = validateParameter(valid_618813, JString, required = false,
                                 default = nil)
  if valid_618813 != nil:
    section.add "DBInstanceClass", valid_618813
  var valid_618814 = formData.getOrDefault("ApplyImmediately")
  valid_618814 = validateParameter(valid_618814, JBool, required = false, default = nil)
  if valid_618814 != nil:
    section.add "ApplyImmediately", valid_618814
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_618815 = formData.getOrDefault("DBInstanceIdentifier")
  valid_618815 = validateParameter(valid_618815, JString, required = true,
                                 default = nil)
  if valid_618815 != nil:
    section.add "DBInstanceIdentifier", valid_618815
  var valid_618816 = formData.getOrDefault("CACertificateIdentifier")
  valid_618816 = validateParameter(valid_618816, JString, required = false,
                                 default = nil)
  if valid_618816 != nil:
    section.add "CACertificateIdentifier", valid_618816
  var valid_618817 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_618817 = validateParameter(valid_618817, JString, required = false,
                                 default = nil)
  if valid_618817 != nil:
    section.add "NewDBInstanceIdentifier", valid_618817
  var valid_618818 = formData.getOrDefault("PromotionTier")
  valid_618818 = validateParameter(valid_618818, JInt, required = false, default = nil)
  if valid_618818 != nil:
    section.add "PromotionTier", valid_618818
  var valid_618819 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_618819 = validateParameter(valid_618819, JBool, required = false, default = nil)
  if valid_618819 != nil:
    section.add "AutoMinorVersionUpgrade", valid_618819
  var valid_618820 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_618820 = validateParameter(valid_618820, JString, required = false,
                                 default = nil)
  if valid_618820 != nil:
    section.add "PreferredMaintenanceWindow", valid_618820
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618821: Call_PostModifyDBInstance_618801; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_618821.validator(path, query, header, formData, body, _)
  let scheme = call_618821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618821.url(scheme.get, call_618821.host, call_618821.base,
                         call_618821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618821, url, valid, _)

proc call*(call_618822: Call_PostModifyDBInstance_618801;
          DBInstanceIdentifier: string; DBInstanceClass: string = "";
          ApplyImmediately: bool = false; CACertificateIdentifier: string = "";
          NewDBInstanceIdentifier: string = ""; Action: string = "ModifyDBInstance";
          PromotionTier: int = 0; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postModifyDBInstance
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the instance. </p> <p> If this parameter is set to <code>false</code>, changes to the instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new instance identifier for the instance when renaming an instance. When you change the instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Action: string (required)
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  var query_618823 = newJObject()
  var formData_618824 = newJObject()
  add(formData_618824, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_618824, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_618824, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_618824, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(formData_618824, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_618823, "Action", newJString(Action))
  add(formData_618824, "PromotionTier", newJInt(PromotionTier))
  add(formData_618824, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_618823, "Version", newJString(Version))
  add(formData_618824, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_618822.call(nil, query_618823, nil, formData_618824, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_618801(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_618802, base: "/",
    url: url_PostModifyDBInstance_618803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_618778 = ref object of OpenApiRestCall_616850
proc url_GetModifyDBInstance_618780(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_618779(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   Action: JString (required)
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new instance identifier for the instance when renaming an instance. When you change the instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the instance. </p> <p> If this parameter is set to <code>false</code>, changes to the instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_618781 = query.getOrDefault("CACertificateIdentifier")
  valid_618781 = validateParameter(valid_618781, JString, required = false,
                                 default = nil)
  if valid_618781 != nil:
    section.add "CACertificateIdentifier", valid_618781
  var valid_618782 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_618782 = validateParameter(valid_618782, JString, required = false,
                                 default = nil)
  if valid_618782 != nil:
    section.add "PreferredMaintenanceWindow", valid_618782
  var valid_618783 = query.getOrDefault("PromotionTier")
  valid_618783 = validateParameter(valid_618783, JInt, required = false, default = nil)
  if valid_618783 != nil:
    section.add "PromotionTier", valid_618783
  var valid_618784 = query.getOrDefault("DBInstanceClass")
  valid_618784 = validateParameter(valid_618784, JString, required = false,
                                 default = nil)
  if valid_618784 != nil:
    section.add "DBInstanceClass", valid_618784
  var valid_618785 = query.getOrDefault("Action")
  valid_618785 = validateParameter(valid_618785, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_618785 != nil:
    section.add "Action", valid_618785
  var valid_618786 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_618786 = validateParameter(valid_618786, JString, required = false,
                                 default = nil)
  if valid_618786 != nil:
    section.add "NewDBInstanceIdentifier", valid_618786
  var valid_618787 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_618787 = validateParameter(valid_618787, JBool, required = false, default = nil)
  if valid_618787 != nil:
    section.add "AutoMinorVersionUpgrade", valid_618787
  var valid_618788 = query.getOrDefault("Version")
  valid_618788 = validateParameter(valid_618788, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618788 != nil:
    section.add "Version", valid_618788
  var valid_618789 = query.getOrDefault("DBInstanceIdentifier")
  valid_618789 = validateParameter(valid_618789, JString, required = true,
                                 default = nil)
  if valid_618789 != nil:
    section.add "DBInstanceIdentifier", valid_618789
  var valid_618790 = query.getOrDefault("ApplyImmediately")
  valid_618790 = validateParameter(valid_618790, JBool, required = false, default = nil)
  if valid_618790 != nil:
    section.add "ApplyImmediately", valid_618790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618791 = header.getOrDefault("X-Amz-Date")
  valid_618791 = validateParameter(valid_618791, JString, required = false,
                                 default = nil)
  if valid_618791 != nil:
    section.add "X-Amz-Date", valid_618791
  var valid_618792 = header.getOrDefault("X-Amz-Security-Token")
  valid_618792 = validateParameter(valid_618792, JString, required = false,
                                 default = nil)
  if valid_618792 != nil:
    section.add "X-Amz-Security-Token", valid_618792
  var valid_618793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618793 = validateParameter(valid_618793, JString, required = false,
                                 default = nil)
  if valid_618793 != nil:
    section.add "X-Amz-Content-Sha256", valid_618793
  var valid_618794 = header.getOrDefault("X-Amz-Algorithm")
  valid_618794 = validateParameter(valid_618794, JString, required = false,
                                 default = nil)
  if valid_618794 != nil:
    section.add "X-Amz-Algorithm", valid_618794
  var valid_618795 = header.getOrDefault("X-Amz-Signature")
  valid_618795 = validateParameter(valid_618795, JString, required = false,
                                 default = nil)
  if valid_618795 != nil:
    section.add "X-Amz-Signature", valid_618795
  var valid_618796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618796 = validateParameter(valid_618796, JString, required = false,
                                 default = nil)
  if valid_618796 != nil:
    section.add "X-Amz-SignedHeaders", valid_618796
  var valid_618797 = header.getOrDefault("X-Amz-Credential")
  valid_618797 = validateParameter(valid_618797, JString, required = false,
                                 default = nil)
  if valid_618797 != nil:
    section.add "X-Amz-Credential", valid_618797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618798: Call_GetModifyDBInstance_618778; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_618798.validator(path, query, header, formData, body, _)
  let scheme = call_618798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618798.url(scheme.get, call_618798.host, call_618798.base,
                         call_618798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618798, url, valid, _)

proc call*(call_618799: Call_GetModifyDBInstance_618778;
          DBInstanceIdentifier: string; CACertificateIdentifier: string = "";
          PreferredMaintenanceWindow: string = ""; PromotionTier: int = 0;
          DBInstanceClass: string = ""; Action: string = "ModifyDBInstance";
          NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBInstance
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   Action: string (required)
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new instance identifier for the instance when renaming an instance. When you change the instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the instance. </p> <p> If this parameter is set to <code>false</code>, changes to the instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  var query_618800 = newJObject()
  add(query_618800, "CACertificateIdentifier", newJString(CACertificateIdentifier))
  add(query_618800, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_618800, "PromotionTier", newJInt(PromotionTier))
  add(query_618800, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_618800, "Action", newJString(Action))
  add(query_618800, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_618800, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_618800, "Version", newJString(Version))
  add(query_618800, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_618800, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_618799.call(nil, query_618800, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_618778(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_618779, base: "/",
    url: url_GetModifyDBInstance_618780, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_618843 = ref object of OpenApiRestCall_616850
proc url_PostModifyDBSubnetGroup_618845(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_618844(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618846 = query.getOrDefault("Action")
  valid_618846 = validateParameter(valid_618846, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_618846 != nil:
    section.add "Action", valid_618846
  var valid_618847 = query.getOrDefault("Version")
  valid_618847 = validateParameter(valid_618847, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618847 != nil:
    section.add "Version", valid_618847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618848 = header.getOrDefault("X-Amz-Date")
  valid_618848 = validateParameter(valid_618848, JString, required = false,
                                 default = nil)
  if valid_618848 != nil:
    section.add "X-Amz-Date", valid_618848
  var valid_618849 = header.getOrDefault("X-Amz-Security-Token")
  valid_618849 = validateParameter(valid_618849, JString, required = false,
                                 default = nil)
  if valid_618849 != nil:
    section.add "X-Amz-Security-Token", valid_618849
  var valid_618850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618850 = validateParameter(valid_618850, JString, required = false,
                                 default = nil)
  if valid_618850 != nil:
    section.add "X-Amz-Content-Sha256", valid_618850
  var valid_618851 = header.getOrDefault("X-Amz-Algorithm")
  valid_618851 = validateParameter(valid_618851, JString, required = false,
                                 default = nil)
  if valid_618851 != nil:
    section.add "X-Amz-Algorithm", valid_618851
  var valid_618852 = header.getOrDefault("X-Amz-Signature")
  valid_618852 = validateParameter(valid_618852, JString, required = false,
                                 default = nil)
  if valid_618852 != nil:
    section.add "X-Amz-Signature", valid_618852
  var valid_618853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618853 = validateParameter(valid_618853, JString, required = false,
                                 default = nil)
  if valid_618853 != nil:
    section.add "X-Amz-SignedHeaders", valid_618853
  var valid_618854 = header.getOrDefault("X-Amz-Credential")
  valid_618854 = validateParameter(valid_618854, JString, required = false,
                                 default = nil)
  if valid_618854 != nil:
    section.add "X-Amz-Credential", valid_618854
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the subnet group.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `SubnetIds` field"
  var valid_618855 = formData.getOrDefault("SubnetIds")
  valid_618855 = validateParameter(valid_618855, JArray, required = true, default = nil)
  if valid_618855 != nil:
    section.add "SubnetIds", valid_618855
  var valid_618856 = formData.getOrDefault("DBSubnetGroupName")
  valid_618856 = validateParameter(valid_618856, JString, required = true,
                                 default = nil)
  if valid_618856 != nil:
    section.add "DBSubnetGroupName", valid_618856
  var valid_618857 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_618857 = validateParameter(valid_618857, JString, required = false,
                                 default = nil)
  if valid_618857 != nil:
    section.add "DBSubnetGroupDescription", valid_618857
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618858: Call_PostModifyDBSubnetGroup_618843; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_618858.validator(path, query, header, formData, body, _)
  let scheme = call_618858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618858.url(scheme.get, call_618858.host, call_618858.base,
                         call_618858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618858, url, valid, _)

proc call*(call_618859: Call_PostModifyDBSubnetGroup_618843; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          Version: string = "2014-10-31"; DBSubnetGroupDescription: string = ""): Recallable =
  ## postModifyDBSubnetGroup
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the subnet group.
  var query_618860 = newJObject()
  var formData_618861 = newJObject()
  if SubnetIds != nil:
    formData_618861.add "SubnetIds", SubnetIds
  add(formData_618861, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_618860, "Action", newJString(Action))
  add(query_618860, "Version", newJString(Version))
  add(formData_618861, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  result = call_618859.call(nil, query_618860, nil, formData_618861, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_618843(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_618844, base: "/",
    url: url_PostModifyDBSubnetGroup_618845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_618825 = ref object of OpenApiRestCall_616850
proc url_GetModifyDBSubnetGroup_618827(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_618826(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the subnet group.
  ##   Version: JString (required)
  section = newJObject()
  var valid_618828 = query.getOrDefault("Action")
  valid_618828 = validateParameter(valid_618828, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_618828 != nil:
    section.add "Action", valid_618828
  var valid_618829 = query.getOrDefault("DBSubnetGroupName")
  valid_618829 = validateParameter(valid_618829, JString, required = true,
                                 default = nil)
  if valid_618829 != nil:
    section.add "DBSubnetGroupName", valid_618829
  var valid_618830 = query.getOrDefault("SubnetIds")
  valid_618830 = validateParameter(valid_618830, JArray, required = true, default = nil)
  if valid_618830 != nil:
    section.add "SubnetIds", valid_618830
  var valid_618831 = query.getOrDefault("DBSubnetGroupDescription")
  valid_618831 = validateParameter(valid_618831, JString, required = false,
                                 default = nil)
  if valid_618831 != nil:
    section.add "DBSubnetGroupDescription", valid_618831
  var valid_618832 = query.getOrDefault("Version")
  valid_618832 = validateParameter(valid_618832, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618832 != nil:
    section.add "Version", valid_618832
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618833 = header.getOrDefault("X-Amz-Date")
  valid_618833 = validateParameter(valid_618833, JString, required = false,
                                 default = nil)
  if valid_618833 != nil:
    section.add "X-Amz-Date", valid_618833
  var valid_618834 = header.getOrDefault("X-Amz-Security-Token")
  valid_618834 = validateParameter(valid_618834, JString, required = false,
                                 default = nil)
  if valid_618834 != nil:
    section.add "X-Amz-Security-Token", valid_618834
  var valid_618835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618835 = validateParameter(valid_618835, JString, required = false,
                                 default = nil)
  if valid_618835 != nil:
    section.add "X-Amz-Content-Sha256", valid_618835
  var valid_618836 = header.getOrDefault("X-Amz-Algorithm")
  valid_618836 = validateParameter(valid_618836, JString, required = false,
                                 default = nil)
  if valid_618836 != nil:
    section.add "X-Amz-Algorithm", valid_618836
  var valid_618837 = header.getOrDefault("X-Amz-Signature")
  valid_618837 = validateParameter(valid_618837, JString, required = false,
                                 default = nil)
  if valid_618837 != nil:
    section.add "X-Amz-Signature", valid_618837
  var valid_618838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618838 = validateParameter(valid_618838, JString, required = false,
                                 default = nil)
  if valid_618838 != nil:
    section.add "X-Amz-SignedHeaders", valid_618838
  var valid_618839 = header.getOrDefault("X-Amz-Credential")
  valid_618839 = validateParameter(valid_618839, JString, required = false,
                                 default = nil)
  if valid_618839 != nil:
    section.add "X-Amz-Credential", valid_618839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618840: Call_GetModifyDBSubnetGroup_618825; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_618840.validator(path, query, header, formData, body, _)
  let scheme = call_618840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618840.url(scheme.get, call_618840.host, call_618840.base,
                         call_618840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618840, url, valid, _)

proc call*(call_618841: Call_GetModifyDBSubnetGroup_618825;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBSubnetGroup
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the subnet group.
  ##   Version: string (required)
  var query_618842 = newJObject()
  add(query_618842, "Action", newJString(Action))
  add(query_618842, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_618842.add "SubnetIds", SubnetIds
  add(query_618842, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_618842, "Version", newJString(Version))
  result = call_618841.call(nil, query_618842, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_618825(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_618826, base: "/",
    url: url_GetModifyDBSubnetGroup_618827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_618879 = ref object of OpenApiRestCall_616850
proc url_PostRebootDBInstance_618881(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_618880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618882 = query.getOrDefault("Action")
  valid_618882 = validateParameter(valid_618882, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_618882 != nil:
    section.add "Action", valid_618882
  var valid_618883 = query.getOrDefault("Version")
  valid_618883 = validateParameter(valid_618883, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618883 != nil:
    section.add "Version", valid_618883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618884 = header.getOrDefault("X-Amz-Date")
  valid_618884 = validateParameter(valid_618884, JString, required = false,
                                 default = nil)
  if valid_618884 != nil:
    section.add "X-Amz-Date", valid_618884
  var valid_618885 = header.getOrDefault("X-Amz-Security-Token")
  valid_618885 = validateParameter(valid_618885, JString, required = false,
                                 default = nil)
  if valid_618885 != nil:
    section.add "X-Amz-Security-Token", valid_618885
  var valid_618886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618886 = validateParameter(valid_618886, JString, required = false,
                                 default = nil)
  if valid_618886 != nil:
    section.add "X-Amz-Content-Sha256", valid_618886
  var valid_618887 = header.getOrDefault("X-Amz-Algorithm")
  valid_618887 = validateParameter(valid_618887, JString, required = false,
                                 default = nil)
  if valid_618887 != nil:
    section.add "X-Amz-Algorithm", valid_618887
  var valid_618888 = header.getOrDefault("X-Amz-Signature")
  valid_618888 = validateParameter(valid_618888, JString, required = false,
                                 default = nil)
  if valid_618888 != nil:
    section.add "X-Amz-Signature", valid_618888
  var valid_618889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618889 = validateParameter(valid_618889, JString, required = false,
                                 default = nil)
  if valid_618889 != nil:
    section.add "X-Amz-SignedHeaders", valid_618889
  var valid_618890 = header.getOrDefault("X-Amz-Credential")
  valid_618890 = validateParameter(valid_618890, JString, required = false,
                                 default = nil)
  if valid_618890 != nil:
    section.add "X-Amz-Credential", valid_618890
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_618891 = formData.getOrDefault("DBInstanceIdentifier")
  valid_618891 = validateParameter(valid_618891, JString, required = true,
                                 default = nil)
  if valid_618891 != nil:
    section.add "DBInstanceIdentifier", valid_618891
  var valid_618892 = formData.getOrDefault("ForceFailover")
  valid_618892 = validateParameter(valid_618892, JBool, required = false, default = nil)
  if valid_618892 != nil:
    section.add "ForceFailover", valid_618892
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618893: Call_PostRebootDBInstance_618879; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_618893.validator(path, query, header, formData, body, _)
  let scheme = call_618893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618893.url(scheme.get, call_618893.host, call_618893.base,
                         call_618893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618893, url, valid, _)

proc call*(call_618894: Call_PostRebootDBInstance_618879;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-10-31"): Recallable =
  ## postRebootDBInstance
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   Version: string (required)
  var query_618895 = newJObject()
  var formData_618896 = newJObject()
  add(formData_618896, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_618895, "Action", newJString(Action))
  add(formData_618896, "ForceFailover", newJBool(ForceFailover))
  add(query_618895, "Version", newJString(Version))
  result = call_618894.call(nil, query_618895, nil, formData_618896, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_618879(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_618880, base: "/",
    url: url_PostRebootDBInstance_618881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_618862 = ref object of OpenApiRestCall_616850
proc url_GetRebootDBInstance_618864(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_618863(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  var valid_618865 = query.getOrDefault("Action")
  valid_618865 = validateParameter(valid_618865, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_618865 != nil:
    section.add "Action", valid_618865
  var valid_618866 = query.getOrDefault("ForceFailover")
  valid_618866 = validateParameter(valid_618866, JBool, required = false, default = nil)
  if valid_618866 != nil:
    section.add "ForceFailover", valid_618866
  var valid_618867 = query.getOrDefault("Version")
  valid_618867 = validateParameter(valid_618867, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618867 != nil:
    section.add "Version", valid_618867
  var valid_618868 = query.getOrDefault("DBInstanceIdentifier")
  valid_618868 = validateParameter(valid_618868, JString, required = true,
                                 default = nil)
  if valid_618868 != nil:
    section.add "DBInstanceIdentifier", valid_618868
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618869 = header.getOrDefault("X-Amz-Date")
  valid_618869 = validateParameter(valid_618869, JString, required = false,
                                 default = nil)
  if valid_618869 != nil:
    section.add "X-Amz-Date", valid_618869
  var valid_618870 = header.getOrDefault("X-Amz-Security-Token")
  valid_618870 = validateParameter(valid_618870, JString, required = false,
                                 default = nil)
  if valid_618870 != nil:
    section.add "X-Amz-Security-Token", valid_618870
  var valid_618871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618871 = validateParameter(valid_618871, JString, required = false,
                                 default = nil)
  if valid_618871 != nil:
    section.add "X-Amz-Content-Sha256", valid_618871
  var valid_618872 = header.getOrDefault("X-Amz-Algorithm")
  valid_618872 = validateParameter(valid_618872, JString, required = false,
                                 default = nil)
  if valid_618872 != nil:
    section.add "X-Amz-Algorithm", valid_618872
  var valid_618873 = header.getOrDefault("X-Amz-Signature")
  valid_618873 = validateParameter(valid_618873, JString, required = false,
                                 default = nil)
  if valid_618873 != nil:
    section.add "X-Amz-Signature", valid_618873
  var valid_618874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618874 = validateParameter(valid_618874, JString, required = false,
                                 default = nil)
  if valid_618874 != nil:
    section.add "X-Amz-SignedHeaders", valid_618874
  var valid_618875 = header.getOrDefault("X-Amz-Credential")
  valid_618875 = validateParameter(valid_618875, JString, required = false,
                                 default = nil)
  if valid_618875 != nil:
    section.add "X-Amz-Credential", valid_618875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618876: Call_GetRebootDBInstance_618862; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_618876.validator(path, query, header, formData, body, _)
  let scheme = call_618876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618876.url(scheme.get, call_618876.host, call_618876.base,
                         call_618876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618876, url, valid, _)

proc call*(call_618877: Call_GetRebootDBInstance_618862;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getRebootDBInstance
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  var query_618878 = newJObject()
  add(query_618878, "Action", newJString(Action))
  add(query_618878, "ForceFailover", newJBool(ForceFailover))
  add(query_618878, "Version", newJString(Version))
  add(query_618878, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_618877.call(nil, query_618878, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_618862(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_618863, base: "/",
    url: url_GetRebootDBInstance_618864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_618914 = ref object of OpenApiRestCall_616850
proc url_PostRemoveTagsFromResource_618916(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_618915(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_618917 = query.getOrDefault("Action")
  valid_618917 = validateParameter(valid_618917, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_618917 != nil:
    section.add "Action", valid_618917
  var valid_618918 = query.getOrDefault("Version")
  valid_618918 = validateParameter(valid_618918, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618918 != nil:
    section.add "Version", valid_618918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618919 = header.getOrDefault("X-Amz-Date")
  valid_618919 = validateParameter(valid_618919, JString, required = false,
                                 default = nil)
  if valid_618919 != nil:
    section.add "X-Amz-Date", valid_618919
  var valid_618920 = header.getOrDefault("X-Amz-Security-Token")
  valid_618920 = validateParameter(valid_618920, JString, required = false,
                                 default = nil)
  if valid_618920 != nil:
    section.add "X-Amz-Security-Token", valid_618920
  var valid_618921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618921 = validateParameter(valid_618921, JString, required = false,
                                 default = nil)
  if valid_618921 != nil:
    section.add "X-Amz-Content-Sha256", valid_618921
  var valid_618922 = header.getOrDefault("X-Amz-Algorithm")
  valid_618922 = validateParameter(valid_618922, JString, required = false,
                                 default = nil)
  if valid_618922 != nil:
    section.add "X-Amz-Algorithm", valid_618922
  var valid_618923 = header.getOrDefault("X-Amz-Signature")
  valid_618923 = validateParameter(valid_618923, JString, required = false,
                                 default = nil)
  if valid_618923 != nil:
    section.add "X-Amz-Signature", valid_618923
  var valid_618924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618924 = validateParameter(valid_618924, JString, required = false,
                                 default = nil)
  if valid_618924 != nil:
    section.add "X-Amz-SignedHeaders", valid_618924
  var valid_618925 = header.getOrDefault("X-Amz-Credential")
  valid_618925 = validateParameter(valid_618925, JString, required = false,
                                 default = nil)
  if valid_618925 != nil:
    section.add "X-Amz-Credential", valid_618925
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_618926 = formData.getOrDefault("TagKeys")
  valid_618926 = validateParameter(valid_618926, JArray, required = true, default = nil)
  if valid_618926 != nil:
    section.add "TagKeys", valid_618926
  var valid_618927 = formData.getOrDefault("ResourceName")
  valid_618927 = validateParameter(valid_618927, JString, required = true,
                                 default = nil)
  if valid_618927 != nil:
    section.add "ResourceName", valid_618927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618928: Call_PostRemoveTagsFromResource_618914;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_618928.validator(path, query, header, formData, body, _)
  let scheme = call_618928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618928.url(scheme.get, call_618928.host, call_618928.base,
                         call_618928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618928, url, valid, _)

proc call*(call_618929: Call_PostRemoveTagsFromResource_618914; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-10-31"): Recallable =
  ## postRemoveTagsFromResource
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_618930 = newJObject()
  var formData_618931 = newJObject()
  add(query_618930, "Action", newJString(Action))
  if TagKeys != nil:
    formData_618931.add "TagKeys", TagKeys
  add(formData_618931, "ResourceName", newJString(ResourceName))
  add(query_618930, "Version", newJString(Version))
  result = call_618929.call(nil, query_618930, nil, formData_618931, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_618914(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_618915, base: "/",
    url: url_PostRemoveTagsFromResource_618916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_618897 = ref object of OpenApiRestCall_616850
proc url_GetRemoveTagsFromResource_618899(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_618898(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_618900 = query.getOrDefault("Action")
  valid_618900 = validateParameter(valid_618900, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_618900 != nil:
    section.add "Action", valid_618900
  var valid_618901 = query.getOrDefault("ResourceName")
  valid_618901 = validateParameter(valid_618901, JString, required = true,
                                 default = nil)
  if valid_618901 != nil:
    section.add "ResourceName", valid_618901
  var valid_618902 = query.getOrDefault("TagKeys")
  valid_618902 = validateParameter(valid_618902, JArray, required = true, default = nil)
  if valid_618902 != nil:
    section.add "TagKeys", valid_618902
  var valid_618903 = query.getOrDefault("Version")
  valid_618903 = validateParameter(valid_618903, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618903 != nil:
    section.add "Version", valid_618903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618904 = header.getOrDefault("X-Amz-Date")
  valid_618904 = validateParameter(valid_618904, JString, required = false,
                                 default = nil)
  if valid_618904 != nil:
    section.add "X-Amz-Date", valid_618904
  var valid_618905 = header.getOrDefault("X-Amz-Security-Token")
  valid_618905 = validateParameter(valid_618905, JString, required = false,
                                 default = nil)
  if valid_618905 != nil:
    section.add "X-Amz-Security-Token", valid_618905
  var valid_618906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618906 = validateParameter(valid_618906, JString, required = false,
                                 default = nil)
  if valid_618906 != nil:
    section.add "X-Amz-Content-Sha256", valid_618906
  var valid_618907 = header.getOrDefault("X-Amz-Algorithm")
  valid_618907 = validateParameter(valid_618907, JString, required = false,
                                 default = nil)
  if valid_618907 != nil:
    section.add "X-Amz-Algorithm", valid_618907
  var valid_618908 = header.getOrDefault("X-Amz-Signature")
  valid_618908 = validateParameter(valid_618908, JString, required = false,
                                 default = nil)
  if valid_618908 != nil:
    section.add "X-Amz-Signature", valid_618908
  var valid_618909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618909 = validateParameter(valid_618909, JString, required = false,
                                 default = nil)
  if valid_618909 != nil:
    section.add "X-Amz-SignedHeaders", valid_618909
  var valid_618910 = header.getOrDefault("X-Amz-Credential")
  valid_618910 = validateParameter(valid_618910, JString, required = false,
                                 default = nil)
  if valid_618910 != nil:
    section.add "X-Amz-Credential", valid_618910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618911: Call_GetRemoveTagsFromResource_618897;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_618911.validator(path, query, header, formData, body, _)
  let scheme = call_618911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618911.url(scheme.get, call_618911.host, call_618911.base,
                         call_618911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618911, url, valid, _)

proc call*(call_618912: Call_GetRemoveTagsFromResource_618897;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-10-31"): Recallable =
  ## getRemoveTagsFromResource
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   Version: string (required)
  var query_618913 = newJObject()
  add(query_618913, "Action", newJString(Action))
  add(query_618913, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_618913.add "TagKeys", TagKeys
  add(query_618913, "Version", newJString(Version))
  result = call_618912.call(nil, query_618913, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_618897(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_618898, base: "/",
    url: url_GetRemoveTagsFromResource_618899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_618950 = ref object of OpenApiRestCall_616850
proc url_PostResetDBClusterParameterGroup_618952(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBClusterParameterGroup_618951(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618953 = query.getOrDefault("Action")
  valid_618953 = validateParameter(valid_618953, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_618953 != nil:
    section.add "Action", valid_618953
  var valid_618954 = query.getOrDefault("Version")
  valid_618954 = validateParameter(valid_618954, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618954 != nil:
    section.add "Version", valid_618954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618955 = header.getOrDefault("X-Amz-Date")
  valid_618955 = validateParameter(valid_618955, JString, required = false,
                                 default = nil)
  if valid_618955 != nil:
    section.add "X-Amz-Date", valid_618955
  var valid_618956 = header.getOrDefault("X-Amz-Security-Token")
  valid_618956 = validateParameter(valid_618956, JString, required = false,
                                 default = nil)
  if valid_618956 != nil:
    section.add "X-Amz-Security-Token", valid_618956
  var valid_618957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618957 = validateParameter(valid_618957, JString, required = false,
                                 default = nil)
  if valid_618957 != nil:
    section.add "X-Amz-Content-Sha256", valid_618957
  var valid_618958 = header.getOrDefault("X-Amz-Algorithm")
  valid_618958 = validateParameter(valid_618958, JString, required = false,
                                 default = nil)
  if valid_618958 != nil:
    section.add "X-Amz-Algorithm", valid_618958
  var valid_618959 = header.getOrDefault("X-Amz-Signature")
  valid_618959 = validateParameter(valid_618959, JString, required = false,
                                 default = nil)
  if valid_618959 != nil:
    section.add "X-Amz-Signature", valid_618959
  var valid_618960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618960 = validateParameter(valid_618960, JString, required = false,
                                 default = nil)
  if valid_618960 != nil:
    section.add "X-Amz-SignedHeaders", valid_618960
  var valid_618961 = header.getOrDefault("X-Amz-Credential")
  valid_618961 = validateParameter(valid_618961, JString, required = false,
                                 default = nil)
  if valid_618961 != nil:
    section.add "X-Amz-Credential", valid_618961
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  section = newJObject()
  var valid_618962 = formData.getOrDefault("Parameters")
  valid_618962 = validateParameter(valid_618962, JArray, required = false,
                                 default = nil)
  if valid_618962 != nil:
    section.add "Parameters", valid_618962
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_618963 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_618963 = validateParameter(valid_618963, JString, required = true,
                                 default = nil)
  if valid_618963 != nil:
    section.add "DBClusterParameterGroupName", valid_618963
  var valid_618964 = formData.getOrDefault("ResetAllParameters")
  valid_618964 = validateParameter(valid_618964, JBool, required = false, default = nil)
  if valid_618964 != nil:
    section.add "ResetAllParameters", valid_618964
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618965: Call_PostResetDBClusterParameterGroup_618950;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_618965.validator(path, query, header, formData, body, _)
  let scheme = call_618965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618965.url(scheme.get, call_618965.host, call_618965.base,
                         call_618965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618965, url, valid, _)

proc call*(call_618966: Call_PostResetDBClusterParameterGroup_618950;
          DBClusterParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBClusterParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-10-31"): Recallable =
  ## postResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   Parameters: JArray
  ##             : A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the cluster parameter group to reset.
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Version: string (required)
  var query_618967 = newJObject()
  var formData_618968 = newJObject()
  if Parameters != nil:
    formData_618968.add "Parameters", Parameters
  add(query_618967, "Action", newJString(Action))
  add(formData_618968, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_618968, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_618967, "Version", newJString(Version))
  result = call_618966.call(nil, query_618967, nil, formData_618968, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_618950(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_618951, base: "/",
    url: url_PostResetDBClusterParameterGroup_618952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_618932 = ref object of OpenApiRestCall_616850
proc url_GetResetDBClusterParameterGroup_618934(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBClusterParameterGroup_618933(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to reset.
  ##   Parameters: JArray
  ##             : A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   Action: JString (required)
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_618935 = query.getOrDefault("DBClusterParameterGroupName")
  valid_618935 = validateParameter(valid_618935, JString, required = true,
                                 default = nil)
  if valid_618935 != nil:
    section.add "DBClusterParameterGroupName", valid_618935
  var valid_618936 = query.getOrDefault("Parameters")
  valid_618936 = validateParameter(valid_618936, JArray, required = false,
                                 default = nil)
  if valid_618936 != nil:
    section.add "Parameters", valid_618936
  var valid_618937 = query.getOrDefault("Action")
  valid_618937 = validateParameter(valid_618937, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_618937 != nil:
    section.add "Action", valid_618937
  var valid_618938 = query.getOrDefault("ResetAllParameters")
  valid_618938 = validateParameter(valid_618938, JBool, required = false, default = nil)
  if valid_618938 != nil:
    section.add "ResetAllParameters", valid_618938
  var valid_618939 = query.getOrDefault("Version")
  valid_618939 = validateParameter(valid_618939, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618939 != nil:
    section.add "Version", valid_618939
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618940 = header.getOrDefault("X-Amz-Date")
  valid_618940 = validateParameter(valid_618940, JString, required = false,
                                 default = nil)
  if valid_618940 != nil:
    section.add "X-Amz-Date", valid_618940
  var valid_618941 = header.getOrDefault("X-Amz-Security-Token")
  valid_618941 = validateParameter(valid_618941, JString, required = false,
                                 default = nil)
  if valid_618941 != nil:
    section.add "X-Amz-Security-Token", valid_618941
  var valid_618942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618942 = validateParameter(valid_618942, JString, required = false,
                                 default = nil)
  if valid_618942 != nil:
    section.add "X-Amz-Content-Sha256", valid_618942
  var valid_618943 = header.getOrDefault("X-Amz-Algorithm")
  valid_618943 = validateParameter(valid_618943, JString, required = false,
                                 default = nil)
  if valid_618943 != nil:
    section.add "X-Amz-Algorithm", valid_618943
  var valid_618944 = header.getOrDefault("X-Amz-Signature")
  valid_618944 = validateParameter(valid_618944, JString, required = false,
                                 default = nil)
  if valid_618944 != nil:
    section.add "X-Amz-Signature", valid_618944
  var valid_618945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618945 = validateParameter(valid_618945, JString, required = false,
                                 default = nil)
  if valid_618945 != nil:
    section.add "X-Amz-SignedHeaders", valid_618945
  var valid_618946 = header.getOrDefault("X-Amz-Credential")
  valid_618946 = validateParameter(valid_618946, JString, required = false,
                                 default = nil)
  if valid_618946 != nil:
    section.add "X-Amz-Credential", valid_618946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618947: Call_GetResetDBClusterParameterGroup_618932;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_618947.validator(path, query, header, formData, body, _)
  let scheme = call_618947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618947.url(scheme.get, call_618947.host, call_618947.base,
                         call_618947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618947, url, valid, _)

proc call*(call_618948: Call_GetResetDBClusterParameterGroup_618932;
          DBClusterParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBClusterParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the cluster parameter group to reset.
  ##   Parameters: JArray
  ##             : A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Version: string (required)
  var query_618949 = newJObject()
  add(query_618949, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_618949.add "Parameters", Parameters
  add(query_618949, "Action", newJString(Action))
  add(query_618949, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_618949, "Version", newJString(Version))
  result = call_618948.call(nil, query_618949, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_618932(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_618933, base: "/",
    url: url_GetResetDBClusterParameterGroup_618934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_618996 = ref object of OpenApiRestCall_616850
proc url_PostRestoreDBClusterFromSnapshot_618998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBClusterFromSnapshot_618997(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_618999 = query.getOrDefault("Action")
  valid_618999 = validateParameter(valid_618999, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_618999 != nil:
    section.add "Action", valid_618999
  var valid_619000 = query.getOrDefault("Version")
  valid_619000 = validateParameter(valid_619000, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_619000 != nil:
    section.add "Version", valid_619000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_619001 = header.getOrDefault("X-Amz-Date")
  valid_619001 = validateParameter(valid_619001, JString, required = false,
                                 default = nil)
  if valid_619001 != nil:
    section.add "X-Amz-Date", valid_619001
  var valid_619002 = header.getOrDefault("X-Amz-Security-Token")
  valid_619002 = validateParameter(valid_619002, JString, required = false,
                                 default = nil)
  if valid_619002 != nil:
    section.add "X-Amz-Security-Token", valid_619002
  var valid_619003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619003 = validateParameter(valid_619003, JString, required = false,
                                 default = nil)
  if valid_619003 != nil:
    section.add "X-Amz-Content-Sha256", valid_619003
  var valid_619004 = header.getOrDefault("X-Amz-Algorithm")
  valid_619004 = validateParameter(valid_619004, JString, required = false,
                                 default = nil)
  if valid_619004 != nil:
    section.add "X-Amz-Algorithm", valid_619004
  var valid_619005 = header.getOrDefault("X-Amz-Signature")
  valid_619005 = validateParameter(valid_619005, JString, required = false,
                                 default = nil)
  if valid_619005 != nil:
    section.add "X-Amz-Signature", valid_619005
  var valid_619006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619006 = validateParameter(valid_619006, JString, required = false,
                                 default = nil)
  if valid_619006 != nil:
    section.add "X-Amz-SignedHeaders", valid_619006
  var valid_619007 = header.getOrDefault("X-Amz-Credential")
  valid_619007 = validateParameter(valid_619007, JString, required = false,
                                 default = nil)
  if valid_619007 != nil:
    section.add "X-Amz-Credential", valid_619007
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new cluster will belong to.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the cluster to create from the snapshot or cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new cluster.
  section = newJObject()
  var valid_619008 = formData.getOrDefault("Port")
  valid_619008 = validateParameter(valid_619008, JInt, required = false, default = nil)
  if valid_619008 != nil:
    section.add "Port", valid_619008
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_619009 = formData.getOrDefault("Engine")
  valid_619009 = validateParameter(valid_619009, JString, required = true,
                                 default = nil)
  if valid_619009 != nil:
    section.add "Engine", valid_619009
  var valid_619010 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_619010 = validateParameter(valid_619010, JArray, required = false,
                                 default = nil)
  if valid_619010 != nil:
    section.add "VpcSecurityGroupIds", valid_619010
  var valid_619011 = formData.getOrDefault("Tags")
  valid_619011 = validateParameter(valid_619011, JArray, required = false,
                                 default = nil)
  if valid_619011 != nil:
    section.add "Tags", valid_619011
  var valid_619012 = formData.getOrDefault("DeletionProtection")
  valid_619012 = validateParameter(valid_619012, JBool, required = false, default = nil)
  if valid_619012 != nil:
    section.add "DeletionProtection", valid_619012
  var valid_619013 = formData.getOrDefault("DBSubnetGroupName")
  valid_619013 = validateParameter(valid_619013, JString, required = false,
                                 default = nil)
  if valid_619013 != nil:
    section.add "DBSubnetGroupName", valid_619013
  var valid_619014 = formData.getOrDefault("AvailabilityZones")
  valid_619014 = validateParameter(valid_619014, JArray, required = false,
                                 default = nil)
  if valid_619014 != nil:
    section.add "AvailabilityZones", valid_619014
  var valid_619015 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_619015 = validateParameter(valid_619015, JArray, required = false,
                                 default = nil)
  if valid_619015 != nil:
    section.add "EnableCloudwatchLogsExports", valid_619015
  var valid_619016 = formData.getOrDefault("KmsKeyId")
  valid_619016 = validateParameter(valid_619016, JString, required = false,
                                 default = nil)
  if valid_619016 != nil:
    section.add "KmsKeyId", valid_619016
  var valid_619017 = formData.getOrDefault("SnapshotIdentifier")
  valid_619017 = validateParameter(valid_619017, JString, required = true,
                                 default = nil)
  if valid_619017 != nil:
    section.add "SnapshotIdentifier", valid_619017
  var valid_619018 = formData.getOrDefault("DBClusterIdentifier")
  valid_619018 = validateParameter(valid_619018, JString, required = true,
                                 default = nil)
  if valid_619018 != nil:
    section.add "DBClusterIdentifier", valid_619018
  var valid_619019 = formData.getOrDefault("EngineVersion")
  valid_619019 = validateParameter(valid_619019, JString, required = false,
                                 default = nil)
  if valid_619019 != nil:
    section.add "EngineVersion", valid_619019
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_619020: Call_PostRestoreDBClusterFromSnapshot_618996;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  let valid = call_619020.validator(path, query, header, formData, body, _)
  let scheme = call_619020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619020.url(scheme.get, call_619020.host, call_619020.base,
                         call_619020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619020, url, valid, _)

proc call*(call_619021: Call_PostRestoreDBClusterFromSnapshot_618996;
          Engine: string; SnapshotIdentifier: string; DBClusterIdentifier: string;
          Port: int = 0; VpcSecurityGroupIds: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false; DBSubnetGroupName: string = "";
          Action: string = "RestoreDBClusterFromSnapshot";
          AvailabilityZones: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; KmsKeyId: string = "";
          EngineVersion: string = ""; Version: string = "2014-10-31"): Recallable =
  ## postRestoreDBClusterFromSnapshot
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new cluster will belong to.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the cluster to create from the snapshot or cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new cluster.
  ##   Version: string (required)
  var query_619022 = newJObject()
  var formData_619023 = newJObject()
  add(formData_619023, "Port", newJInt(Port))
  add(formData_619023, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_619023.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if Tags != nil:
    formData_619023.add "Tags", Tags
  add(formData_619023, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_619023, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_619022, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_619023.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    formData_619023.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_619023, "KmsKeyId", newJString(KmsKeyId))
  add(formData_619023, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(formData_619023, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_619023, "EngineVersion", newJString(EngineVersion))
  add(query_619022, "Version", newJString(Version))
  result = call_619021.call(nil, query_619022, nil, formData_619023, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_618996(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_618997, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_618998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_618969 = ref object of OpenApiRestCall_616850
proc url_GetRestoreDBClusterFromSnapshot_618971(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBClusterFromSnapshot_618970(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the cluster to create from the snapshot or cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new cluster will belong to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   Action: JString (required)
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new cluster.
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_618972 = query.getOrDefault("AvailabilityZones")
  valid_618972 = validateParameter(valid_618972, JArray, required = false,
                                 default = nil)
  if valid_618972 != nil:
    section.add "AvailabilityZones", valid_618972
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_618973 = query.getOrDefault("DBClusterIdentifier")
  valid_618973 = validateParameter(valid_618973, JString, required = true,
                                 default = nil)
  if valid_618973 != nil:
    section.add "DBClusterIdentifier", valid_618973
  var valid_618974 = query.getOrDefault("VpcSecurityGroupIds")
  valid_618974 = validateParameter(valid_618974, JArray, required = false,
                                 default = nil)
  if valid_618974 != nil:
    section.add "VpcSecurityGroupIds", valid_618974
  var valid_618975 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_618975 = validateParameter(valid_618975, JArray, required = false,
                                 default = nil)
  if valid_618975 != nil:
    section.add "EnableCloudwatchLogsExports", valid_618975
  var valid_618976 = query.getOrDefault("Tags")
  valid_618976 = validateParameter(valid_618976, JArray, required = false,
                                 default = nil)
  if valid_618976 != nil:
    section.add "Tags", valid_618976
  var valid_618977 = query.getOrDefault("DeletionProtection")
  valid_618977 = validateParameter(valid_618977, JBool, required = false, default = nil)
  if valid_618977 != nil:
    section.add "DeletionProtection", valid_618977
  var valid_618978 = query.getOrDefault("DBSubnetGroupName")
  valid_618978 = validateParameter(valid_618978, JString, required = false,
                                 default = nil)
  if valid_618978 != nil:
    section.add "DBSubnetGroupName", valid_618978
  var valid_618979 = query.getOrDefault("KmsKeyId")
  valid_618979 = validateParameter(valid_618979, JString, required = false,
                                 default = nil)
  if valid_618979 != nil:
    section.add "KmsKeyId", valid_618979
  var valid_618980 = query.getOrDefault("Action")
  valid_618980 = validateParameter(valid_618980, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_618980 != nil:
    section.add "Action", valid_618980
  var valid_618981 = query.getOrDefault("EngineVersion")
  valid_618981 = validateParameter(valid_618981, JString, required = false,
                                 default = nil)
  if valid_618981 != nil:
    section.add "EngineVersion", valid_618981
  var valid_618982 = query.getOrDefault("Port")
  valid_618982 = validateParameter(valid_618982, JInt, required = false, default = nil)
  if valid_618982 != nil:
    section.add "Port", valid_618982
  var valid_618983 = query.getOrDefault("SnapshotIdentifier")
  valid_618983 = validateParameter(valid_618983, JString, required = true,
                                 default = nil)
  if valid_618983 != nil:
    section.add "SnapshotIdentifier", valid_618983
  var valid_618984 = query.getOrDefault("Engine")
  valid_618984 = validateParameter(valid_618984, JString, required = true,
                                 default = nil)
  if valid_618984 != nil:
    section.add "Engine", valid_618984
  var valid_618985 = query.getOrDefault("Version")
  valid_618985 = validateParameter(valid_618985, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_618985 != nil:
    section.add "Version", valid_618985
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_618986 = header.getOrDefault("X-Amz-Date")
  valid_618986 = validateParameter(valid_618986, JString, required = false,
                                 default = nil)
  if valid_618986 != nil:
    section.add "X-Amz-Date", valid_618986
  var valid_618987 = header.getOrDefault("X-Amz-Security-Token")
  valid_618987 = validateParameter(valid_618987, JString, required = false,
                                 default = nil)
  if valid_618987 != nil:
    section.add "X-Amz-Security-Token", valid_618987
  var valid_618988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_618988 = validateParameter(valid_618988, JString, required = false,
                                 default = nil)
  if valid_618988 != nil:
    section.add "X-Amz-Content-Sha256", valid_618988
  var valid_618989 = header.getOrDefault("X-Amz-Algorithm")
  valid_618989 = validateParameter(valid_618989, JString, required = false,
                                 default = nil)
  if valid_618989 != nil:
    section.add "X-Amz-Algorithm", valid_618989
  var valid_618990 = header.getOrDefault("X-Amz-Signature")
  valid_618990 = validateParameter(valid_618990, JString, required = false,
                                 default = nil)
  if valid_618990 != nil:
    section.add "X-Amz-Signature", valid_618990
  var valid_618991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_618991 = validateParameter(valid_618991, JString, required = false,
                                 default = nil)
  if valid_618991 != nil:
    section.add "X-Amz-SignedHeaders", valid_618991
  var valid_618992 = header.getOrDefault("X-Amz-Credential")
  valid_618992 = validateParameter(valid_618992, JString, required = false,
                                 default = nil)
  if valid_618992 != nil:
    section.add "X-Amz-Credential", valid_618992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_618993: Call_GetRestoreDBClusterFromSnapshot_618969;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  let valid = call_618993.validator(path, query, header, formData, body, _)
  let scheme = call_618993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_618993.url(scheme.get, call_618993.host, call_618993.base,
                         call_618993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_618993, url, valid, _)

proc call*(call_618994: Call_GetRestoreDBClusterFromSnapshot_618969;
          DBClusterIdentifier: string; SnapshotIdentifier: string; Engine: string;
          AvailabilityZones: JsonNode = nil; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false; DBSubnetGroupName: string = "";
          KmsKeyId: string = ""; Action: string = "RestoreDBClusterFromSnapshot";
          EngineVersion: string = ""; Port: int = 0; Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterFromSnapshot
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the cluster to create from the snapshot or cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new cluster will belong to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   Action: string (required)
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new cluster.
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   Version: string (required)
  var query_618995 = newJObject()
  if AvailabilityZones != nil:
    query_618995.add "AvailabilityZones", AvailabilityZones
  add(query_618995, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_618995.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_618995.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_618995.add "Tags", Tags
  add(query_618995, "DeletionProtection", newJBool(DeletionProtection))
  add(query_618995, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_618995, "KmsKeyId", newJString(KmsKeyId))
  add(query_618995, "Action", newJString(Action))
  add(query_618995, "EngineVersion", newJString(EngineVersion))
  add(query_618995, "Port", newJInt(Port))
  add(query_618995, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(query_618995, "Engine", newJString(Engine))
  add(query_618995, "Version", newJString(Version))
  result = call_618994.call(nil, query_618995, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_618969(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_618970, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_618971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_619050 = ref object of OpenApiRestCall_616850
proc url_PostRestoreDBClusterToPointInTime_619052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBClusterToPointInTime_619051(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
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
  var valid_619053 = query.getOrDefault("Action")
  valid_619053 = validateParameter(valid_619053, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_619053 != nil:
    section.add "Action", valid_619053
  var valid_619054 = query.getOrDefault("Version")
  valid_619054 = validateParameter(valid_619054, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_619054 != nil:
    section.add "Version", valid_619054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_619055 = header.getOrDefault("X-Amz-Date")
  valid_619055 = validateParameter(valid_619055, JString, required = false,
                                 default = nil)
  if valid_619055 != nil:
    section.add "X-Amz-Date", valid_619055
  var valid_619056 = header.getOrDefault("X-Amz-Security-Token")
  valid_619056 = validateParameter(valid_619056, JString, required = false,
                                 default = nil)
  if valid_619056 != nil:
    section.add "X-Amz-Security-Token", valid_619056
  var valid_619057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619057 = validateParameter(valid_619057, JString, required = false,
                                 default = nil)
  if valid_619057 != nil:
    section.add "X-Amz-Content-Sha256", valid_619057
  var valid_619058 = header.getOrDefault("X-Amz-Algorithm")
  valid_619058 = validateParameter(valid_619058, JString, required = false,
                                 default = nil)
  if valid_619058 != nil:
    section.add "X-Amz-Algorithm", valid_619058
  var valid_619059 = header.getOrDefault("X-Amz-Signature")
  valid_619059 = validateParameter(valid_619059, JString, required = false,
                                 default = nil)
  if valid_619059 != nil:
    section.add "X-Amz-Signature", valid_619059
  var valid_619060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619060 = validateParameter(valid_619060, JString, required = false,
                                 default = nil)
  if valid_619060 != nil:
    section.add "X-Amz-SignedHeaders", valid_619060
  var valid_619061 = header.getOrDefault("X-Amz-Credential")
  valid_619061 = validateParameter(valid_619061, JString, required = false,
                                 default = nil)
  if valid_619061 != nil:
    section.add "X-Amz-Credential", valid_619061
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new cluster belongs to.
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterIdentifier` field"
  var valid_619062 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_619062 = validateParameter(valid_619062, JString, required = true,
                                 default = nil)
  if valid_619062 != nil:
    section.add "SourceDBClusterIdentifier", valid_619062
  var valid_619063 = formData.getOrDefault("Port")
  valid_619063 = validateParameter(valid_619063, JInt, required = false, default = nil)
  if valid_619063 != nil:
    section.add "Port", valid_619063
  var valid_619064 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_619064 = validateParameter(valid_619064, JArray, required = false,
                                 default = nil)
  if valid_619064 != nil:
    section.add "VpcSecurityGroupIds", valid_619064
  var valid_619065 = formData.getOrDefault("RestoreToTime")
  valid_619065 = validateParameter(valid_619065, JString, required = false,
                                 default = nil)
  if valid_619065 != nil:
    section.add "RestoreToTime", valid_619065
  var valid_619066 = formData.getOrDefault("Tags")
  valid_619066 = validateParameter(valid_619066, JArray, required = false,
                                 default = nil)
  if valid_619066 != nil:
    section.add "Tags", valid_619066
  var valid_619067 = formData.getOrDefault("DeletionProtection")
  valid_619067 = validateParameter(valid_619067, JBool, required = false, default = nil)
  if valid_619067 != nil:
    section.add "DeletionProtection", valid_619067
  var valid_619068 = formData.getOrDefault("DBSubnetGroupName")
  valid_619068 = validateParameter(valid_619068, JString, required = false,
                                 default = nil)
  if valid_619068 != nil:
    section.add "DBSubnetGroupName", valid_619068
  var valid_619069 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_619069 = validateParameter(valid_619069, JArray, required = false,
                                 default = nil)
  if valid_619069 != nil:
    section.add "EnableCloudwatchLogsExports", valid_619069
  var valid_619070 = formData.getOrDefault("KmsKeyId")
  valid_619070 = validateParameter(valid_619070, JString, required = false,
                                 default = nil)
  if valid_619070 != nil:
    section.add "KmsKeyId", valid_619070
  var valid_619071 = formData.getOrDefault("DBClusterIdentifier")
  valid_619071 = validateParameter(valid_619071, JString, required = true,
                                 default = nil)
  if valid_619071 != nil:
    section.add "DBClusterIdentifier", valid_619071
  var valid_619072 = formData.getOrDefault("UseLatestRestorableTime")
  valid_619072 = validateParameter(valid_619072, JBool, required = false, default = nil)
  if valid_619072 != nil:
    section.add "UseLatestRestorableTime", valid_619072
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_619073: Call_PostRestoreDBClusterToPointInTime_619050;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ## 
  let valid = call_619073.validator(path, query, header, formData, body, _)
  let scheme = call_619073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619073.url(scheme.get, call_619073.host, call_619073.base,
                         call_619073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619073, url, valid, _)

proc call*(call_619074: Call_PostRestoreDBClusterToPointInTime_619050;
          SourceDBClusterIdentifier: string; DBClusterIdentifier: string;
          Port: int = 0; VpcSecurityGroupIds: JsonNode = nil;
          RestoreToTime: string = ""; Tags: JsonNode = nil;
          DeletionProtection: bool = false; DBSubnetGroupName: string = "";
          Action: string = "RestoreDBClusterToPointInTime";
          EnableCloudwatchLogsExports: JsonNode = nil; KmsKeyId: string = "";
          Version: string = "2014-10-31"; UseLatestRestorableTime: bool = false): Recallable =
  ## postRestoreDBClusterToPointInTime
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new cluster belongs to.
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Version: string (required)
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  var query_619075 = newJObject()
  var formData_619076 = newJObject()
  add(formData_619076, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_619076, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_619076.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_619076, "RestoreToTime", newJString(RestoreToTime))
  if Tags != nil:
    formData_619076.add "Tags", Tags
  add(formData_619076, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_619076, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_619075, "Action", newJString(Action))
  if EnableCloudwatchLogsExports != nil:
    formData_619076.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_619076, "KmsKeyId", newJString(KmsKeyId))
  add(formData_619076, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_619075, "Version", newJString(Version))
  add(formData_619076, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  result = call_619074.call(nil, query_619075, nil, formData_619076, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_619050(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_619051, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_619052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_619024 = ref object of OpenApiRestCall_616850
proc url_GetRestoreDBClusterToPointInTime_619026(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBClusterToPointInTime_619025(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new cluster belongs to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   DBSubnetGroupName: JString
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   Action: JString (required)
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  var valid_619027 = query.getOrDefault("RestoreToTime")
  valid_619027 = validateParameter(valid_619027, JString, required = false,
                                 default = nil)
  if valid_619027 != nil:
    section.add "RestoreToTime", valid_619027
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_619028 = query.getOrDefault("DBClusterIdentifier")
  valid_619028 = validateParameter(valid_619028, JString, required = true,
                                 default = nil)
  if valid_619028 != nil:
    section.add "DBClusterIdentifier", valid_619028
  var valid_619029 = query.getOrDefault("VpcSecurityGroupIds")
  valid_619029 = validateParameter(valid_619029, JArray, required = false,
                                 default = nil)
  if valid_619029 != nil:
    section.add "VpcSecurityGroupIds", valid_619029
  var valid_619030 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_619030 = validateParameter(valid_619030, JArray, required = false,
                                 default = nil)
  if valid_619030 != nil:
    section.add "EnableCloudwatchLogsExports", valid_619030
  var valid_619031 = query.getOrDefault("Tags")
  valid_619031 = validateParameter(valid_619031, JArray, required = false,
                                 default = nil)
  if valid_619031 != nil:
    section.add "Tags", valid_619031
  var valid_619032 = query.getOrDefault("DeletionProtection")
  valid_619032 = validateParameter(valid_619032, JBool, required = false, default = nil)
  if valid_619032 != nil:
    section.add "DeletionProtection", valid_619032
  var valid_619033 = query.getOrDefault("UseLatestRestorableTime")
  valid_619033 = validateParameter(valid_619033, JBool, required = false, default = nil)
  if valid_619033 != nil:
    section.add "UseLatestRestorableTime", valid_619033
  var valid_619034 = query.getOrDefault("DBSubnetGroupName")
  valid_619034 = validateParameter(valid_619034, JString, required = false,
                                 default = nil)
  if valid_619034 != nil:
    section.add "DBSubnetGroupName", valid_619034
  var valid_619035 = query.getOrDefault("KmsKeyId")
  valid_619035 = validateParameter(valid_619035, JString, required = false,
                                 default = nil)
  if valid_619035 != nil:
    section.add "KmsKeyId", valid_619035
  var valid_619036 = query.getOrDefault("Action")
  valid_619036 = validateParameter(valid_619036, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_619036 != nil:
    section.add "Action", valid_619036
  var valid_619037 = query.getOrDefault("Port")
  valid_619037 = validateParameter(valid_619037, JInt, required = false, default = nil)
  if valid_619037 != nil:
    section.add "Port", valid_619037
  var valid_619038 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_619038 = validateParameter(valid_619038, JString, required = true,
                                 default = nil)
  if valid_619038 != nil:
    section.add "SourceDBClusterIdentifier", valid_619038
  var valid_619039 = query.getOrDefault("Version")
  valid_619039 = validateParameter(valid_619039, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_619039 != nil:
    section.add "Version", valid_619039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_619040 = header.getOrDefault("X-Amz-Date")
  valid_619040 = validateParameter(valid_619040, JString, required = false,
                                 default = nil)
  if valid_619040 != nil:
    section.add "X-Amz-Date", valid_619040
  var valid_619041 = header.getOrDefault("X-Amz-Security-Token")
  valid_619041 = validateParameter(valid_619041, JString, required = false,
                                 default = nil)
  if valid_619041 != nil:
    section.add "X-Amz-Security-Token", valid_619041
  var valid_619042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619042 = validateParameter(valid_619042, JString, required = false,
                                 default = nil)
  if valid_619042 != nil:
    section.add "X-Amz-Content-Sha256", valid_619042
  var valid_619043 = header.getOrDefault("X-Amz-Algorithm")
  valid_619043 = validateParameter(valid_619043, JString, required = false,
                                 default = nil)
  if valid_619043 != nil:
    section.add "X-Amz-Algorithm", valid_619043
  var valid_619044 = header.getOrDefault("X-Amz-Signature")
  valid_619044 = validateParameter(valid_619044, JString, required = false,
                                 default = nil)
  if valid_619044 != nil:
    section.add "X-Amz-Signature", valid_619044
  var valid_619045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619045 = validateParameter(valid_619045, JString, required = false,
                                 default = nil)
  if valid_619045 != nil:
    section.add "X-Amz-SignedHeaders", valid_619045
  var valid_619046 = header.getOrDefault("X-Amz-Credential")
  valid_619046 = validateParameter(valid_619046, JString, required = false,
                                 default = nil)
  if valid_619046 != nil:
    section.add "X-Amz-Credential", valid_619046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_619047: Call_GetRestoreDBClusterToPointInTime_619024;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ## 
  let valid = call_619047.validator(path, query, header, formData, body, _)
  let scheme = call_619047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619047.url(scheme.get, call_619047.host, call_619047.base,
                         call_619047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619047, url, valid, _)

proc call*(call_619048: Call_GetRestoreDBClusterToPointInTime_619024;
          DBClusterIdentifier: string; SourceDBClusterIdentifier: string;
          RestoreToTime: string = ""; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false; UseLatestRestorableTime: bool = false;
          DBSubnetGroupName: string = ""; KmsKeyId: string = "";
          Action: string = "RestoreDBClusterToPointInTime"; Port: int = 0;
          Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterToPointInTime
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new cluster belongs to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   DBSubnetGroupName: string
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   Action: string (required)
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_619049 = newJObject()
  add(query_619049, "RestoreToTime", newJString(RestoreToTime))
  add(query_619049, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_619049.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_619049.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_619049.add "Tags", Tags
  add(query_619049, "DeletionProtection", newJBool(DeletionProtection))
  add(query_619049, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_619049, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_619049, "KmsKeyId", newJString(KmsKeyId))
  add(query_619049, "Action", newJString(Action))
  add(query_619049, "Port", newJInt(Port))
  add(query_619049, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_619049, "Version", newJString(Version))
  result = call_619048.call(nil, query_619049, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_619024(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_619025, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_619026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_619093 = ref object of OpenApiRestCall_616850
proc url_PostStartDBCluster_619095(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostStartDBCluster_619094(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619096 = query.getOrDefault("Action")
  valid_619096 = validateParameter(valid_619096, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_619096 != nil:
    section.add "Action", valid_619096
  var valid_619097 = query.getOrDefault("Version")
  valid_619097 = validateParameter(valid_619097, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_619097 != nil:
    section.add "Version", valid_619097
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_619098 = header.getOrDefault("X-Amz-Date")
  valid_619098 = validateParameter(valid_619098, JString, required = false,
                                 default = nil)
  if valid_619098 != nil:
    section.add "X-Amz-Date", valid_619098
  var valid_619099 = header.getOrDefault("X-Amz-Security-Token")
  valid_619099 = validateParameter(valid_619099, JString, required = false,
                                 default = nil)
  if valid_619099 != nil:
    section.add "X-Amz-Security-Token", valid_619099
  var valid_619100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619100 = validateParameter(valid_619100, JString, required = false,
                                 default = nil)
  if valid_619100 != nil:
    section.add "X-Amz-Content-Sha256", valid_619100
  var valid_619101 = header.getOrDefault("X-Amz-Algorithm")
  valid_619101 = validateParameter(valid_619101, JString, required = false,
                                 default = nil)
  if valid_619101 != nil:
    section.add "X-Amz-Algorithm", valid_619101
  var valid_619102 = header.getOrDefault("X-Amz-Signature")
  valid_619102 = validateParameter(valid_619102, JString, required = false,
                                 default = nil)
  if valid_619102 != nil:
    section.add "X-Amz-Signature", valid_619102
  var valid_619103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619103 = validateParameter(valid_619103, JString, required = false,
                                 default = nil)
  if valid_619103 != nil:
    section.add "X-Amz-SignedHeaders", valid_619103
  var valid_619104 = header.getOrDefault("X-Amz-Credential")
  valid_619104 = validateParameter(valid_619104, JString, required = false,
                                 default = nil)
  if valid_619104 != nil:
    section.add "X-Amz-Credential", valid_619104
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_619105 = formData.getOrDefault("DBClusterIdentifier")
  valid_619105 = validateParameter(valid_619105, JString, required = true,
                                 default = nil)
  if valid_619105 != nil:
    section.add "DBClusterIdentifier", valid_619105
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_619106: Call_PostStartDBCluster_619093; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_619106.validator(path, query, header, formData, body, _)
  let scheme = call_619106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619106.url(scheme.get, call_619106.host, call_619106.base,
                         call_619106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619106, url, valid, _)

proc call*(call_619107: Call_PostStartDBCluster_619093;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_619108 = newJObject()
  var formData_619109 = newJObject()
  add(query_619108, "Action", newJString(Action))
  add(formData_619109, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_619108, "Version", newJString(Version))
  result = call_619107.call(nil, query_619108, nil, formData_619109, nil)

var postStartDBCluster* = Call_PostStartDBCluster_619093(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_619094, base: "/",
    url: url_PostStartDBCluster_619095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_619077 = ref object of OpenApiRestCall_616850
proc url_GetStartDBCluster_619079(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStartDBCluster_619078(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619080 = query.getOrDefault("DBClusterIdentifier")
  valid_619080 = validateParameter(valid_619080, JString, required = true,
                                 default = nil)
  if valid_619080 != nil:
    section.add "DBClusterIdentifier", valid_619080
  var valid_619081 = query.getOrDefault("Action")
  valid_619081 = validateParameter(valid_619081, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_619081 != nil:
    section.add "Action", valid_619081
  var valid_619082 = query.getOrDefault("Version")
  valid_619082 = validateParameter(valid_619082, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_619082 != nil:
    section.add "Version", valid_619082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_619083 = header.getOrDefault("X-Amz-Date")
  valid_619083 = validateParameter(valid_619083, JString, required = false,
                                 default = nil)
  if valid_619083 != nil:
    section.add "X-Amz-Date", valid_619083
  var valid_619084 = header.getOrDefault("X-Amz-Security-Token")
  valid_619084 = validateParameter(valid_619084, JString, required = false,
                                 default = nil)
  if valid_619084 != nil:
    section.add "X-Amz-Security-Token", valid_619084
  var valid_619085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619085 = validateParameter(valid_619085, JString, required = false,
                                 default = nil)
  if valid_619085 != nil:
    section.add "X-Amz-Content-Sha256", valid_619085
  var valid_619086 = header.getOrDefault("X-Amz-Algorithm")
  valid_619086 = validateParameter(valid_619086, JString, required = false,
                                 default = nil)
  if valid_619086 != nil:
    section.add "X-Amz-Algorithm", valid_619086
  var valid_619087 = header.getOrDefault("X-Amz-Signature")
  valid_619087 = validateParameter(valid_619087, JString, required = false,
                                 default = nil)
  if valid_619087 != nil:
    section.add "X-Amz-Signature", valid_619087
  var valid_619088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619088 = validateParameter(valid_619088, JString, required = false,
                                 default = nil)
  if valid_619088 != nil:
    section.add "X-Amz-SignedHeaders", valid_619088
  var valid_619089 = header.getOrDefault("X-Amz-Credential")
  valid_619089 = validateParameter(valid_619089, JString, required = false,
                                 default = nil)
  if valid_619089 != nil:
    section.add "X-Amz-Credential", valid_619089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_619090: Call_GetStartDBCluster_619077; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_619090.validator(path, query, header, formData, body, _)
  let scheme = call_619090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619090.url(scheme.get, call_619090.host, call_619090.base,
                         call_619090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619090, url, valid, _)

proc call*(call_619091: Call_GetStartDBCluster_619077; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_619092 = newJObject()
  add(query_619092, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_619092, "Action", newJString(Action))
  add(query_619092, "Version", newJString(Version))
  result = call_619091.call(nil, query_619092, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_619077(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_619078,
    base: "/", url: url_GetStartDBCluster_619079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_619126 = ref object of OpenApiRestCall_616850
proc url_PostStopDBCluster_619128(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostStopDBCluster_619127(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619129 = query.getOrDefault("Action")
  valid_619129 = validateParameter(valid_619129, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_619129 != nil:
    section.add "Action", valid_619129
  var valid_619130 = query.getOrDefault("Version")
  valid_619130 = validateParameter(valid_619130, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_619130 != nil:
    section.add "Version", valid_619130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_619131 = header.getOrDefault("X-Amz-Date")
  valid_619131 = validateParameter(valid_619131, JString, required = false,
                                 default = nil)
  if valid_619131 != nil:
    section.add "X-Amz-Date", valid_619131
  var valid_619132 = header.getOrDefault("X-Amz-Security-Token")
  valid_619132 = validateParameter(valid_619132, JString, required = false,
                                 default = nil)
  if valid_619132 != nil:
    section.add "X-Amz-Security-Token", valid_619132
  var valid_619133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619133 = validateParameter(valid_619133, JString, required = false,
                                 default = nil)
  if valid_619133 != nil:
    section.add "X-Amz-Content-Sha256", valid_619133
  var valid_619134 = header.getOrDefault("X-Amz-Algorithm")
  valid_619134 = validateParameter(valid_619134, JString, required = false,
                                 default = nil)
  if valid_619134 != nil:
    section.add "X-Amz-Algorithm", valid_619134
  var valid_619135 = header.getOrDefault("X-Amz-Signature")
  valid_619135 = validateParameter(valid_619135, JString, required = false,
                                 default = nil)
  if valid_619135 != nil:
    section.add "X-Amz-Signature", valid_619135
  var valid_619136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619136 = validateParameter(valid_619136, JString, required = false,
                                 default = nil)
  if valid_619136 != nil:
    section.add "X-Amz-SignedHeaders", valid_619136
  var valid_619137 = header.getOrDefault("X-Amz-Credential")
  valid_619137 = validateParameter(valid_619137, JString, required = false,
                                 default = nil)
  if valid_619137 != nil:
    section.add "X-Amz-Credential", valid_619137
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_619138 = formData.getOrDefault("DBClusterIdentifier")
  valid_619138 = validateParameter(valid_619138, JString, required = true,
                                 default = nil)
  if valid_619138 != nil:
    section.add "DBClusterIdentifier", valid_619138
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_619139: Call_PostStopDBCluster_619126; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_619139.validator(path, query, header, formData, body, _)
  let scheme = call_619139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619139.url(scheme.get, call_619139.host, call_619139.base,
                         call_619139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619139, url, valid, _)

proc call*(call_619140: Call_PostStopDBCluster_619126; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_619141 = newJObject()
  var formData_619142 = newJObject()
  add(query_619141, "Action", newJString(Action))
  add(formData_619142, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_619141, "Version", newJString(Version))
  result = call_619140.call(nil, query_619141, nil, formData_619142, nil)

var postStopDBCluster* = Call_PostStopDBCluster_619126(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_619127,
    base: "/", url: url_PostStopDBCluster_619128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_619110 = ref object of OpenApiRestCall_616850
proc url_GetStopDBCluster_619112(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStopDBCluster_619111(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_619113 = query.getOrDefault("DBClusterIdentifier")
  valid_619113 = validateParameter(valid_619113, JString, required = true,
                                 default = nil)
  if valid_619113 != nil:
    section.add "DBClusterIdentifier", valid_619113
  var valid_619114 = query.getOrDefault("Action")
  valid_619114 = validateParameter(valid_619114, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_619114 != nil:
    section.add "Action", valid_619114
  var valid_619115 = query.getOrDefault("Version")
  valid_619115 = validateParameter(valid_619115, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_619115 != nil:
    section.add "Version", valid_619115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_619116 = header.getOrDefault("X-Amz-Date")
  valid_619116 = validateParameter(valid_619116, JString, required = false,
                                 default = nil)
  if valid_619116 != nil:
    section.add "X-Amz-Date", valid_619116
  var valid_619117 = header.getOrDefault("X-Amz-Security-Token")
  valid_619117 = validateParameter(valid_619117, JString, required = false,
                                 default = nil)
  if valid_619117 != nil:
    section.add "X-Amz-Security-Token", valid_619117
  var valid_619118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_619118 = validateParameter(valid_619118, JString, required = false,
                                 default = nil)
  if valid_619118 != nil:
    section.add "X-Amz-Content-Sha256", valid_619118
  var valid_619119 = header.getOrDefault("X-Amz-Algorithm")
  valid_619119 = validateParameter(valid_619119, JString, required = false,
                                 default = nil)
  if valid_619119 != nil:
    section.add "X-Amz-Algorithm", valid_619119
  var valid_619120 = header.getOrDefault("X-Amz-Signature")
  valid_619120 = validateParameter(valid_619120, JString, required = false,
                                 default = nil)
  if valid_619120 != nil:
    section.add "X-Amz-Signature", valid_619120
  var valid_619121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_619121 = validateParameter(valid_619121, JString, required = false,
                                 default = nil)
  if valid_619121 != nil:
    section.add "X-Amz-SignedHeaders", valid_619121
  var valid_619122 = header.getOrDefault("X-Amz-Credential")
  valid_619122 = validateParameter(valid_619122, JString, required = false,
                                 default = nil)
  if valid_619122 != nil:
    section.add "X-Amz-Credential", valid_619122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_619123: Call_GetStopDBCluster_619110; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_619123.validator(path, query, header, formData, body, _)
  let scheme = call_619123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_619123.url(scheme.get, call_619123.host, call_619123.base,
                         call_619123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_619123, url, valid, _)

proc call*(call_619124: Call_GetStopDBCluster_619110; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_619125 = newJObject()
  add(query_619125, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_619125, "Action", newJString(Action))
  add(query_619125, "Version", newJString(Version))
  result = call_619124.call(nil, query_619125, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_619110(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_619111,
    base: "/", url: url_GetStopDBCluster_619112,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

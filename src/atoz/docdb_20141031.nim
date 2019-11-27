
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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
  Call_PostAddTagsToResource_599961 = ref object of OpenApiRestCall_599352
proc url_PostAddTagsToResource_599963(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTagsToResource_599962(path: JsonNode; query: JsonNode;
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
  var valid_599964 = query.getOrDefault("Action")
  valid_599964 = validateParameter(valid_599964, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_599964 != nil:
    section.add "Action", valid_599964
  var valid_599965 = query.getOrDefault("Version")
  valid_599965 = validateParameter(valid_599965, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_599965 != nil:
    section.add "Version", valid_599965
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599966 = header.getOrDefault("X-Amz-Date")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Date", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Security-Token")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Security-Token", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Content-Sha256", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Algorithm")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Algorithm", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-Signature")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Signature", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-SignedHeaders", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Credential")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Credential", valid_599972
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_599973 = formData.getOrDefault("Tags")
  valid_599973 = validateParameter(valid_599973, JArray, required = true, default = nil)
  if valid_599973 != nil:
    section.add "Tags", valid_599973
  var valid_599974 = formData.getOrDefault("ResourceName")
  valid_599974 = validateParameter(valid_599974, JString, required = true,
                                 default = nil)
  if valid_599974 != nil:
    section.add "ResourceName", valid_599974
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599975: Call_PostAddTagsToResource_599961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_599975.validator(path, query, header, formData, body)
  let scheme = call_599975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599975.url(scheme.get, call_599975.host, call_599975.base,
                         call_599975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599975, url, valid)

proc call*(call_599976: Call_PostAddTagsToResource_599961; Tags: JsonNode;
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
  var query_599977 = newJObject()
  var formData_599978 = newJObject()
  if Tags != nil:
    formData_599978.add "Tags", Tags
  add(query_599977, "Action", newJString(Action))
  add(formData_599978, "ResourceName", newJString(ResourceName))
  add(query_599977, "Version", newJString(Version))
  result = call_599976.call(nil, query_599977, nil, formData_599978, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_599961(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_599962, base: "/",
    url: url_PostAddTagsToResource_599963, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_599689 = ref object of OpenApiRestCall_599352
proc url_GetAddTagsToResource_599691(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTagsToResource_599690(path: JsonNode; query: JsonNode;
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
  var valid_599803 = query.getOrDefault("Tags")
  valid_599803 = validateParameter(valid_599803, JArray, required = true, default = nil)
  if valid_599803 != nil:
    section.add "Tags", valid_599803
  var valid_599804 = query.getOrDefault("ResourceName")
  valid_599804 = validateParameter(valid_599804, JString, required = true,
                                 default = nil)
  if valid_599804 != nil:
    section.add "ResourceName", valid_599804
  var valid_599818 = query.getOrDefault("Action")
  valid_599818 = validateParameter(valid_599818, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_599818 != nil:
    section.add "Action", valid_599818
  var valid_599819 = query.getOrDefault("Version")
  valid_599819 = validateParameter(valid_599819, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_599819 != nil:
    section.add "Version", valid_599819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599820 = header.getOrDefault("X-Amz-Date")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Date", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Security-Token")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Security-Token", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Content-Sha256", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Algorithm")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Algorithm", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Signature")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Signature", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-SignedHeaders", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Credential")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Credential", valid_599826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599849: Call_GetAddTagsToResource_599689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_599849.validator(path, query, header, formData, body)
  let scheme = call_599849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599849.url(scheme.get, call_599849.host, call_599849.base,
                         call_599849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599849, url, valid)

proc call*(call_599920: Call_GetAddTagsToResource_599689; Tags: JsonNode;
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
  var query_599921 = newJObject()
  if Tags != nil:
    query_599921.add "Tags", Tags
  add(query_599921, "ResourceName", newJString(ResourceName))
  add(query_599921, "Action", newJString(Action))
  add(query_599921, "Version", newJString(Version))
  result = call_599920.call(nil, query_599921, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_599689(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_599690, base: "/",
    url: url_GetAddTagsToResource_599691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_599997 = ref object of OpenApiRestCall_599352
proc url_PostApplyPendingMaintenanceAction_599999(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplyPendingMaintenanceAction_599998(path: JsonNode;
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
  var valid_600000 = query.getOrDefault("Action")
  valid_600000 = validateParameter(valid_600000, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_600000 != nil:
    section.add "Action", valid_600000
  var valid_600001 = query.getOrDefault("Version")
  valid_600001 = validateParameter(valid_600001, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600001 != nil:
    section.add "Version", valid_600001
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600002 = header.getOrDefault("X-Amz-Date")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Date", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Security-Token")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Security-Token", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Content-Sha256", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Algorithm")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Algorithm", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Signature")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Signature", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-SignedHeaders", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Credential")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Credential", valid_600008
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
  var valid_600009 = formData.getOrDefault("ApplyAction")
  valid_600009 = validateParameter(valid_600009, JString, required = true,
                                 default = nil)
  if valid_600009 != nil:
    section.add "ApplyAction", valid_600009
  var valid_600010 = formData.getOrDefault("ResourceIdentifier")
  valid_600010 = validateParameter(valid_600010, JString, required = true,
                                 default = nil)
  if valid_600010 != nil:
    section.add "ResourceIdentifier", valid_600010
  var valid_600011 = formData.getOrDefault("OptInType")
  valid_600011 = validateParameter(valid_600011, JString, required = true,
                                 default = nil)
  if valid_600011 != nil:
    section.add "OptInType", valid_600011
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600012: Call_PostApplyPendingMaintenanceAction_599997;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_600012.validator(path, query, header, formData, body)
  let scheme = call_600012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600012.url(scheme.get, call_600012.host, call_600012.base,
                         call_600012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600012, url, valid)

proc call*(call_600013: Call_PostApplyPendingMaintenanceAction_599997;
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
  var query_600014 = newJObject()
  var formData_600015 = newJObject()
  add(query_600014, "Action", newJString(Action))
  add(formData_600015, "ApplyAction", newJString(ApplyAction))
  add(formData_600015, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_600015, "OptInType", newJString(OptInType))
  add(query_600014, "Version", newJString(Version))
  result = call_600013.call(nil, query_600014, nil, formData_600015, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_599997(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_599998, base: "/",
    url: url_PostApplyPendingMaintenanceAction_599999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_599979 = ref object of OpenApiRestCall_599352
proc url_GetApplyPendingMaintenanceAction_599981(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplyPendingMaintenanceAction_599980(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599982 = query.getOrDefault("ApplyAction")
  valid_599982 = validateParameter(valid_599982, JString, required = true,
                                 default = nil)
  if valid_599982 != nil:
    section.add "ApplyAction", valid_599982
  var valid_599983 = query.getOrDefault("ResourceIdentifier")
  valid_599983 = validateParameter(valid_599983, JString, required = true,
                                 default = nil)
  if valid_599983 != nil:
    section.add "ResourceIdentifier", valid_599983
  var valid_599984 = query.getOrDefault("Action")
  valid_599984 = validateParameter(valid_599984, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_599984 != nil:
    section.add "Action", valid_599984
  var valid_599985 = query.getOrDefault("OptInType")
  valid_599985 = validateParameter(valid_599985, JString, required = true,
                                 default = nil)
  if valid_599985 != nil:
    section.add "OptInType", valid_599985
  var valid_599986 = query.getOrDefault("Version")
  valid_599986 = validateParameter(valid_599986, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_599986 != nil:
    section.add "Version", valid_599986
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599987 = header.getOrDefault("X-Amz-Date")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Date", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Security-Token")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Security-Token", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Content-Sha256", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Algorithm")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Algorithm", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-Signature")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Signature", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-SignedHeaders", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Credential")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Credential", valid_599993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599994: Call_GetApplyPendingMaintenanceAction_599979;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_599994.validator(path, query, header, formData, body)
  let scheme = call_599994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599994.url(scheme.get, call_599994.host, call_599994.base,
                         call_599994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599994, url, valid)

proc call*(call_599995: Call_GetApplyPendingMaintenanceAction_599979;
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
  var query_599996 = newJObject()
  add(query_599996, "ApplyAction", newJString(ApplyAction))
  add(query_599996, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_599996, "Action", newJString(Action))
  add(query_599996, "OptInType", newJString(OptInType))
  add(query_599996, "Version", newJString(Version))
  result = call_599995.call(nil, query_599996, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_599979(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_599980, base: "/",
    url: url_GetApplyPendingMaintenanceAction_599981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_600035 = ref object of OpenApiRestCall_599352
proc url_PostCopyDBClusterParameterGroup_600037(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBClusterParameterGroup_600036(path: JsonNode;
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
  var valid_600038 = query.getOrDefault("Action")
  valid_600038 = validateParameter(valid_600038, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_600038 != nil:
    section.add "Action", valid_600038
  var valid_600039 = query.getOrDefault("Version")
  valid_600039 = validateParameter(valid_600039, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600039 != nil:
    section.add "Version", valid_600039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600040 = header.getOrDefault("X-Amz-Date")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Date", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Security-Token")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Security-Token", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Content-Sha256", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Algorithm")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Algorithm", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Signature")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Signature", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-SignedHeaders", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-Credential")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Credential", valid_600046
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBClusterParameterGroupDescription` field"
  var valid_600047 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_600047 = validateParameter(valid_600047, JString, required = true,
                                 default = nil)
  if valid_600047 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_600047
  var valid_600048 = formData.getOrDefault("Tags")
  valid_600048 = validateParameter(valid_600048, JArray, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "Tags", valid_600048
  var valid_600049 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_600049 = validateParameter(valid_600049, JString, required = true,
                                 default = nil)
  if valid_600049 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_600049
  var valid_600050 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_600050 = validateParameter(valid_600050, JString, required = true,
                                 default = nil)
  if valid_600050 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_600050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600051: Call_PostCopyDBClusterParameterGroup_600035;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_600051.validator(path, query, header, formData, body)
  let scheme = call_600051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600051.url(scheme.get, call_600051.host, call_600051.base,
                         call_600051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600051, url, valid)

proc call*(call_600052: Call_PostCopyDBClusterParameterGroup_600035;
          TargetDBClusterParameterGroupDescription: string;
          SourceDBClusterParameterGroupIdentifier: string;
          TargetDBClusterParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterParameterGroup
  ## Copies the specified DB cluster parameter group.
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   Action: string (required)
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Version: string (required)
  var query_600053 = newJObject()
  var formData_600054 = newJObject()
  add(formData_600054, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    formData_600054.add "Tags", Tags
  add(query_600053, "Action", newJString(Action))
  add(formData_600054, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(formData_600054, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_600053, "Version", newJString(Version))
  result = call_600052.call(nil, query_600053, nil, formData_600054, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_600035(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_600036, base: "/",
    url: url_PostCopyDBClusterParameterGroup_600037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_600016 = ref object of OpenApiRestCall_599352
proc url_GetCopyDBClusterParameterGroup_600018(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBClusterParameterGroup_600017(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Copies the specified DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupDescription: JString (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Action: JString (required)
  ##   TargetDBClusterParameterGroupIdentifier: JString (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBClusterParameterGroupIdentifier` field"
  var valid_600019 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_600019 = validateParameter(valid_600019, JString, required = true,
                                 default = nil)
  if valid_600019 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_600019
  var valid_600020 = query.getOrDefault("Tags")
  valid_600020 = validateParameter(valid_600020, JArray, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "Tags", valid_600020
  var valid_600021 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_600021 = validateParameter(valid_600021, JString, required = true,
                                 default = nil)
  if valid_600021 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_600021
  var valid_600022 = query.getOrDefault("Action")
  valid_600022 = validateParameter(valid_600022, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_600022 != nil:
    section.add "Action", valid_600022
  var valid_600023 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_600023 = validateParameter(valid_600023, JString, required = true,
                                 default = nil)
  if valid_600023 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_600023
  var valid_600024 = query.getOrDefault("Version")
  valid_600024 = validateParameter(valid_600024, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600024 != nil:
    section.add "Version", valid_600024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600025 = header.getOrDefault("X-Amz-Date")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Date", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Security-Token")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Security-Token", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Content-Sha256", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Algorithm")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Algorithm", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Signature")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Signature", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-SignedHeaders", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-Credential")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Credential", valid_600031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600032: Call_GetCopyDBClusterParameterGroup_600016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_600032.validator(path, query, header, formData, body)
  let scheme = call_600032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600032.url(scheme.get, call_600032.host, call_600032.base,
                         call_600032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600032, url, valid)

proc call*(call_600033: Call_GetCopyDBClusterParameterGroup_600016;
          SourceDBClusterParameterGroupIdentifier: string;
          TargetDBClusterParameterGroupDescription: string;
          TargetDBClusterParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCopyDBClusterParameterGroup
  ## Copies the specified DB cluster parameter group.
  ##   SourceDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid DB cluster parameter group.</p> </li> <li> <p>If the source DB cluster parameter group is in the same AWS Region as the copy, specify a valid DB parameter group identifier; for example, <code>my-db-cluster-param-group</code>, or a valid ARN.</p> </li> <li> <p>If the source DB parameter group is in a different AWS Region than the copy, specify a valid DB cluster parameter group ARN; for example, 
  ## <code>arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags that are to be assigned to the parameter group.
  ##   TargetDBClusterParameterGroupDescription: string (required)
  ##                                           : A description for the copied DB cluster parameter group.
  ##   Action: string (required)
  ##   TargetDBClusterParameterGroupIdentifier: string (required)
  ##                                          : <p>The identifier for the copied DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Cannot be null, empty, or blank.</p> </li> <li> <p>Must contain from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-param-group1</code> </p>
  ##   Version: string (required)
  var query_600034 = newJObject()
  add(query_600034, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  if Tags != nil:
    query_600034.add "Tags", Tags
  add(query_600034, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  add(query_600034, "Action", newJString(Action))
  add(query_600034, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_600034, "Version", newJString(Version))
  result = call_600033.call(nil, query_600034, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_600016(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_600017, base: "/",
    url: url_GetCopyDBClusterParameterGroup_600018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_600076 = ref object of OpenApiRestCall_599352
proc url_PostCopyDBClusterSnapshot_600078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBClusterSnapshot_600077(path: JsonNode; query: JsonNode;
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
  var valid_600079 = query.getOrDefault("Action")
  valid_600079 = validateParameter(valid_600079, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_600079 != nil:
    section.add "Action", valid_600079
  var valid_600080 = query.getOrDefault("Version")
  valid_600080 = validateParameter(valid_600080, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600080 != nil:
    section.add "Version", valid_600080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600081 = header.getOrDefault("X-Amz-Date")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Date", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Security-Token")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Security-Token", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Content-Sha256", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Algorithm")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Algorithm", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Signature")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Signature", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-SignedHeaders", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Credential")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Credential", valid_600087
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  section = newJObject()
  var valid_600088 = formData.getOrDefault("PreSignedUrl")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "PreSignedUrl", valid_600088
  var valid_600089 = formData.getOrDefault("Tags")
  valid_600089 = validateParameter(valid_600089, JArray, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "Tags", valid_600089
  var valid_600090 = formData.getOrDefault("CopyTags")
  valid_600090 = validateParameter(valid_600090, JBool, required = false, default = nil)
  if valid_600090 != nil:
    section.add "CopyTags", valid_600090
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_600091 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_600091 = validateParameter(valid_600091, JString, required = true,
                                 default = nil)
  if valid_600091 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_600091
  var valid_600092 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_600092 = validateParameter(valid_600092, JString, required = true,
                                 default = nil)
  if valid_600092 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_600092
  var valid_600093 = formData.getOrDefault("KmsKeyId")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "KmsKeyId", valid_600093
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600094: Call_PostCopyDBClusterSnapshot_600076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_600094.validator(path, query, header, formData, body)
  let scheme = call_600094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600094.url(scheme.get, call_600094.host, call_600094.base,
                         call_600094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600094, url, valid)

proc call*(call_600095: Call_PostCopyDBClusterSnapshot_600076;
          SourceDBClusterSnapshotIdentifier: string;
          TargetDBClusterSnapshotIdentifier: string; PreSignedUrl: string = "";
          Tags: JsonNode = nil; CopyTags: bool = false;
          Action: string = "CopyDBClusterSnapshot"; KmsKeyId: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Action: string (required)
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   Version: string (required)
  var query_600096 = newJObject()
  var formData_600097 = newJObject()
  add(formData_600097, "PreSignedUrl", newJString(PreSignedUrl))
  if Tags != nil:
    formData_600097.add "Tags", Tags
  add(formData_600097, "CopyTags", newJBool(CopyTags))
  add(formData_600097, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_600097, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_600096, "Action", newJString(Action))
  add(formData_600097, "KmsKeyId", newJString(KmsKeyId))
  add(query_600096, "Version", newJString(Version))
  result = call_600095.call(nil, query_600096, nil, formData_600097, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_600076(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_600077, base: "/",
    url: url_PostCopyDBClusterSnapshot_600078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_600055 = ref object of OpenApiRestCall_599352
proc url_GetCopyDBClusterSnapshot_600057(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBClusterSnapshot_600056(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreSignedUrl: JString
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: JString (required)
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Version: JString (required)
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  section = newJObject()
  var valid_600058 = query.getOrDefault("PreSignedUrl")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "PreSignedUrl", valid_600058
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_600059 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_600059 = validateParameter(valid_600059, JString, required = true,
                                 default = nil)
  if valid_600059 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_600059
  var valid_600060 = query.getOrDefault("Tags")
  valid_600060 = validateParameter(valid_600060, JArray, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "Tags", valid_600060
  var valid_600061 = query.getOrDefault("Action")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_600061 != nil:
    section.add "Action", valid_600061
  var valid_600062 = query.getOrDefault("KmsKeyId")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "KmsKeyId", valid_600062
  var valid_600063 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_600063 = validateParameter(valid_600063, JString, required = true,
                                 default = nil)
  if valid_600063 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_600063
  var valid_600064 = query.getOrDefault("Version")
  valid_600064 = validateParameter(valid_600064, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600064 != nil:
    section.add "Version", valid_600064
  var valid_600065 = query.getOrDefault("CopyTags")
  valid_600065 = validateParameter(valid_600065, JBool, required = false, default = nil)
  if valid_600065 != nil:
    section.add "CopyTags", valid_600065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600066 = header.getOrDefault("X-Amz-Date")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Date", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Security-Token")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Security-Token", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Content-Sha256", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Algorithm")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Algorithm", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Signature")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Signature", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-SignedHeaders", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Credential")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Credential", valid_600072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600073: Call_GetCopyDBClusterSnapshot_600055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_600073.validator(path, query, header, formData, body)
  let scheme = call_600073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600073.url(scheme.get, call_600073.host, call_600073.base,
                         call_600073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600073, url, valid)

proc call*(call_600074: Call_GetCopyDBClusterSnapshot_600055;
          TargetDBClusterSnapshotIdentifier: string;
          SourceDBClusterSnapshotIdentifier: string; PreSignedUrl: string = "";
          Tags: JsonNode = nil; Action: string = "CopyDBClusterSnapshot";
          KmsKeyId: string = ""; Version: string = "2014-10-31"; CopyTags: bool = false): Recallable =
  ## getCopyDBClusterSnapshot
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ##   PreSignedUrl: string
  ##               : <p>The URL that contains a Signature Version 4 signed request for the <code>CopyDBClusterSnapshot</code> API action in the AWS Region that contains the source DB cluster snapshot to copy. You must use the <code>PreSignedUrl</code> parameter when copying an encrypted DB cluster snapshot from another AWS Region.</p> <p>The presigned URL must be a valid request for the <code>CopyDBSClusterSnapshot</code> API action that can be executed in the source AWS Region that contains the encrypted DB cluster snapshot to be copied. The presigned URL request must contain the following parameter values:</p> <ul> <li> <p> <code>KmsKeyId</code> - The AWS KMS key identifier for the key to use to encrypt the copy of the DB cluster snapshot in the destination AWS Region. This is the same identifier for both the <code>CopyDBClusterSnapshot</code> action that is called in the destination AWS Region, and the action contained in the presigned URL.</p> </li> <li> <p> <code>DestinationRegion</code> - The name of the AWS Region that the DB cluster snapshot will be created in.</p> </li> <li> <p> <code>SourceDBClusterSnapshotIdentifier</code> - The DB cluster snapshot identifier for the encrypted DB cluster snapshot to be copied. This identifier must be in the Amazon Resource Name (ARN) format for the source AWS Region. For example, if you are copying an encrypted DB cluster snapshot from the us-west-2 AWS Region, then your <code>SourceDBClusterSnapshotIdentifier</code> looks like the following example: 
  ## <code>arn:aws:rds:us-west-2:123456789012:cluster-snapshot:my-cluster-snapshot-20161115</code>.</p> </li> </ul>
  ##   TargetDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot2</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: string (required)
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted DB cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted DB cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the DB cluster snapshot is encrypted with the same AWS KMS key as the source DB cluster snapshot. </p> <p>If you copy an encrypted DB cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted DB cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the DB cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted DB cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the DB cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared DB cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid DB snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid DB cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Version: string (required)
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  var query_600075 = newJObject()
  add(query_600075, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_600075, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  if Tags != nil:
    query_600075.add "Tags", Tags
  add(query_600075, "Action", newJString(Action))
  add(query_600075, "KmsKeyId", newJString(KmsKeyId))
  add(query_600075, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_600075, "Version", newJString(Version))
  add(query_600075, "CopyTags", newJBool(CopyTags))
  result = call_600074.call(nil, query_600075, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_600055(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_600056, base: "/",
    url: url_GetCopyDBClusterSnapshot_600057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_600131 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBCluster_600133(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBCluster_600132(path: JsonNode; query: JsonNode;
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
  var valid_600134 = query.getOrDefault("Action")
  valid_600134 = validateParameter(valid_600134, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_600134 != nil:
    section.add "Action", valid_600134
  var valid_600135 = query.getOrDefault("Version")
  valid_600135 = validateParameter(valid_600135, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600135 != nil:
    section.add "Version", valid_600135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600136 = header.getOrDefault("X-Amz-Date")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Date", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Security-Token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Security-Token", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Content-Sha256", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Algorithm")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Algorithm", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Signature")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Signature", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-SignedHeaders", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Credential")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Credential", valid_600142
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  var valid_600143 = formData.getOrDefault("Port")
  valid_600143 = validateParameter(valid_600143, JInt, required = false, default = nil)
  if valid_600143 != nil:
    section.add "Port", valid_600143
  var valid_600144 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_600144 = validateParameter(valid_600144, JArray, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "VpcSecurityGroupIds", valid_600144
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_600145 = formData.getOrDefault("Engine")
  valid_600145 = validateParameter(valid_600145, JString, required = true,
                                 default = nil)
  if valid_600145 != nil:
    section.add "Engine", valid_600145
  var valid_600146 = formData.getOrDefault("BackupRetentionPeriod")
  valid_600146 = validateParameter(valid_600146, JInt, required = false, default = nil)
  if valid_600146 != nil:
    section.add "BackupRetentionPeriod", valid_600146
  var valid_600147 = formData.getOrDefault("Tags")
  valid_600147 = validateParameter(valid_600147, JArray, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "Tags", valid_600147
  var valid_600148 = formData.getOrDefault("MasterUserPassword")
  valid_600148 = validateParameter(valid_600148, JString, required = true,
                                 default = nil)
  if valid_600148 != nil:
    section.add "MasterUserPassword", valid_600148
  var valid_600149 = formData.getOrDefault("DeletionProtection")
  valid_600149 = validateParameter(valid_600149, JBool, required = false, default = nil)
  if valid_600149 != nil:
    section.add "DeletionProtection", valid_600149
  var valid_600150 = formData.getOrDefault("DBSubnetGroupName")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "DBSubnetGroupName", valid_600150
  var valid_600151 = formData.getOrDefault("AvailabilityZones")
  valid_600151 = validateParameter(valid_600151, JArray, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "AvailabilityZones", valid_600151
  var valid_600152 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "DBClusterParameterGroupName", valid_600152
  var valid_600153 = formData.getOrDefault("MasterUsername")
  valid_600153 = validateParameter(valid_600153, JString, required = true,
                                 default = nil)
  if valid_600153 != nil:
    section.add "MasterUsername", valid_600153
  var valid_600154 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_600154 = validateParameter(valid_600154, JArray, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "EnableCloudwatchLogsExports", valid_600154
  var valid_600155 = formData.getOrDefault("PreferredBackupWindow")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "PreferredBackupWindow", valid_600155
  var valid_600156 = formData.getOrDefault("KmsKeyId")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "KmsKeyId", valid_600156
  var valid_600157 = formData.getOrDefault("StorageEncrypted")
  valid_600157 = validateParameter(valid_600157, JBool, required = false, default = nil)
  if valid_600157 != nil:
    section.add "StorageEncrypted", valid_600157
  var valid_600158 = formData.getOrDefault("DBClusterIdentifier")
  valid_600158 = validateParameter(valid_600158, JString, required = true,
                                 default = nil)
  if valid_600158 != nil:
    section.add "DBClusterIdentifier", valid_600158
  var valid_600159 = formData.getOrDefault("EngineVersion")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "EngineVersion", valid_600159
  var valid_600160 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "PreferredMaintenanceWindow", valid_600160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600161: Call_PostCreateDBCluster_600131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_600161.validator(path, query, header, formData, body)
  let scheme = call_600161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600161.url(scheme.get, call_600161.host, call_600161.base,
                         call_600161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600161, url, valid)

proc call*(call_600162: Call_PostCreateDBCluster_600131; Engine: string;
          MasterUserPassword: string; MasterUsername: string;
          DBClusterIdentifier: string; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          Tags: JsonNode = nil; DeletionProtection: bool = false;
          DBSubnetGroupName: string = ""; Action: string = "CreateDBCluster";
          AvailabilityZones: JsonNode = nil;
          DBClusterParameterGroupName: string = "";
          EnableCloudwatchLogsExports: JsonNode = nil;
          PreferredBackupWindow: string = ""; KmsKeyId: string = "";
          StorageEncrypted: bool = false; EngineVersion: string = "";
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postCreateDBCluster
  ## Creates a new Amazon DocumentDB DB cluster.
  ##   Port: int
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_600163 = newJObject()
  var formData_600164 = newJObject()
  add(formData_600164, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_600164.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_600164, "Engine", newJString(Engine))
  add(formData_600164, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if Tags != nil:
    formData_600164.add "Tags", Tags
  add(formData_600164, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_600164, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_600164, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600163, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_600164.add "AvailabilityZones", AvailabilityZones
  add(formData_600164, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_600164, "MasterUsername", newJString(MasterUsername))
  if EnableCloudwatchLogsExports != nil:
    formData_600164.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_600164, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_600164, "KmsKeyId", newJString(KmsKeyId))
  add(formData_600164, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_600164, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_600164, "EngineVersion", newJString(EngineVersion))
  add(query_600163, "Version", newJString(Version))
  add(formData_600164, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_600162.call(nil, query_600163, nil, formData_600164, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_600131(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_600132, base: "/",
    url: url_PostCreateDBCluster_600133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_600098 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBCluster_600100(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBCluster_600099(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   Port: JInt
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: JString (required)
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_600101 = query.getOrDefault("Engine")
  valid_600101 = validateParameter(valid_600101, JString, required = true,
                                 default = nil)
  if valid_600101 != nil:
    section.add "Engine", valid_600101
  var valid_600102 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "PreferredMaintenanceWindow", valid_600102
  var valid_600103 = query.getOrDefault("DBClusterParameterGroupName")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "DBClusterParameterGroupName", valid_600103
  var valid_600104 = query.getOrDefault("StorageEncrypted")
  valid_600104 = validateParameter(valid_600104, JBool, required = false, default = nil)
  if valid_600104 != nil:
    section.add "StorageEncrypted", valid_600104
  var valid_600105 = query.getOrDefault("AvailabilityZones")
  valid_600105 = validateParameter(valid_600105, JArray, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "AvailabilityZones", valid_600105
  var valid_600106 = query.getOrDefault("DBClusterIdentifier")
  valid_600106 = validateParameter(valid_600106, JString, required = true,
                                 default = nil)
  if valid_600106 != nil:
    section.add "DBClusterIdentifier", valid_600106
  var valid_600107 = query.getOrDefault("MasterUserPassword")
  valid_600107 = validateParameter(valid_600107, JString, required = true,
                                 default = nil)
  if valid_600107 != nil:
    section.add "MasterUserPassword", valid_600107
  var valid_600108 = query.getOrDefault("VpcSecurityGroupIds")
  valid_600108 = validateParameter(valid_600108, JArray, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "VpcSecurityGroupIds", valid_600108
  var valid_600109 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_600109 = validateParameter(valid_600109, JArray, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "EnableCloudwatchLogsExports", valid_600109
  var valid_600110 = query.getOrDefault("Tags")
  valid_600110 = validateParameter(valid_600110, JArray, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "Tags", valid_600110
  var valid_600111 = query.getOrDefault("BackupRetentionPeriod")
  valid_600111 = validateParameter(valid_600111, JInt, required = false, default = nil)
  if valid_600111 != nil:
    section.add "BackupRetentionPeriod", valid_600111
  var valid_600112 = query.getOrDefault("DeletionProtection")
  valid_600112 = validateParameter(valid_600112, JBool, required = false, default = nil)
  if valid_600112 != nil:
    section.add "DeletionProtection", valid_600112
  var valid_600113 = query.getOrDefault("Action")
  valid_600113 = validateParameter(valid_600113, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_600113 != nil:
    section.add "Action", valid_600113
  var valid_600114 = query.getOrDefault("DBSubnetGroupName")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "DBSubnetGroupName", valid_600114
  var valid_600115 = query.getOrDefault("KmsKeyId")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "KmsKeyId", valid_600115
  var valid_600116 = query.getOrDefault("EngineVersion")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "EngineVersion", valid_600116
  var valid_600117 = query.getOrDefault("Port")
  valid_600117 = validateParameter(valid_600117, JInt, required = false, default = nil)
  if valid_600117 != nil:
    section.add "Port", valid_600117
  var valid_600118 = query.getOrDefault("PreferredBackupWindow")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "PreferredBackupWindow", valid_600118
  var valid_600119 = query.getOrDefault("Version")
  valid_600119 = validateParameter(valid_600119, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600119 != nil:
    section.add "Version", valid_600119
  var valid_600120 = query.getOrDefault("MasterUsername")
  valid_600120 = validateParameter(valid_600120, JString, required = true,
                                 default = nil)
  if valid_600120 != nil:
    section.add "MasterUsername", valid_600120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600121 = header.getOrDefault("X-Amz-Date")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Date", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Security-Token")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Security-Token", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Content-Sha256", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Algorithm")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Algorithm", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Signature")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Signature", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-SignedHeaders", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Credential")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Credential", valid_600127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600128: Call_GetCreateDBCluster_600098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_600128.validator(path, query, header, formData, body)
  let scheme = call_600128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600128.url(scheme.get, call_600128.host, call_600128.base,
                         call_600128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600128, url, valid)

proc call*(call_600129: Call_GetCreateDBCluster_600098; Engine: string;
          DBClusterIdentifier: string; MasterUserPassword: string;
          MasterUsername: string; PreferredMaintenanceWindow: string = "";
          DBClusterParameterGroupName: string = ""; StorageEncrypted: bool = false;
          AvailabilityZones: JsonNode = nil; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          BackupRetentionPeriod: int = 0; DeletionProtection: bool = false;
          Action: string = "CreateDBCluster"; DBSubnetGroupName: string = "";
          KmsKeyId: string = ""; EngineVersion: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBCluster
  ## Creates a new Amazon DocumentDB DB cluster.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this DB cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the DB cluster is encrypted.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this DB cluster.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a DB cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new DB cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted DB cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   Port: int
  ##       : The port number on which the instances in the DB cluster accept connections.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: string (required)
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  var query_600130 = newJObject()
  add(query_600130, "Engine", newJString(Engine))
  add(query_600130, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_600130, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_600130, "StorageEncrypted", newJBool(StorageEncrypted))
  if AvailabilityZones != nil:
    query_600130.add "AvailabilityZones", AvailabilityZones
  add(query_600130, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600130, "MasterUserPassword", newJString(MasterUserPassword))
  if VpcSecurityGroupIds != nil:
    query_600130.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_600130.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_600130.add "Tags", Tags
  add(query_600130, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_600130, "DeletionProtection", newJBool(DeletionProtection))
  add(query_600130, "Action", newJString(Action))
  add(query_600130, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600130, "KmsKeyId", newJString(KmsKeyId))
  add(query_600130, "EngineVersion", newJString(EngineVersion))
  add(query_600130, "Port", newJInt(Port))
  add(query_600130, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_600130, "Version", newJString(Version))
  add(query_600130, "MasterUsername", newJString(MasterUsername))
  result = call_600129.call(nil, query_600130, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_600098(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_600099,
    base: "/", url: url_GetCreateDBCluster_600100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_600184 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBClusterParameterGroup_600186(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBClusterParameterGroup_600185(path: JsonNode;
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
  var valid_600187 = query.getOrDefault("Action")
  valid_600187 = validateParameter(valid_600187, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_600187 != nil:
    section.add "Action", valid_600187
  var valid_600188 = query.getOrDefault("Version")
  valid_600188 = validateParameter(valid_600188, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600188 != nil:
    section.add "Version", valid_600188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600189 = header.getOrDefault("X-Amz-Date")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Date", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Security-Token")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Security-Token", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Content-Sha256", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Algorithm")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Algorithm", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Signature")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Signature", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-SignedHeaders", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Credential")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Credential", valid_600195
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The DB cluster parameter group family name.
  ##   Description: JString (required)
  ##              : The description for the DB cluster parameter group.
  section = newJObject()
  var valid_600196 = formData.getOrDefault("Tags")
  valid_600196 = validateParameter(valid_600196, JArray, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "Tags", valid_600196
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_600197 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_600197 = validateParameter(valid_600197, JString, required = true,
                                 default = nil)
  if valid_600197 != nil:
    section.add "DBClusterParameterGroupName", valid_600197
  var valid_600198 = formData.getOrDefault("DBParameterGroupFamily")
  valid_600198 = validateParameter(valid_600198, JString, required = true,
                                 default = nil)
  if valid_600198 != nil:
    section.add "DBParameterGroupFamily", valid_600198
  var valid_600199 = formData.getOrDefault("Description")
  valid_600199 = validateParameter(valid_600199, JString, required = true,
                                 default = nil)
  if valid_600199 != nil:
    section.add "Description", valid_600199
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600200: Call_PostCreateDBClusterParameterGroup_600184;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_600200.validator(path, query, header, formData, body)
  let scheme = call_600200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600200.url(scheme.get, call_600200.host, call_600200.base,
                         call_600200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600200, url, valid)

proc call*(call_600201: Call_PostCreateDBClusterParameterGroup_600184;
          DBClusterParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterParameterGroup
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   DBParameterGroupFamily: string (required)
  ##                         : The DB cluster parameter group family name.
  ##   Version: string (required)
  ##   Description: string (required)
  ##              : The description for the DB cluster parameter group.
  var query_600202 = newJObject()
  var formData_600203 = newJObject()
  if Tags != nil:
    formData_600203.add "Tags", Tags
  add(query_600202, "Action", newJString(Action))
  add(formData_600203, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_600203, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_600202, "Version", newJString(Version))
  add(formData_600203, "Description", newJString(Description))
  result = call_600201.call(nil, query_600202, nil, formData_600203, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_600184(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_600185, base: "/",
    url: url_PostCreateDBClusterParameterGroup_600186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_600165 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBClusterParameterGroup_600167(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBClusterParameterGroup_600166(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Description: JString (required)
  ##              : The description for the DB cluster parameter group.
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The DB cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_600168 = query.getOrDefault("DBClusterParameterGroupName")
  valid_600168 = validateParameter(valid_600168, JString, required = true,
                                 default = nil)
  if valid_600168 != nil:
    section.add "DBClusterParameterGroupName", valid_600168
  var valid_600169 = query.getOrDefault("Description")
  valid_600169 = validateParameter(valid_600169, JString, required = true,
                                 default = nil)
  if valid_600169 != nil:
    section.add "Description", valid_600169
  var valid_600170 = query.getOrDefault("DBParameterGroupFamily")
  valid_600170 = validateParameter(valid_600170, JString, required = true,
                                 default = nil)
  if valid_600170 != nil:
    section.add "DBParameterGroupFamily", valid_600170
  var valid_600171 = query.getOrDefault("Tags")
  valid_600171 = validateParameter(valid_600171, JArray, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "Tags", valid_600171
  var valid_600172 = query.getOrDefault("Action")
  valid_600172 = validateParameter(valid_600172, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_600172 != nil:
    section.add "Action", valid_600172
  var valid_600173 = query.getOrDefault("Version")
  valid_600173 = validateParameter(valid_600173, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600173 != nil:
    section.add "Version", valid_600173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600174 = header.getOrDefault("X-Amz-Date")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Date", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Security-Token")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Security-Token", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Content-Sha256", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Algorithm")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Algorithm", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Signature")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Signature", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-SignedHeaders", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-Credential")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Credential", valid_600180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_GetCreateDBClusterParameterGroup_600165;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_GetCreateDBClusterParameterGroup_600165;
          DBClusterParameterGroupName: string; Description: string;
          DBParameterGroupFamily: string; Tags: JsonNode = nil;
          Action: string = "CreateDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterParameterGroup
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul> <note> <p>This value is stored as a lowercase string.</p> </note>
  ##   Description: string (required)
  ##              : The description for the DB cluster parameter group.
  ##   DBParameterGroupFamily: string (required)
  ##                         : The DB cluster parameter group family name.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster parameter group.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600183 = newJObject()
  add(query_600183, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_600183, "Description", newJString(Description))
  add(query_600183, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_600183.add "Tags", Tags
  add(query_600183, "Action", newJString(Action))
  add(query_600183, "Version", newJString(Version))
  result = call_600182.call(nil, query_600183, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_600165(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_600166, base: "/",
    url: url_GetCreateDBClusterParameterGroup_600167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_600222 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBClusterSnapshot_600224(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBClusterSnapshot_600223(path: JsonNode; query: JsonNode;
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
  var valid_600225 = query.getOrDefault("Action")
  valid_600225 = validateParameter(valid_600225, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_600225 != nil:
    section.add "Action", valid_600225
  var valid_600226 = query.getOrDefault("Version")
  valid_600226 = validateParameter(valid_600226, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600226 != nil:
    section.add "Version", valid_600226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600227 = header.getOrDefault("X-Amz-Date")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Date", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Security-Token")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Security-Token", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Content-Sha256", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Algorithm")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Algorithm", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Signature")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Signature", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-SignedHeaders", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Credential")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Credential", valid_600233
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
  var valid_600234 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_600234 = validateParameter(valid_600234, JString, required = true,
                                 default = nil)
  if valid_600234 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_600234
  var valid_600235 = formData.getOrDefault("Tags")
  valid_600235 = validateParameter(valid_600235, JArray, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "Tags", valid_600235
  var valid_600236 = formData.getOrDefault("DBClusterIdentifier")
  valid_600236 = validateParameter(valid_600236, JString, required = true,
                                 default = nil)
  if valid_600236 != nil:
    section.add "DBClusterIdentifier", valid_600236
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600237: Call_PostCreateDBClusterSnapshot_600222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_600237.validator(path, query, header, formData, body)
  let scheme = call_600237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600237.url(scheme.get, call_600237.host, call_600237.base,
                         call_600237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600237, url, valid)

proc call*(call_600238: Call_PostCreateDBClusterSnapshot_600222;
          DBClusterSnapshotIdentifier: string; DBClusterIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBClusterSnapshot";
          Version: string = "2014-10-31"): Recallable =
  ## postCreateDBClusterSnapshot
  ## Creates a snapshot of a DB cluster. 
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   Version: string (required)
  var query_600239 = newJObject()
  var formData_600240 = newJObject()
  add(formData_600240, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    formData_600240.add "Tags", Tags
  add(query_600239, "Action", newJString(Action))
  add(formData_600240, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600239, "Version", newJString(Version))
  result = call_600238.call(nil, query_600239, nil, formData_600240, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_600222(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_600223, base: "/",
    url: url_PostCreateDBClusterSnapshot_600224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_600204 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBClusterSnapshot_600206(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBClusterSnapshot_600205(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a snapshot of a DB cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_600207 = query.getOrDefault("DBClusterIdentifier")
  valid_600207 = validateParameter(valid_600207, JString, required = true,
                                 default = nil)
  if valid_600207 != nil:
    section.add "DBClusterIdentifier", valid_600207
  var valid_600208 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_600208 = validateParameter(valid_600208, JString, required = true,
                                 default = nil)
  if valid_600208 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_600208
  var valid_600209 = query.getOrDefault("Tags")
  valid_600209 = validateParameter(valid_600209, JArray, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "Tags", valid_600209
  var valid_600210 = query.getOrDefault("Action")
  valid_600210 = validateParameter(valid_600210, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_600210 != nil:
    section.add "Action", valid_600210
  var valid_600211 = query.getOrDefault("Version")
  valid_600211 = validateParameter(valid_600211, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600211 != nil:
    section.add "Version", valid_600211
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600212 = header.getOrDefault("X-Amz-Date")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Date", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Security-Token")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Security-Token", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Content-Sha256", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Algorithm")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Algorithm", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Signature")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Signature", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-SignedHeaders", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Credential")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Credential", valid_600218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600219: Call_GetCreateDBClusterSnapshot_600204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_600219.validator(path, query, header, formData, body)
  let scheme = call_600219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600219.url(scheme.get, call_600219.host, call_600219.base,
                         call_600219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600219, url, valid)

proc call*(call_600220: Call_GetCreateDBClusterSnapshot_600204;
          DBClusterIdentifier: string; DBClusterSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBClusterSnapshot";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterSnapshot
  ## Creates a snapshot of a DB cluster. 
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the DB cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB cluster snapshot.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600221 = newJObject()
  add(query_600221, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600221, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_600221.add "Tags", Tags
  add(query_600221, "Action", newJString(Action))
  add(query_600221, "Version", newJString(Version))
  result = call_600220.call(nil, query_600221, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_600204(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_600205, base: "/",
    url: url_GetCreateDBClusterSnapshot_600206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_600265 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBInstance_600267(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_600266(path: JsonNode; query: JsonNode;
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
  var valid_600268 = query.getOrDefault("Action")
  valid_600268 = validateParameter(valid_600268, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_600268 != nil:
    section.add "Action", valid_600268
  var valid_600269 = query.getOrDefault("Version")
  valid_600269 = validateParameter(valid_600269, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600269 != nil:
    section.add "Version", valid_600269
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600270 = header.getOrDefault("X-Amz-Date")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Date", valid_600270
  var valid_600271 = header.getOrDefault("X-Amz-Security-Token")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-Security-Token", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Content-Sha256", valid_600272
  var valid_600273 = header.getOrDefault("X-Amz-Algorithm")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Algorithm", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Signature")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Signature", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-SignedHeaders", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Credential")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Credential", valid_600276
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_600277 = formData.getOrDefault("Engine")
  valid_600277 = validateParameter(valid_600277, JString, required = true,
                                 default = nil)
  if valid_600277 != nil:
    section.add "Engine", valid_600277
  var valid_600278 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600278 = validateParameter(valid_600278, JString, required = true,
                                 default = nil)
  if valid_600278 != nil:
    section.add "DBInstanceIdentifier", valid_600278
  var valid_600279 = formData.getOrDefault("Tags")
  valid_600279 = validateParameter(valid_600279, JArray, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "Tags", valid_600279
  var valid_600280 = formData.getOrDefault("AvailabilityZone")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "AvailabilityZone", valid_600280
  var valid_600281 = formData.getOrDefault("PromotionTier")
  valid_600281 = validateParameter(valid_600281, JInt, required = false, default = nil)
  if valid_600281 != nil:
    section.add "PromotionTier", valid_600281
  var valid_600282 = formData.getOrDefault("DBInstanceClass")
  valid_600282 = validateParameter(valid_600282, JString, required = true,
                                 default = nil)
  if valid_600282 != nil:
    section.add "DBInstanceClass", valid_600282
  var valid_600283 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_600283 = validateParameter(valid_600283, JBool, required = false, default = nil)
  if valid_600283 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600283
  var valid_600284 = formData.getOrDefault("DBClusterIdentifier")
  valid_600284 = validateParameter(valid_600284, JString, required = true,
                                 default = nil)
  if valid_600284 != nil:
    section.add "DBClusterIdentifier", valid_600284
  var valid_600285 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "PreferredMaintenanceWindow", valid_600285
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_PostCreateDBInstance_600265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_PostCreateDBInstance_600265; Engine: string;
          DBInstanceIdentifier: string; DBInstanceClass: string;
          DBClusterIdentifier: string; Tags: JsonNode = nil;
          AvailabilityZone: string = ""; Action: string = "CreateDBInstance";
          PromotionTier: int = 0; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postCreateDBInstance
  ## Creates a new DB instance.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Action: string (required)
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_600288 = newJObject()
  var formData_600289 = newJObject()
  add(formData_600289, "Engine", newJString(Engine))
  add(formData_600289, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_600289.add "Tags", Tags
  add(formData_600289, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600288, "Action", newJString(Action))
  add(formData_600289, "PromotionTier", newJInt(PromotionTier))
  add(formData_600289, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_600289, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_600289, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600288, "Version", newJString(Version))
  add(formData_600289, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_600287.call(nil, query_600288, nil, formData_600289, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_600265(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_600266, base: "/",
    url: url_PostCreateDBInstance_600267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_600241 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBInstance_600243(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_600242(path: JsonNode; query: JsonNode;
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
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   Action: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_600244 = query.getOrDefault("Engine")
  valid_600244 = validateParameter(valid_600244, JString, required = true,
                                 default = nil)
  if valid_600244 != nil:
    section.add "Engine", valid_600244
  var valid_600245 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "PreferredMaintenanceWindow", valid_600245
  var valid_600246 = query.getOrDefault("PromotionTier")
  valid_600246 = validateParameter(valid_600246, JInt, required = false, default = nil)
  if valid_600246 != nil:
    section.add "PromotionTier", valid_600246
  var valid_600247 = query.getOrDefault("DBClusterIdentifier")
  valid_600247 = validateParameter(valid_600247, JString, required = true,
                                 default = nil)
  if valid_600247 != nil:
    section.add "DBClusterIdentifier", valid_600247
  var valid_600248 = query.getOrDefault("AvailabilityZone")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "AvailabilityZone", valid_600248
  var valid_600249 = query.getOrDefault("Tags")
  valid_600249 = validateParameter(valid_600249, JArray, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "Tags", valid_600249
  var valid_600250 = query.getOrDefault("DBInstanceClass")
  valid_600250 = validateParameter(valid_600250, JString, required = true,
                                 default = nil)
  if valid_600250 != nil:
    section.add "DBInstanceClass", valid_600250
  var valid_600251 = query.getOrDefault("Action")
  valid_600251 = validateParameter(valid_600251, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_600251 != nil:
    section.add "Action", valid_600251
  var valid_600252 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_600252 = validateParameter(valid_600252, JBool, required = false, default = nil)
  if valid_600252 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600252
  var valid_600253 = query.getOrDefault("Version")
  valid_600253 = validateParameter(valid_600253, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600253 != nil:
    section.add "Version", valid_600253
  var valid_600254 = query.getOrDefault("DBInstanceIdentifier")
  valid_600254 = validateParameter(valid_600254, JString, required = true,
                                 default = nil)
  if valid_600254 != nil:
    section.add "DBInstanceIdentifier", valid_600254
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600255 = header.getOrDefault("X-Amz-Date")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Date", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Security-Token")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Security-Token", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Content-Sha256", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Algorithm")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Algorithm", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Signature")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Signature", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-SignedHeaders", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Credential")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Credential", valid_600261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600262: Call_GetCreateDBInstance_600241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_600262.validator(path, query, header, formData, body)
  let scheme = call_600262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600262.url(scheme.get, call_600262.host, call_600262.base,
                         call_600262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600262, url, valid)

proc call*(call_600263: Call_GetCreateDBInstance_600241; Engine: string;
          DBClusterIdentifier: string; DBInstanceClass: string;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          PromotionTier: int = 0; AvailabilityZone: string = ""; Tags: JsonNode = nil;
          Action: string = "CreateDBInstance";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBInstance
  ## Creates a new DB instance.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the DB cluster that the instance will belong to.
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the DB instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance. You can assign up to 10 tags to an instance.
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   Action: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  var query_600264 = newJObject()
  add(query_600264, "Engine", newJString(Engine))
  add(query_600264, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_600264, "PromotionTier", newJInt(PromotionTier))
  add(query_600264, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600264, "AvailabilityZone", newJString(AvailabilityZone))
  if Tags != nil:
    query_600264.add "Tags", Tags
  add(query_600264, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_600264, "Action", newJString(Action))
  add(query_600264, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_600264, "Version", newJString(Version))
  add(query_600264, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600263.call(nil, query_600264, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_600241(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_600242, base: "/",
    url: url_GetCreateDBInstance_600243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_600309 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSubnetGroup_600311(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_600310(path: JsonNode; query: JsonNode;
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
  var valid_600312 = query.getOrDefault("Action")
  valid_600312 = validateParameter(valid_600312, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_600312 != nil:
    section.add "Action", valid_600312
  var valid_600313 = query.getOrDefault("Version")
  valid_600313 = validateParameter(valid_600313, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600313 != nil:
    section.add "Version", valid_600313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600314 = header.getOrDefault("X-Amz-Date")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Date", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Security-Token")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Security-Token", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Content-Sha256", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Algorithm")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Algorithm", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-Signature")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Signature", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-SignedHeaders", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Credential")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Credential", valid_600320
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the DB subnet group.
  section = newJObject()
  var valid_600321 = formData.getOrDefault("Tags")
  valid_600321 = validateParameter(valid_600321, JArray, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "Tags", valid_600321
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_600322 = formData.getOrDefault("DBSubnetGroupName")
  valid_600322 = validateParameter(valid_600322, JString, required = true,
                                 default = nil)
  if valid_600322 != nil:
    section.add "DBSubnetGroupName", valid_600322
  var valid_600323 = formData.getOrDefault("SubnetIds")
  valid_600323 = validateParameter(valid_600323, JArray, required = true, default = nil)
  if valid_600323 != nil:
    section.add "SubnetIds", valid_600323
  var valid_600324 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_600324 = validateParameter(valid_600324, JString, required = true,
                                 default = nil)
  if valid_600324 != nil:
    section.add "DBSubnetGroupDescription", valid_600324
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600325: Call_PostCreateDBSubnetGroup_600309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_600325.validator(path, query, header, formData, body)
  let scheme = call_600325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600325.url(scheme.get, call_600325.host, call_600325.base,
                         call_600325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600325, url, valid)

proc call*(call_600326: Call_PostCreateDBSubnetGroup_600309;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-10-31"): Recallable =
  ## postCreateDBSubnetGroup
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the DB subnet group.
  ##   Version: string (required)
  var query_600327 = newJObject()
  var formData_600328 = newJObject()
  if Tags != nil:
    formData_600328.add "Tags", Tags
  add(formData_600328, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_600328.add "SubnetIds", SubnetIds
  add(query_600327, "Action", newJString(Action))
  add(formData_600328, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_600327, "Version", newJString(Version))
  result = call_600326.call(nil, query_600327, nil, formData_600328, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_600309(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_600310, base: "/",
    url: url_PostCreateDBSubnetGroup_600311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_600290 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSubnetGroup_600292(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_600291(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the DB subnet group.
  ##   Version: JString (required)
  section = newJObject()
  var valid_600293 = query.getOrDefault("Tags")
  valid_600293 = validateParameter(valid_600293, JArray, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "Tags", valid_600293
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600294 = query.getOrDefault("Action")
  valid_600294 = validateParameter(valid_600294, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_600294 != nil:
    section.add "Action", valid_600294
  var valid_600295 = query.getOrDefault("DBSubnetGroupName")
  valid_600295 = validateParameter(valid_600295, JString, required = true,
                                 default = nil)
  if valid_600295 != nil:
    section.add "DBSubnetGroupName", valid_600295
  var valid_600296 = query.getOrDefault("SubnetIds")
  valid_600296 = validateParameter(valid_600296, JArray, required = true, default = nil)
  if valid_600296 != nil:
    section.add "SubnetIds", valid_600296
  var valid_600297 = query.getOrDefault("DBSubnetGroupDescription")
  valid_600297 = validateParameter(valid_600297, JString, required = true,
                                 default = nil)
  if valid_600297 != nil:
    section.add "DBSubnetGroupDescription", valid_600297
  var valid_600298 = query.getOrDefault("Version")
  valid_600298 = validateParameter(valid_600298, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600298 != nil:
    section.add "Version", valid_600298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600299 = header.getOrDefault("X-Amz-Date")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Date", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Security-Token")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Security-Token", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Content-Sha256", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Algorithm")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Algorithm", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Signature")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Signature", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-SignedHeaders", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Credential")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Credential", valid_600305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600306: Call_GetCreateDBSubnetGroup_600290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_600306.validator(path, query, header, formData, body)
  let scheme = call_600306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600306.url(scheme.get, call_600306.host, call_600306.base,
                         call_600306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600306, url, valid)

proc call*(call_600307: Call_GetCreateDBSubnetGroup_600290;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBSubnetGroup
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the DB subnet group.
  ##   Version: string (required)
  var query_600308 = newJObject()
  if Tags != nil:
    query_600308.add "Tags", Tags
  add(query_600308, "Action", newJString(Action))
  add(query_600308, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_600308.add "SubnetIds", SubnetIds
  add(query_600308, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_600308, "Version", newJString(Version))
  result = call_600307.call(nil, query_600308, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_600290(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_600291, base: "/",
    url: url_GetCreateDBSubnetGroup_600292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_600347 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBCluster_600349(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBCluster_600348(path: JsonNode; query: JsonNode;
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
  var valid_600350 = query.getOrDefault("Action")
  valid_600350 = validateParameter(valid_600350, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_600350 != nil:
    section.add "Action", valid_600350
  var valid_600351 = query.getOrDefault("Version")
  valid_600351 = validateParameter(valid_600351, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600351 != nil:
    section.add "Version", valid_600351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600352 = header.getOrDefault("X-Amz-Date")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Date", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Security-Token")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Security-Token", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Content-Sha256", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Algorithm")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Algorithm", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Signature")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Signature", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-SignedHeaders", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Credential")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Credential", valid_600358
  result.add "header", section
  ## parameters in `formData` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_600359 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_600359
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_600360 = formData.getOrDefault("DBClusterIdentifier")
  valid_600360 = validateParameter(valid_600360, JString, required = true,
                                 default = nil)
  if valid_600360 != nil:
    section.add "DBClusterIdentifier", valid_600360
  var valid_600361 = formData.getOrDefault("SkipFinalSnapshot")
  valid_600361 = validateParameter(valid_600361, JBool, required = false, default = nil)
  if valid_600361 != nil:
    section.add "SkipFinalSnapshot", valid_600361
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600362: Call_PostDeleteDBCluster_600347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_600362.validator(path, query, header, formData, body)
  let scheme = call_600362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600362.url(scheme.get, call_600362.host, call_600362.base,
                         call_600362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600362, url, valid)

proc call*(call_600363: Call_PostDeleteDBCluster_600347;
          DBClusterIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBCluster"; Version: string = "2014-10-31";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBCluster
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  var query_600364 = newJObject()
  var formData_600365 = newJObject()
  add(formData_600365, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_600364, "Action", newJString(Action))
  add(formData_600365, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600364, "Version", newJString(Version))
  add(formData_600365, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_600363.call(nil, query_600364, nil, formData_600365, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_600347(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_600348, base: "/",
    url: url_PostDeleteDBCluster_600349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_600329 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBCluster_600331(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBCluster_600330(path: JsonNode; query: JsonNode;
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
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Action: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_600332 = query.getOrDefault("DBClusterIdentifier")
  valid_600332 = validateParameter(valid_600332, JString, required = true,
                                 default = nil)
  if valid_600332 != nil:
    section.add "DBClusterIdentifier", valid_600332
  var valid_600333 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_600333
  var valid_600334 = query.getOrDefault("Action")
  valid_600334 = validateParameter(valid_600334, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_600334 != nil:
    section.add "Action", valid_600334
  var valid_600335 = query.getOrDefault("SkipFinalSnapshot")
  valid_600335 = validateParameter(valid_600335, JBool, required = false, default = nil)
  if valid_600335 != nil:
    section.add "SkipFinalSnapshot", valid_600335
  var valid_600336 = query.getOrDefault("Version")
  valid_600336 = validateParameter(valid_600336, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600336 != nil:
    section.add "Version", valid_600336
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600337 = header.getOrDefault("X-Amz-Date")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Date", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Security-Token")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Security-Token", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Content-Sha256", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Algorithm")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Algorithm", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Signature")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Signature", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-SignedHeaders", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Credential")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Credential", valid_600343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600344: Call_GetDeleteDBCluster_600329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_600344.validator(path, query, header, formData, body)
  let scheme = call_600344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600344.url(scheme.get, call_600344.host, call_600344.base,
                         call_600344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600344, url, valid)

proc call*(call_600345: Call_GetDeleteDBCluster_600329;
          DBClusterIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBCluster"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBCluster
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   FinalDBSnapshotIdentifier: string
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   Version: string (required)
  var query_600346 = newJObject()
  add(query_600346, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600346, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_600346, "Action", newJString(Action))
  add(query_600346, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_600346, "Version", newJString(Version))
  result = call_600345.call(nil, query_600346, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_600329(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_600330,
    base: "/", url: url_GetDeleteDBCluster_600331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_600382 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBClusterParameterGroup_600384(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBClusterParameterGroup_600383(path: JsonNode;
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
  var valid_600385 = query.getOrDefault("Action")
  valid_600385 = validateParameter(valid_600385, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_600385 != nil:
    section.add "Action", valid_600385
  var valid_600386 = query.getOrDefault("Version")
  valid_600386 = validateParameter(valid_600386, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600386 != nil:
    section.add "Version", valid_600386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600387 = header.getOrDefault("X-Amz-Date")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Date", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Security-Token")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Security-Token", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Content-Sha256", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Algorithm")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Algorithm", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Signature")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Signature", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-SignedHeaders", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Credential")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Credential", valid_600393
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_600394 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_600394 = validateParameter(valid_600394, JString, required = true,
                                 default = nil)
  if valid_600394 != nil:
    section.add "DBClusterParameterGroupName", valid_600394
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600395: Call_PostDeleteDBClusterParameterGroup_600382;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_600395.validator(path, query, header, formData, body)
  let scheme = call_600395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600395.url(scheme.get, call_600395.host, call_600395.base,
                         call_600395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600395, url, valid)

proc call*(call_600396: Call_PostDeleteDBClusterParameterGroup_600382;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_600397 = newJObject()
  var formData_600398 = newJObject()
  add(query_600397, "Action", newJString(Action))
  add(formData_600398, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_600397, "Version", newJString(Version))
  result = call_600396.call(nil, query_600397, nil, formData_600398, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_600382(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_600383, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_600384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_600366 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBClusterParameterGroup_600368(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBClusterParameterGroup_600367(path: JsonNode;
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
  var valid_600369 = query.getOrDefault("DBClusterParameterGroupName")
  valid_600369 = validateParameter(valid_600369, JString, required = true,
                                 default = nil)
  if valid_600369 != nil:
    section.add "DBClusterParameterGroupName", valid_600369
  var valid_600370 = query.getOrDefault("Action")
  valid_600370 = validateParameter(valid_600370, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_600370 != nil:
    section.add "Action", valid_600370
  var valid_600371 = query.getOrDefault("Version")
  valid_600371 = validateParameter(valid_600371, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600371 != nil:
    section.add "Version", valid_600371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600372 = header.getOrDefault("X-Amz-Date")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Date", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Security-Token")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Security-Token", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Content-Sha256", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Algorithm")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Algorithm", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Signature")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Signature", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-SignedHeaders", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Credential")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Credential", valid_600378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600379: Call_GetDeleteDBClusterParameterGroup_600366;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_600379.validator(path, query, header, formData, body)
  let scheme = call_600379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600379.url(scheme.get, call_600379.host, call_600379.base,
                         call_600379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600379, url, valid)

proc call*(call_600380: Call_GetDeleteDBClusterParameterGroup_600366;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600381 = newJObject()
  add(query_600381, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_600381, "Action", newJString(Action))
  add(query_600381, "Version", newJString(Version))
  result = call_600380.call(nil, query_600381, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_600366(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_600367, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_600368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_600415 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBClusterSnapshot_600417(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBClusterSnapshot_600416(path: JsonNode; query: JsonNode;
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
  var valid_600418 = query.getOrDefault("Action")
  valid_600418 = validateParameter(valid_600418, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_600418 != nil:
    section.add "Action", valid_600418
  var valid_600419 = query.getOrDefault("Version")
  valid_600419 = validateParameter(valid_600419, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600419 != nil:
    section.add "Version", valid_600419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600420 = header.getOrDefault("X-Amz-Date")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Date", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Security-Token")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Security-Token", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Content-Sha256", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Algorithm")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Algorithm", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-Signature")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-Signature", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-SignedHeaders", valid_600425
  var valid_600426 = header.getOrDefault("X-Amz-Credential")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-Credential", valid_600426
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_600427 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_600427 = validateParameter(valid_600427, JString, required = true,
                                 default = nil)
  if valid_600427 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_600427
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600428: Call_PostDeleteDBClusterSnapshot_600415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_600428.validator(path, query, header, formData, body)
  let scheme = call_600428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600428.url(scheme.get, call_600428.host, call_600428.base,
                         call_600428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600428, url, valid)

proc call*(call_600429: Call_PostDeleteDBClusterSnapshot_600415;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600430 = newJObject()
  var formData_600431 = newJObject()
  add(formData_600431, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_600430, "Action", newJString(Action))
  add(query_600430, "Version", newJString(Version))
  result = call_600429.call(nil, query_600430, nil, formData_600431, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_600415(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_600416, base: "/",
    url: url_PostDeleteDBClusterSnapshot_600417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_600399 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBClusterSnapshot_600401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBClusterSnapshot_600400(path: JsonNode; query: JsonNode;
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
  var valid_600402 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_600402 = validateParameter(valid_600402, JString, required = true,
                                 default = nil)
  if valid_600402 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_600402
  var valid_600403 = query.getOrDefault("Action")
  valid_600403 = validateParameter(valid_600403, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_600403 != nil:
    section.add "Action", valid_600403
  var valid_600404 = query.getOrDefault("Version")
  valid_600404 = validateParameter(valid_600404, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600404 != nil:
    section.add "Version", valid_600404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600405 = header.getOrDefault("X-Amz-Date")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Date", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Security-Token")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Security-Token", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-Content-Sha256", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Algorithm")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Algorithm", valid_600408
  var valid_600409 = header.getOrDefault("X-Amz-Signature")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-Signature", valid_600409
  var valid_600410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-SignedHeaders", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-Credential")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Credential", valid_600411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600412: Call_GetDeleteDBClusterSnapshot_600399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_600412.validator(path, query, header, formData, body)
  let scheme = call_600412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600412.url(scheme.get, call_600412.host, call_600412.base,
                         call_600412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600412, url, valid)

proc call*(call_600413: Call_GetDeleteDBClusterSnapshot_600399;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600414 = newJObject()
  add(query_600414, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_600414, "Action", newJString(Action))
  add(query_600414, "Version", newJString(Version))
  result = call_600413.call(nil, query_600414, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_600399(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_600400, base: "/",
    url: url_GetDeleteDBClusterSnapshot_600401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_600448 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBInstance_600450(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_600449(path: JsonNode; query: JsonNode;
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
  var valid_600451 = query.getOrDefault("Action")
  valid_600451 = validateParameter(valid_600451, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_600451 != nil:
    section.add "Action", valid_600451
  var valid_600452 = query.getOrDefault("Version")
  valid_600452 = validateParameter(valid_600452, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600452 != nil:
    section.add "Version", valid_600452
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600453 = header.getOrDefault("X-Amz-Date")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Date", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Security-Token")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Security-Token", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Content-Sha256", valid_600455
  var valid_600456 = header.getOrDefault("X-Amz-Algorithm")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-Algorithm", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-Signature")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Signature", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-SignedHeaders", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Credential")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Credential", valid_600459
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600460 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600460 = validateParameter(valid_600460, JString, required = true,
                                 default = nil)
  if valid_600460 != nil:
    section.add "DBInstanceIdentifier", valid_600460
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600461: Call_PostDeleteDBInstance_600448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_600461.validator(path, query, header, formData, body)
  let scheme = call_600461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600461.url(scheme.get, call_600461.host, call_600461.base,
                         call_600461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600461, url, valid)

proc call*(call_600462: Call_PostDeleteDBInstance_600448;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600463 = newJObject()
  var formData_600464 = newJObject()
  add(formData_600464, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_600463, "Action", newJString(Action))
  add(query_600463, "Version", newJString(Version))
  result = call_600462.call(nil, query_600463, nil, formData_600464, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_600448(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_600449, base: "/",
    url: url_PostDeleteDBInstance_600450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_600432 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBInstance_600434(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_600433(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a previously provisioned DB instance. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600435 = query.getOrDefault("Action")
  valid_600435 = validateParameter(valid_600435, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_600435 != nil:
    section.add "Action", valid_600435
  var valid_600436 = query.getOrDefault("Version")
  valid_600436 = validateParameter(valid_600436, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600436 != nil:
    section.add "Version", valid_600436
  var valid_600437 = query.getOrDefault("DBInstanceIdentifier")
  valid_600437 = validateParameter(valid_600437, JString, required = true,
                                 default = nil)
  if valid_600437 != nil:
    section.add "DBInstanceIdentifier", valid_600437
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600438 = header.getOrDefault("X-Amz-Date")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Date", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Security-Token")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Security-Token", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Content-Sha256", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Algorithm")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Algorithm", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-Signature")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Signature", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-SignedHeaders", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Credential")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Credential", valid_600444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600445: Call_GetDeleteDBInstance_600432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_600445.validator(path, query, header, formData, body)
  let scheme = call_600445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600445.url(scheme.get, call_600445.host, call_600445.base,
                         call_600445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600445, url, valid)

proc call*(call_600446: Call_GetDeleteDBInstance_600432;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  var query_600447 = newJObject()
  add(query_600447, "Action", newJString(Action))
  add(query_600447, "Version", newJString(Version))
  add(query_600447, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600446.call(nil, query_600447, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_600432(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_600433, base: "/",
    url: url_GetDeleteDBInstance_600434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_600481 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSubnetGroup_600483(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_600482(path: JsonNode; query: JsonNode;
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
  var valid_600484 = query.getOrDefault("Action")
  valid_600484 = validateParameter(valid_600484, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_600484 != nil:
    section.add "Action", valid_600484
  var valid_600485 = query.getOrDefault("Version")
  valid_600485 = validateParameter(valid_600485, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600485 != nil:
    section.add "Version", valid_600485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600486 = header.getOrDefault("X-Amz-Date")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Date", valid_600486
  var valid_600487 = header.getOrDefault("X-Amz-Security-Token")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Security-Token", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Content-Sha256", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Algorithm")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Algorithm", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Signature")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Signature", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-SignedHeaders", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Credential")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Credential", valid_600492
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_600493 = formData.getOrDefault("DBSubnetGroupName")
  valid_600493 = validateParameter(valid_600493, JString, required = true,
                                 default = nil)
  if valid_600493 != nil:
    section.add "DBSubnetGroupName", valid_600493
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600494: Call_PostDeleteDBSubnetGroup_600481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_600494.validator(path, query, header, formData, body)
  let scheme = call_600494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600494.url(scheme.get, call_600494.host, call_600494.base,
                         call_600494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600494, url, valid)

proc call*(call_600495: Call_PostDeleteDBSubnetGroup_600481;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600496 = newJObject()
  var formData_600497 = newJObject()
  add(formData_600497, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600496, "Action", newJString(Action))
  add(query_600496, "Version", newJString(Version))
  result = call_600495.call(nil, query_600496, nil, formData_600497, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_600481(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_600482, base: "/",
    url: url_PostDeleteDBSubnetGroup_600483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_600465 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSubnetGroup_600467(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_600466(path: JsonNode; query: JsonNode;
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
  var valid_600468 = query.getOrDefault("Action")
  valid_600468 = validateParameter(valid_600468, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_600468 != nil:
    section.add "Action", valid_600468
  var valid_600469 = query.getOrDefault("DBSubnetGroupName")
  valid_600469 = validateParameter(valid_600469, JString, required = true,
                                 default = nil)
  if valid_600469 != nil:
    section.add "DBSubnetGroupName", valid_600469
  var valid_600470 = query.getOrDefault("Version")
  valid_600470 = validateParameter(valid_600470, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600470 != nil:
    section.add "Version", valid_600470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600471 = header.getOrDefault("X-Amz-Date")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Date", valid_600471
  var valid_600472 = header.getOrDefault("X-Amz-Security-Token")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Security-Token", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Content-Sha256", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Algorithm")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Algorithm", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Signature")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Signature", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-SignedHeaders", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Credential")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Credential", valid_600477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600478: Call_GetDeleteDBSubnetGroup_600465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_600478.validator(path, query, header, formData, body)
  let scheme = call_600478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600478.url(scheme.get, call_600478.host, call_600478.base,
                         call_600478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600478, url, valid)

proc call*(call_600479: Call_GetDeleteDBSubnetGroup_600465;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_600480 = newJObject()
  add(query_600480, "Action", newJString(Action))
  add(query_600480, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600480, "Version", newJString(Version))
  result = call_600479.call(nil, query_600480, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_600465(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_600466, base: "/",
    url: url_GetDeleteDBSubnetGroup_600467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeCertificates_600517 = ref object of OpenApiRestCall_599352
proc url_PostDescribeCertificates_600519(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeCertificates_600518(path: JsonNode; query: JsonNode;
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
  var valid_600520 = query.getOrDefault("Action")
  valid_600520 = validateParameter(valid_600520, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_600520 != nil:
    section.add "Action", valid_600520
  var valid_600521 = query.getOrDefault("Version")
  valid_600521 = validateParameter(valid_600521, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600521 != nil:
    section.add "Version", valid_600521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600522 = header.getOrDefault("X-Amz-Date")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Date", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Security-Token")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Security-Token", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Content-Sha256", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Algorithm")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Algorithm", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Signature")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Signature", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-SignedHeaders", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Credential")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Credential", valid_600528
  result.add "header", section
  ## parameters in `formData` object:
  ##   CertificateIdentifier: JString
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  section = newJObject()
  var valid_600529 = formData.getOrDefault("CertificateIdentifier")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "CertificateIdentifier", valid_600529
  var valid_600530 = formData.getOrDefault("Marker")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "Marker", valid_600530
  var valid_600531 = formData.getOrDefault("Filters")
  valid_600531 = validateParameter(valid_600531, JArray, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "Filters", valid_600531
  var valid_600532 = formData.getOrDefault("MaxRecords")
  valid_600532 = validateParameter(valid_600532, JInt, required = false, default = nil)
  if valid_600532 != nil:
    section.add "MaxRecords", valid_600532
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600533: Call_PostDescribeCertificates_600517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_600533.validator(path, query, header, formData, body)
  let scheme = call_600533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600533.url(scheme.get, call_600533.host, call_600533.base,
                         call_600533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600533, url, valid)

proc call*(call_600534: Call_PostDescribeCertificates_600517;
          CertificateIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeCertificates"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ##   CertificateIdentifier: string
  ##                        : <p>The user-supplied certificate identifier. If this parameter is specified, information for only the specified certificate is returned. If this parameter is omitted, a list of up to <code>MaxRecords</code> certificates is returned. This parameter is not case sensitive.</p> <p>Constraints</p> <ul> <li> <p>Must match an existing <code>CertificateIdentifier</code>.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous <code>DescribeCertificates</code> request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p>The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token called a marker is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints:</p> <ul> <li> <p>Minimum: 20</p> </li> <li> <p>Maximum: 100</p> </li> </ul>
  ##   Version: string (required)
  var query_600535 = newJObject()
  var formData_600536 = newJObject()
  add(formData_600536, "CertificateIdentifier", newJString(CertificateIdentifier))
  add(formData_600536, "Marker", newJString(Marker))
  add(query_600535, "Action", newJString(Action))
  if Filters != nil:
    formData_600536.add "Filters", Filters
  add(formData_600536, "MaxRecords", newJInt(MaxRecords))
  add(query_600535, "Version", newJString(Version))
  result = call_600534.call(nil, query_600535, nil, formData_600536, nil)

var postDescribeCertificates* = Call_PostDescribeCertificates_600517(
    name: "postDescribeCertificates", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_PostDescribeCertificates_600518, base: "/",
    url: url_PostDescribeCertificates_600519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeCertificates_600498 = ref object of OpenApiRestCall_599352
proc url_GetDescribeCertificates_600500(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeCertificates_600499(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
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
  var valid_600501 = query.getOrDefault("MaxRecords")
  valid_600501 = validateParameter(valid_600501, JInt, required = false, default = nil)
  if valid_600501 != nil:
    section.add "MaxRecords", valid_600501
  var valid_600502 = query.getOrDefault("CertificateIdentifier")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "CertificateIdentifier", valid_600502
  var valid_600503 = query.getOrDefault("Filters")
  valid_600503 = validateParameter(valid_600503, JArray, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "Filters", valid_600503
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600504 = query.getOrDefault("Action")
  valid_600504 = validateParameter(valid_600504, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_600504 != nil:
    section.add "Action", valid_600504
  var valid_600505 = query.getOrDefault("Marker")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "Marker", valid_600505
  var valid_600506 = query.getOrDefault("Version")
  valid_600506 = validateParameter(valid_600506, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600506 != nil:
    section.add "Version", valid_600506
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600507 = header.getOrDefault("X-Amz-Date")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Date", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Security-Token")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Security-Token", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Content-Sha256", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Algorithm")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Algorithm", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Signature")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Signature", valid_600511
  var valid_600512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-SignedHeaders", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-Credential")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Credential", valid_600513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600514: Call_GetDescribeCertificates_600498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_600514.validator(path, query, header, formData, body)
  let scheme = call_600514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600514.url(scheme.get, call_600514.host, call_600514.base,
                         call_600514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600514, url, valid)

proc call*(call_600515: Call_GetDescribeCertificates_600498; MaxRecords: int = 0;
          CertificateIdentifier: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeCertificates"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
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
  var query_600516 = newJObject()
  add(query_600516, "MaxRecords", newJInt(MaxRecords))
  add(query_600516, "CertificateIdentifier", newJString(CertificateIdentifier))
  if Filters != nil:
    query_600516.add "Filters", Filters
  add(query_600516, "Action", newJString(Action))
  add(query_600516, "Marker", newJString(Marker))
  add(query_600516, "Version", newJString(Version))
  result = call_600515.call(nil, query_600516, nil, nil, nil)

var getDescribeCertificates* = Call_GetDescribeCertificates_600498(
    name: "getDescribeCertificates", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_GetDescribeCertificates_600499, base: "/",
    url: url_GetDescribeCertificates_600500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_600556 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBClusterParameterGroups_600558(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterParameterGroups_600557(path: JsonNode;
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
  var valid_600559 = query.getOrDefault("Action")
  valid_600559 = validateParameter(valid_600559, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_600559 != nil:
    section.add "Action", valid_600559
  var valid_600560 = query.getOrDefault("Version")
  valid_600560 = validateParameter(valid_600560, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600560 != nil:
    section.add "Version", valid_600560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600561 = header.getOrDefault("X-Amz-Date")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Date", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-Security-Token")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Security-Token", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Content-Sha256", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-Algorithm")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Algorithm", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Signature")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Signature", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-SignedHeaders", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Credential")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Credential", valid_600567
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_600568 = formData.getOrDefault("Marker")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "Marker", valid_600568
  var valid_600569 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "DBClusterParameterGroupName", valid_600569
  var valid_600570 = formData.getOrDefault("Filters")
  valid_600570 = validateParameter(valid_600570, JArray, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "Filters", valid_600570
  var valid_600571 = formData.getOrDefault("MaxRecords")
  valid_600571 = validateParameter(valid_600571, JInt, required = false, default = nil)
  if valid_600571 != nil:
    section.add "MaxRecords", valid_600571
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600572: Call_PostDescribeDBClusterParameterGroups_600556;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_600572.validator(path, query, header, formData, body)
  let scheme = call_600572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600572.url(scheme.get, call_600572.host, call_600572.base,
                         call_600572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600572, url, valid)

proc call*(call_600573: Call_PostDescribeDBClusterParameterGroups_600556;
          Marker: string = ""; Action: string = "DescribeDBClusterParameterGroups";
          DBClusterParameterGroupName: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_600574 = newJObject()
  var formData_600575 = newJObject()
  add(formData_600575, "Marker", newJString(Marker))
  add(query_600574, "Action", newJString(Action))
  add(formData_600575, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_600575.add "Filters", Filters
  add(formData_600575, "MaxRecords", newJInt(MaxRecords))
  add(query_600574, "Version", newJString(Version))
  result = call_600573.call(nil, query_600574, nil, formData_600575, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_600556(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_600557, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_600558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_600537 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBClusterParameterGroups_600539(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterParameterGroups_600538(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_600540 = query.getOrDefault("MaxRecords")
  valid_600540 = validateParameter(valid_600540, JInt, required = false, default = nil)
  if valid_600540 != nil:
    section.add "MaxRecords", valid_600540
  var valid_600541 = query.getOrDefault("DBClusterParameterGroupName")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "DBClusterParameterGroupName", valid_600541
  var valid_600542 = query.getOrDefault("Filters")
  valid_600542 = validateParameter(valid_600542, JArray, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "Filters", valid_600542
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600543 = query.getOrDefault("Action")
  valid_600543 = validateParameter(valid_600543, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_600543 != nil:
    section.add "Action", valid_600543
  var valid_600544 = query.getOrDefault("Marker")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "Marker", valid_600544
  var valid_600545 = query.getOrDefault("Version")
  valid_600545 = validateParameter(valid_600545, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600545 != nil:
    section.add "Version", valid_600545
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600546 = header.getOrDefault("X-Amz-Date")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Date", valid_600546
  var valid_600547 = header.getOrDefault("X-Amz-Security-Token")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-Security-Token", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Content-Sha256", valid_600548
  var valid_600549 = header.getOrDefault("X-Amz-Algorithm")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = nil)
  if valid_600549 != nil:
    section.add "X-Amz-Algorithm", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-Signature")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Signature", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-SignedHeaders", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Credential")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Credential", valid_600552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600553: Call_GetDescribeDBClusterParameterGroups_600537;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_600553.validator(path, query, header, formData, body)
  let scheme = call_600553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600553.url(scheme.get, call_600553.host, call_600553.base,
                         call_600553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600553, url, valid)

proc call*(call_600554: Call_GetDescribeDBClusterParameterGroups_600537;
          MaxRecords: int = 0; DBClusterParameterGroupName: string = "";
          Filters: JsonNode = nil;
          Action: string = "DescribeDBClusterParameterGroups"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific DB cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_600555 = newJObject()
  add(query_600555, "MaxRecords", newJInt(MaxRecords))
  add(query_600555, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_600555.add "Filters", Filters
  add(query_600555, "Action", newJString(Action))
  add(query_600555, "Marker", newJString(Marker))
  add(query_600555, "Version", newJString(Version))
  result = call_600554.call(nil, query_600555, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_600537(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_600538, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_600539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_600596 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBClusterParameters_600598(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterParameters_600597(path: JsonNode;
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
  var valid_600599 = query.getOrDefault("Action")
  valid_600599 = validateParameter(valid_600599, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_600599 != nil:
    section.add "Action", valid_600599
  var valid_600600 = query.getOrDefault("Version")
  valid_600600 = validateParameter(valid_600600, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600600 != nil:
    section.add "Version", valid_600600
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600601 = header.getOrDefault("X-Amz-Date")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-Date", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Security-Token")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Security-Token", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Content-Sha256", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Algorithm")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Algorithm", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-Signature")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-Signature", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-SignedHeaders", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Credential")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Credential", valid_600607
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Source: JString
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  section = newJObject()
  var valid_600608 = formData.getOrDefault("Marker")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "Marker", valid_600608
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_600609 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_600609 = validateParameter(valid_600609, JString, required = true,
                                 default = nil)
  if valid_600609 != nil:
    section.add "DBClusterParameterGroupName", valid_600609
  var valid_600610 = formData.getOrDefault("Filters")
  valid_600610 = validateParameter(valid_600610, JArray, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "Filters", valid_600610
  var valid_600611 = formData.getOrDefault("MaxRecords")
  valid_600611 = validateParameter(valid_600611, JInt, required = false, default = nil)
  if valid_600611 != nil:
    section.add "MaxRecords", valid_600611
  var valid_600612 = formData.getOrDefault("Source")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "Source", valid_600612
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600613: Call_PostDescribeDBClusterParameters_600596;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_600613.validator(path, query, header, formData, body)
  let scheme = call_600613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600613.url(scheme.get, call_600613.host, call_600613.base,
                         call_600613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600613, url, valid)

proc call*(call_600614: Call_PostDescribeDBClusterParameters_600596;
          DBClusterParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBClusterParameters"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"; Source: string = ""): Recallable =
  ## postDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  var query_600615 = newJObject()
  var formData_600616 = newJObject()
  add(formData_600616, "Marker", newJString(Marker))
  add(query_600615, "Action", newJString(Action))
  add(formData_600616, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_600616.add "Filters", Filters
  add(formData_600616, "MaxRecords", newJInt(MaxRecords))
  add(query_600615, "Version", newJString(Version))
  add(formData_600616, "Source", newJString(Source))
  result = call_600614.call(nil, query_600615, nil, formData_600616, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_600596(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_600597, base: "/",
    url: url_PostDescribeDBClusterParameters_600598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_600576 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBClusterParameters_600578(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterParameters_600577(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Source: JString
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   Version: JString (required)
  section = newJObject()
  var valid_600579 = query.getOrDefault("MaxRecords")
  valid_600579 = validateParameter(valid_600579, JInt, required = false, default = nil)
  if valid_600579 != nil:
    section.add "MaxRecords", valid_600579
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_600580 = query.getOrDefault("DBClusterParameterGroupName")
  valid_600580 = validateParameter(valid_600580, JString, required = true,
                                 default = nil)
  if valid_600580 != nil:
    section.add "DBClusterParameterGroupName", valid_600580
  var valid_600581 = query.getOrDefault("Filters")
  valid_600581 = validateParameter(valid_600581, JArray, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "Filters", valid_600581
  var valid_600582 = query.getOrDefault("Action")
  valid_600582 = validateParameter(valid_600582, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_600582 != nil:
    section.add "Action", valid_600582
  var valid_600583 = query.getOrDefault("Marker")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "Marker", valid_600583
  var valid_600584 = query.getOrDefault("Source")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "Source", valid_600584
  var valid_600585 = query.getOrDefault("Version")
  valid_600585 = validateParameter(valid_600585, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600585 != nil:
    section.add "Version", valid_600585
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600586 = header.getOrDefault("X-Amz-Date")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-Date", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Security-Token")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Security-Token", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Content-Sha256", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Algorithm")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Algorithm", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Signature")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Signature", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-SignedHeaders", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-Credential")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Credential", valid_600592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600593: Call_GetDescribeDBClusterParameters_600576; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_600593.validator(path, query, header, formData, body)
  let scheme = call_600593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600593.url(scheme.get, call_600593.host, call_600593.base,
                         call_600593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600593, url, valid)

proc call*(call_600594: Call_GetDescribeDBClusterParameters_600576;
          DBClusterParameterGroupName: string; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBClusterParameters";
          Marker: string = ""; Source: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific DB cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  ##   Version: string (required)
  var query_600595 = newJObject()
  add(query_600595, "MaxRecords", newJInt(MaxRecords))
  add(query_600595, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_600595.add "Filters", Filters
  add(query_600595, "Action", newJString(Action))
  add(query_600595, "Marker", newJString(Marker))
  add(query_600595, "Source", newJString(Source))
  add(query_600595, "Version", newJString(Version))
  result = call_600594.call(nil, query_600595, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_600576(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_600577, base: "/",
    url: url_GetDescribeDBClusterParameters_600578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_600633 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBClusterSnapshotAttributes_600635(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_600634(path: JsonNode;
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
  var valid_600636 = query.getOrDefault("Action")
  valid_600636 = validateParameter(valid_600636, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_600636 != nil:
    section.add "Action", valid_600636
  var valid_600637 = query.getOrDefault("Version")
  valid_600637 = validateParameter(valid_600637, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600637 != nil:
    section.add "Version", valid_600637
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600638 = header.getOrDefault("X-Amz-Date")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Date", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Security-Token")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Security-Token", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Content-Sha256", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Algorithm")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Algorithm", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Signature")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Signature", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-SignedHeaders", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-Credential")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Credential", valid_600644
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_600645 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_600645 = validateParameter(valid_600645, JString, required = true,
                                 default = nil)
  if valid_600645 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_600645
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600646: Call_PostDescribeDBClusterSnapshotAttributes_600633;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_600646.validator(path, query, header, formData, body)
  let scheme = call_600646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600646.url(scheme.get, call_600646.host, call_600646.base,
                         call_600646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600646, url, valid)

proc call*(call_600647: Call_PostDescribeDBClusterSnapshotAttributes_600633;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600648 = newJObject()
  var formData_600649 = newJObject()
  add(formData_600649, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_600648, "Action", newJString(Action))
  add(query_600648, "Version", newJString(Version))
  result = call_600647.call(nil, query_600648, nil, formData_600649, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_600633(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_600634, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_600635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_600617 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBClusterSnapshotAttributes_600619(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_600618(path: JsonNode;
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
  var valid_600620 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_600620 = validateParameter(valid_600620, JString, required = true,
                                 default = nil)
  if valid_600620 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_600620
  var valid_600621 = query.getOrDefault("Action")
  valid_600621 = validateParameter(valid_600621, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_600621 != nil:
    section.add "Action", valid_600621
  var valid_600622 = query.getOrDefault("Version")
  valid_600622 = validateParameter(valid_600622, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600622 != nil:
    section.add "Version", valid_600622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600623 = header.getOrDefault("X-Amz-Date")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Date", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Security-Token")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Security-Token", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Content-Sha256", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Algorithm")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Algorithm", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Signature")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Signature", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-SignedHeaders", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Credential")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Credential", valid_600629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600630: Call_GetDescribeDBClusterSnapshotAttributes_600617;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_600630.validator(path, query, header, formData, body)
  let scheme = call_600630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600630.url(scheme.get, call_600630.host, call_600630.base,
                         call_600630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600630, url, valid)

proc call*(call_600631: Call_GetDescribeDBClusterSnapshotAttributes_600617;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600632 = newJObject()
  add(query_600632, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_600632, "Action", newJString(Action))
  add(query_600632, "Version", newJString(Version))
  result = call_600631.call(nil, query_600632, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_600617(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_600618, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_600619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_600673 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBClusterSnapshots_600675(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterSnapshots_600674(path: JsonNode;
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
  var valid_600676 = query.getOrDefault("Action")
  valid_600676 = validateParameter(valid_600676, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_600676 != nil:
    section.add "Action", valid_600676
  var valid_600677 = query.getOrDefault("Version")
  valid_600677 = validateParameter(valid_600677, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600677 != nil:
    section.add "Version", valid_600677
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600678 = header.getOrDefault("X-Amz-Date")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Date", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-Security-Token")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-Security-Token", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-Content-Sha256", valid_600680
  var valid_600681 = header.getOrDefault("X-Amz-Algorithm")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-Algorithm", valid_600681
  var valid_600682 = header.getOrDefault("X-Amz-Signature")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Signature", valid_600682
  var valid_600683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-SignedHeaders", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-Credential")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Credential", valid_600684
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SnapshotType: JString
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_600685 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_600685
  var valid_600686 = formData.getOrDefault("IncludeShared")
  valid_600686 = validateParameter(valid_600686, JBool, required = false, default = nil)
  if valid_600686 != nil:
    section.add "IncludeShared", valid_600686
  var valid_600687 = formData.getOrDefault("IncludePublic")
  valid_600687 = validateParameter(valid_600687, JBool, required = false, default = nil)
  if valid_600687 != nil:
    section.add "IncludePublic", valid_600687
  var valid_600688 = formData.getOrDefault("SnapshotType")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "SnapshotType", valid_600688
  var valid_600689 = formData.getOrDefault("Marker")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "Marker", valid_600689
  var valid_600690 = formData.getOrDefault("Filters")
  valid_600690 = validateParameter(valid_600690, JArray, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "Filters", valid_600690
  var valid_600691 = formData.getOrDefault("MaxRecords")
  valid_600691 = validateParameter(valid_600691, JInt, required = false, default = nil)
  if valid_600691 != nil:
    section.add "MaxRecords", valid_600691
  var valid_600692 = formData.getOrDefault("DBClusterIdentifier")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "DBClusterIdentifier", valid_600692
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600693: Call_PostDescribeDBClusterSnapshots_600673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_600693.validator(path, query, header, formData, body)
  let scheme = call_600693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600693.url(scheme.get, call_600693.host, call_600693.base,
                         call_600693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600693, url, valid)

proc call*(call_600694: Call_PostDescribeDBClusterSnapshots_600673;
          DBClusterSnapshotIdentifier: string = ""; IncludeShared: bool = false;
          IncludePublic: bool = false; SnapshotType: string = ""; Marker: string = "";
          Action: string = "DescribeDBClusterSnapshots"; Filters: JsonNode = nil;
          MaxRecords: int = 0; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshots
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SnapshotType: string
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_600695 = newJObject()
  var formData_600696 = newJObject()
  add(formData_600696, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_600696, "IncludeShared", newJBool(IncludeShared))
  add(formData_600696, "IncludePublic", newJBool(IncludePublic))
  add(formData_600696, "SnapshotType", newJString(SnapshotType))
  add(formData_600696, "Marker", newJString(Marker))
  add(query_600695, "Action", newJString(Action))
  if Filters != nil:
    formData_600696.add "Filters", Filters
  add(formData_600696, "MaxRecords", newJInt(MaxRecords))
  add(formData_600696, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600695, "Version", newJString(Version))
  result = call_600694.call(nil, query_600695, nil, formData_600696, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_600673(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_600674, base: "/",
    url: url_PostDescribeDBClusterSnapshots_600675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_600650 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBClusterSnapshots_600652(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterSnapshots_600651(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SnapshotType: JString
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_600653 = query.getOrDefault("IncludePublic")
  valid_600653 = validateParameter(valid_600653, JBool, required = false, default = nil)
  if valid_600653 != nil:
    section.add "IncludePublic", valid_600653
  var valid_600654 = query.getOrDefault("MaxRecords")
  valid_600654 = validateParameter(valid_600654, JInt, required = false, default = nil)
  if valid_600654 != nil:
    section.add "MaxRecords", valid_600654
  var valid_600655 = query.getOrDefault("DBClusterIdentifier")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "DBClusterIdentifier", valid_600655
  var valid_600656 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_600656
  var valid_600657 = query.getOrDefault("Filters")
  valid_600657 = validateParameter(valid_600657, JArray, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "Filters", valid_600657
  var valid_600658 = query.getOrDefault("IncludeShared")
  valid_600658 = validateParameter(valid_600658, JBool, required = false, default = nil)
  if valid_600658 != nil:
    section.add "IncludeShared", valid_600658
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600659 = query.getOrDefault("Action")
  valid_600659 = validateParameter(valid_600659, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_600659 != nil:
    section.add "Action", valid_600659
  var valid_600660 = query.getOrDefault("Marker")
  valid_600660 = validateParameter(valid_600660, JString, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "Marker", valid_600660
  var valid_600661 = query.getOrDefault("SnapshotType")
  valid_600661 = validateParameter(valid_600661, JString, required = false,
                                 default = nil)
  if valid_600661 != nil:
    section.add "SnapshotType", valid_600661
  var valid_600662 = query.getOrDefault("Version")
  valid_600662 = validateParameter(valid_600662, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600662 != nil:
    section.add "Version", valid_600662
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600663 = header.getOrDefault("X-Amz-Date")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Date", valid_600663
  var valid_600664 = header.getOrDefault("X-Amz-Security-Token")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-Security-Token", valid_600664
  var valid_600665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-Content-Sha256", valid_600665
  var valid_600666 = header.getOrDefault("X-Amz-Algorithm")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Algorithm", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Signature")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Signature", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-SignedHeaders", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Credential")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Credential", valid_600669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600670: Call_GetDescribeDBClusterSnapshots_600650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_600670.validator(path, query, header, formData, body)
  let scheme = call_600670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600670.url(scheme.get, call_600670.host, call_600670.base,
                         call_600670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600670, url, valid)

proc call*(call_600671: Call_GetDescribeDBClusterSnapshots_600650;
          IncludePublic: bool = false; MaxRecords: int = 0;
          DBClusterIdentifier: string = "";
          DBClusterSnapshotIdentifier: string = ""; Filters: JsonNode = nil;
          IncludeShared: bool = false;
          Action: string = "DescribeDBClusterSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshots
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual DB cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific DB cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual DB cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SnapshotType: string
  ##               : <p>The type of DB cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all DB cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all DB cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual DB cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all DB cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public DB cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Version: string (required)
  var query_600672 = newJObject()
  add(query_600672, "IncludePublic", newJBool(IncludePublic))
  add(query_600672, "MaxRecords", newJInt(MaxRecords))
  add(query_600672, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600672, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Filters != nil:
    query_600672.add "Filters", Filters
  add(query_600672, "IncludeShared", newJBool(IncludeShared))
  add(query_600672, "Action", newJString(Action))
  add(query_600672, "Marker", newJString(Marker))
  add(query_600672, "SnapshotType", newJString(SnapshotType))
  add(query_600672, "Version", newJString(Version))
  result = call_600671.call(nil, query_600672, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_600650(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_600651, base: "/",
    url: url_GetDescribeDBClusterSnapshots_600652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_600716 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBClusters_600718(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusters_600717(path: JsonNode; query: JsonNode;
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
  var valid_600719 = query.getOrDefault("Action")
  valid_600719 = validateParameter(valid_600719, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_600719 != nil:
    section.add "Action", valid_600719
  var valid_600720 = query.getOrDefault("Version")
  valid_600720 = validateParameter(valid_600720, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600720 != nil:
    section.add "Version", valid_600720
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600721 = header.getOrDefault("X-Amz-Date")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "X-Amz-Date", valid_600721
  var valid_600722 = header.getOrDefault("X-Amz-Security-Token")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Security-Token", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Content-Sha256", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Algorithm")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Algorithm", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-Signature")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-Signature", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-SignedHeaders", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-Credential")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-Credential", valid_600727
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_600728 = formData.getOrDefault("Marker")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "Marker", valid_600728
  var valid_600729 = formData.getOrDefault("Filters")
  valid_600729 = validateParameter(valid_600729, JArray, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "Filters", valid_600729
  var valid_600730 = formData.getOrDefault("MaxRecords")
  valid_600730 = validateParameter(valid_600730, JInt, required = false, default = nil)
  if valid_600730 != nil:
    section.add "MaxRecords", valid_600730
  var valid_600731 = formData.getOrDefault("DBClusterIdentifier")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "DBClusterIdentifier", valid_600731
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600732: Call_PostDescribeDBClusters_600716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_600732.validator(path, query, header, formData, body)
  let scheme = call_600732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600732.url(scheme.get, call_600732.host, call_600732.base,
                         call_600732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600732, url, valid)

proc call*(call_600733: Call_PostDescribeDBClusters_600716; Marker: string = "";
          Action: string = "DescribeDBClusters"; Filters: JsonNode = nil;
          MaxRecords: int = 0; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_600734 = newJObject()
  var formData_600735 = newJObject()
  add(formData_600735, "Marker", newJString(Marker))
  add(query_600734, "Action", newJString(Action))
  if Filters != nil:
    formData_600735.add "Filters", Filters
  add(formData_600735, "MaxRecords", newJInt(MaxRecords))
  add(formData_600735, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_600734, "Version", newJString(Version))
  result = call_600733.call(nil, query_600734, nil, formData_600735, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_600716(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_600717, base: "/",
    url: url_PostDescribeDBClusters_600718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_600697 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBClusters_600699(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusters_600698(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_600700 = query.getOrDefault("MaxRecords")
  valid_600700 = validateParameter(valid_600700, JInt, required = false, default = nil)
  if valid_600700 != nil:
    section.add "MaxRecords", valid_600700
  var valid_600701 = query.getOrDefault("DBClusterIdentifier")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "DBClusterIdentifier", valid_600701
  var valid_600702 = query.getOrDefault("Filters")
  valid_600702 = validateParameter(valid_600702, JArray, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "Filters", valid_600702
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600703 = query.getOrDefault("Action")
  valid_600703 = validateParameter(valid_600703, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_600703 != nil:
    section.add "Action", valid_600703
  var valid_600704 = query.getOrDefault("Marker")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "Marker", valid_600704
  var valid_600705 = query.getOrDefault("Version")
  valid_600705 = validateParameter(valid_600705, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600705 != nil:
    section.add "Version", valid_600705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600706 = header.getOrDefault("X-Amz-Date")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "X-Amz-Date", valid_600706
  var valid_600707 = header.getOrDefault("X-Amz-Security-Token")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-Security-Token", valid_600707
  var valid_600708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-Content-Sha256", valid_600708
  var valid_600709 = header.getOrDefault("X-Amz-Algorithm")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Algorithm", valid_600709
  var valid_600710 = header.getOrDefault("X-Amz-Signature")
  valid_600710 = validateParameter(valid_600710, JString, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "X-Amz-Signature", valid_600710
  var valid_600711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-SignedHeaders", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-Credential")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Credential", valid_600712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600713: Call_GetDescribeDBClusters_600697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_600713.validator(path, query, header, formData, body)
  let scheme = call_600713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600713.url(scheme.get, call_600713.host, call_600713.base,
                         call_600713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600713, url, valid)

proc call*(call_600714: Call_GetDescribeDBClusters_600697; MaxRecords: int = 0;
          DBClusterIdentifier: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeDBClusters"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list only includes information about the DB clusters identified by these ARNs.</p> </li> </ul>
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_600715 = newJObject()
  add(query_600715, "MaxRecords", newJInt(MaxRecords))
  add(query_600715, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Filters != nil:
    query_600715.add "Filters", Filters
  add(query_600715, "Action", newJString(Action))
  add(query_600715, "Marker", newJString(Marker))
  add(query_600715, "Version", newJString(Version))
  result = call_600714.call(nil, query_600715, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_600697(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_600698, base: "/",
    url: url_GetDescribeDBClusters_600699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_600760 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBEngineVersions_600762(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_600761(path: JsonNode; query: JsonNode;
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
  var valid_600763 = query.getOrDefault("Action")
  valid_600763 = validateParameter(valid_600763, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_600763 != nil:
    section.add "Action", valid_600763
  var valid_600764 = query.getOrDefault("Version")
  valid_600764 = validateParameter(valid_600764, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600764 != nil:
    section.add "Version", valid_600764
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600765 = header.getOrDefault("X-Amz-Date")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-Date", valid_600765
  var valid_600766 = header.getOrDefault("X-Amz-Security-Token")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-Security-Token", valid_600766
  var valid_600767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-Content-Sha256", valid_600767
  var valid_600768 = header.getOrDefault("X-Amz-Algorithm")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "X-Amz-Algorithm", valid_600768
  var valid_600769 = header.getOrDefault("X-Amz-Signature")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-Signature", valid_600769
  var valid_600770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600770 = validateParameter(valid_600770, JString, required = false,
                                 default = nil)
  if valid_600770 != nil:
    section.add "X-Amz-SignedHeaders", valid_600770
  var valid_600771 = header.getOrDefault("X-Amz-Credential")
  valid_600771 = validateParameter(valid_600771, JString, required = false,
                                 default = nil)
  if valid_600771 != nil:
    section.add "X-Amz-Credential", valid_600771
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListSupportedCharacterSets: JBool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Engine: JString
  ##         : The database engine to return.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBParameterGroupFamily: JString
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: JString
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   ListSupportedTimezones: JBool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   DefaultOnly: JBool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  section = newJObject()
  var valid_600772 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_600772 = validateParameter(valid_600772, JBool, required = false, default = nil)
  if valid_600772 != nil:
    section.add "ListSupportedCharacterSets", valid_600772
  var valid_600773 = formData.getOrDefault("Engine")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "Engine", valid_600773
  var valid_600774 = formData.getOrDefault("Marker")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "Marker", valid_600774
  var valid_600775 = formData.getOrDefault("DBParameterGroupFamily")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "DBParameterGroupFamily", valid_600775
  var valid_600776 = formData.getOrDefault("Filters")
  valid_600776 = validateParameter(valid_600776, JArray, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "Filters", valid_600776
  var valid_600777 = formData.getOrDefault("MaxRecords")
  valid_600777 = validateParameter(valid_600777, JInt, required = false, default = nil)
  if valid_600777 != nil:
    section.add "MaxRecords", valid_600777
  var valid_600778 = formData.getOrDefault("EngineVersion")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "EngineVersion", valid_600778
  var valid_600779 = formData.getOrDefault("ListSupportedTimezones")
  valid_600779 = validateParameter(valid_600779, JBool, required = false, default = nil)
  if valid_600779 != nil:
    section.add "ListSupportedTimezones", valid_600779
  var valid_600780 = formData.getOrDefault("DefaultOnly")
  valid_600780 = validateParameter(valid_600780, JBool, required = false, default = nil)
  if valid_600780 != nil:
    section.add "DefaultOnly", valid_600780
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600781: Call_PostDescribeDBEngineVersions_600760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_600781.validator(path, query, header, formData, body)
  let scheme = call_600781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600781.url(scheme.get, call_600781.host, call_600781.base,
                         call_600781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600781, url, valid)

proc call*(call_600782: Call_PostDescribeDBEngineVersions_600760;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; EngineVersion: string = "";
          ListSupportedTimezones: bool = false; Version: string = "2014-10-31";
          DefaultOnly: bool = false): Recallable =
  ## postDescribeDBEngineVersions
  ## Returns a list of the available DB engines.
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Engine: string
  ##         : The database engine to return.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : <p>The database engine version to return.</p> <p>Example: <code>5.1.49</code> </p>
  ##   ListSupportedTimezones: bool
  ##                         : If this parameter is specified and the requested engine supports the <code>TimeZone</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported time zones for each engine version. 
  ##   Version: string (required)
  ##   DefaultOnly: bool
  ##              : Indicates that only the default version of the specified engine or engine and major version combination is returned.
  var query_600783 = newJObject()
  var formData_600784 = newJObject()
  add(formData_600784, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_600784, "Engine", newJString(Engine))
  add(formData_600784, "Marker", newJString(Marker))
  add(query_600783, "Action", newJString(Action))
  add(formData_600784, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_600784.add "Filters", Filters
  add(formData_600784, "MaxRecords", newJInt(MaxRecords))
  add(formData_600784, "EngineVersion", newJString(EngineVersion))
  add(formData_600784, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_600783, "Version", newJString(Version))
  add(formData_600784, "DefaultOnly", newJBool(DefaultOnly))
  result = call_600782.call(nil, query_600783, nil, formData_600784, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_600760(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_600761, base: "/",
    url: url_PostDescribeDBEngineVersions_600762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_600736 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBEngineVersions_600738(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_600737(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the available DB engines.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##         : The database engine to return.
  ##   ListSupportedCharacterSets: JBool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: JString
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
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
  ##   Version: JString (required)
  section = newJObject()
  var valid_600739 = query.getOrDefault("Engine")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "Engine", valid_600739
  var valid_600740 = query.getOrDefault("ListSupportedCharacterSets")
  valid_600740 = validateParameter(valid_600740, JBool, required = false, default = nil)
  if valid_600740 != nil:
    section.add "ListSupportedCharacterSets", valid_600740
  var valid_600741 = query.getOrDefault("MaxRecords")
  valid_600741 = validateParameter(valid_600741, JInt, required = false, default = nil)
  if valid_600741 != nil:
    section.add "MaxRecords", valid_600741
  var valid_600742 = query.getOrDefault("DBParameterGroupFamily")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "DBParameterGroupFamily", valid_600742
  var valid_600743 = query.getOrDefault("Filters")
  valid_600743 = validateParameter(valid_600743, JArray, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "Filters", valid_600743
  var valid_600744 = query.getOrDefault("ListSupportedTimezones")
  valid_600744 = validateParameter(valid_600744, JBool, required = false, default = nil)
  if valid_600744 != nil:
    section.add "ListSupportedTimezones", valid_600744
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600745 = query.getOrDefault("Action")
  valid_600745 = validateParameter(valid_600745, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_600745 != nil:
    section.add "Action", valid_600745
  var valid_600746 = query.getOrDefault("Marker")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "Marker", valid_600746
  var valid_600747 = query.getOrDefault("EngineVersion")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "EngineVersion", valid_600747
  var valid_600748 = query.getOrDefault("DefaultOnly")
  valid_600748 = validateParameter(valid_600748, JBool, required = false, default = nil)
  if valid_600748 != nil:
    section.add "DefaultOnly", valid_600748
  var valid_600749 = query.getOrDefault("Version")
  valid_600749 = validateParameter(valid_600749, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600749 != nil:
    section.add "Version", valid_600749
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600750 = header.getOrDefault("X-Amz-Date")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Date", valid_600750
  var valid_600751 = header.getOrDefault("X-Amz-Security-Token")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-Security-Token", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-Content-Sha256", valid_600752
  var valid_600753 = header.getOrDefault("X-Amz-Algorithm")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-Algorithm", valid_600753
  var valid_600754 = header.getOrDefault("X-Amz-Signature")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "X-Amz-Signature", valid_600754
  var valid_600755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "X-Amz-SignedHeaders", valid_600755
  var valid_600756 = header.getOrDefault("X-Amz-Credential")
  valid_600756 = validateParameter(valid_600756, JString, required = false,
                                 default = nil)
  if valid_600756 != nil:
    section.add "X-Amz-Credential", valid_600756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600757: Call_GetDescribeDBEngineVersions_600736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_600757.validator(path, query, header, formData, body)
  let scheme = call_600757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600757.url(scheme.get, call_600757.host, call_600757.base,
                         call_600757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600757, url, valid)

proc call*(call_600758: Call_GetDescribeDBEngineVersions_600736;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Filters: JsonNode = nil; ListSupportedTimezones: bool = false;
          Action: string = "DescribeDBEngineVersions"; Marker: string = "";
          EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBEngineVersions
  ## Returns a list of the available DB engines.
  ##   Engine: string
  ##         : The database engine to return.
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific DB parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
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
  ##   Version: string (required)
  var query_600759 = newJObject()
  add(query_600759, "Engine", newJString(Engine))
  add(query_600759, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_600759, "MaxRecords", newJInt(MaxRecords))
  add(query_600759, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_600759.add "Filters", Filters
  add(query_600759, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_600759, "Action", newJString(Action))
  add(query_600759, "Marker", newJString(Marker))
  add(query_600759, "EngineVersion", newJString(EngineVersion))
  add(query_600759, "DefaultOnly", newJBool(DefaultOnly))
  add(query_600759, "Version", newJString(Version))
  result = call_600758.call(nil, query_600759, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_600736(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_600737, base: "/",
    url: url_GetDescribeDBEngineVersions_600738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_600804 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBInstances_600806(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_600805(path: JsonNode; query: JsonNode;
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
  var valid_600807 = query.getOrDefault("Action")
  valid_600807 = validateParameter(valid_600807, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_600807 != nil:
    section.add "Action", valid_600807
  var valid_600808 = query.getOrDefault("Version")
  valid_600808 = validateParameter(valid_600808, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600808 != nil:
    section.add "Version", valid_600808
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600809 = header.getOrDefault("X-Amz-Date")
  valid_600809 = validateParameter(valid_600809, JString, required = false,
                                 default = nil)
  if valid_600809 != nil:
    section.add "X-Amz-Date", valid_600809
  var valid_600810 = header.getOrDefault("X-Amz-Security-Token")
  valid_600810 = validateParameter(valid_600810, JString, required = false,
                                 default = nil)
  if valid_600810 != nil:
    section.add "X-Amz-Security-Token", valid_600810
  var valid_600811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600811 = validateParameter(valid_600811, JString, required = false,
                                 default = nil)
  if valid_600811 != nil:
    section.add "X-Amz-Content-Sha256", valid_600811
  var valid_600812 = header.getOrDefault("X-Amz-Algorithm")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Algorithm", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Signature")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Signature", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-SignedHeaders", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Credential")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Credential", valid_600815
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_600816 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "DBInstanceIdentifier", valid_600816
  var valid_600817 = formData.getOrDefault("Marker")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "Marker", valid_600817
  var valid_600818 = formData.getOrDefault("Filters")
  valid_600818 = validateParameter(valid_600818, JArray, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "Filters", valid_600818
  var valid_600819 = formData.getOrDefault("MaxRecords")
  valid_600819 = validateParameter(valid_600819, JInt, required = false, default = nil)
  if valid_600819 != nil:
    section.add "MaxRecords", valid_600819
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600820: Call_PostDescribeDBInstances_600804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_600820.validator(path, query, header, formData, body)
  let scheme = call_600820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600820.url(scheme.get, call_600820.host, call_600820.base,
                         call_600820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600820, url, valid)

proc call*(call_600821: Call_PostDescribeDBInstances_600804;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_600822 = newJObject()
  var formData_600823 = newJObject()
  add(formData_600823, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600823, "Marker", newJString(Marker))
  add(query_600822, "Action", newJString(Action))
  if Filters != nil:
    formData_600823.add "Filters", Filters
  add(formData_600823, "MaxRecords", newJInt(MaxRecords))
  add(query_600822, "Version", newJString(Version))
  result = call_600821.call(nil, query_600822, nil, formData_600823, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_600804(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_600805, base: "/",
    url: url_PostDescribeDBInstances_600806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_600785 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBInstances_600787(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_600786(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  var valid_600788 = query.getOrDefault("MaxRecords")
  valid_600788 = validateParameter(valid_600788, JInt, required = false, default = nil)
  if valid_600788 != nil:
    section.add "MaxRecords", valid_600788
  var valid_600789 = query.getOrDefault("Filters")
  valid_600789 = validateParameter(valid_600789, JArray, required = false,
                                 default = nil)
  if valid_600789 != nil:
    section.add "Filters", valid_600789
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600790 = query.getOrDefault("Action")
  valid_600790 = validateParameter(valid_600790, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_600790 != nil:
    section.add "Action", valid_600790
  var valid_600791 = query.getOrDefault("Marker")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "Marker", valid_600791
  var valid_600792 = query.getOrDefault("Version")
  valid_600792 = validateParameter(valid_600792, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600792 != nil:
    section.add "Version", valid_600792
  var valid_600793 = query.getOrDefault("DBInstanceIdentifier")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "DBInstanceIdentifier", valid_600793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600794 = header.getOrDefault("X-Amz-Date")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "X-Amz-Date", valid_600794
  var valid_600795 = header.getOrDefault("X-Amz-Security-Token")
  valid_600795 = validateParameter(valid_600795, JString, required = false,
                                 default = nil)
  if valid_600795 != nil:
    section.add "X-Amz-Security-Token", valid_600795
  var valid_600796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600796 = validateParameter(valid_600796, JString, required = false,
                                 default = nil)
  if valid_600796 != nil:
    section.add "X-Amz-Content-Sha256", valid_600796
  var valid_600797 = header.getOrDefault("X-Amz-Algorithm")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-Algorithm", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Signature")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Signature", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-SignedHeaders", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Credential")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Credential", valid_600800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600801: Call_GetDescribeDBInstances_600785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_600801.validator(path, query, header, formData, body)
  let scheme = call_600801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600801.url(scheme.get, call_600801.host, call_600801.base,
                         call_600801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600801, url, valid)

proc call*(call_600802: Call_GetDescribeDBInstances_600785; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBInstances";
          Marker: string = ""; Version: string = "2014-10-31";
          DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more DB instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only the information about the DB instances that are associated with the DB clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only the information about the DB instances that are identified by these ARNs.</p> </li> </ul>
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  var query_600803 = newJObject()
  add(query_600803, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_600803.add "Filters", Filters
  add(query_600803, "Action", newJString(Action))
  add(query_600803, "Marker", newJString(Marker))
  add(query_600803, "Version", newJString(Version))
  add(query_600803, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600802.call(nil, query_600803, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_600785(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_600786, base: "/",
    url: url_GetDescribeDBInstances_600787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_600843 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSubnetGroups_600845(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_600844(path: JsonNode; query: JsonNode;
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
  var valid_600846 = query.getOrDefault("Action")
  valid_600846 = validateParameter(valid_600846, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_600846 != nil:
    section.add "Action", valid_600846
  var valid_600847 = query.getOrDefault("Version")
  valid_600847 = validateParameter(valid_600847, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600847 != nil:
    section.add "Version", valid_600847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600848 = header.getOrDefault("X-Amz-Date")
  valid_600848 = validateParameter(valid_600848, JString, required = false,
                                 default = nil)
  if valid_600848 != nil:
    section.add "X-Amz-Date", valid_600848
  var valid_600849 = header.getOrDefault("X-Amz-Security-Token")
  valid_600849 = validateParameter(valid_600849, JString, required = false,
                                 default = nil)
  if valid_600849 != nil:
    section.add "X-Amz-Security-Token", valid_600849
  var valid_600850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Content-Sha256", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Algorithm")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Algorithm", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Signature")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Signature", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-SignedHeaders", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Credential")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Credential", valid_600854
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##                    : The name of the DB subnet group to return details for.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_600855 = formData.getOrDefault("DBSubnetGroupName")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "DBSubnetGroupName", valid_600855
  var valid_600856 = formData.getOrDefault("Marker")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "Marker", valid_600856
  var valid_600857 = formData.getOrDefault("Filters")
  valid_600857 = validateParameter(valid_600857, JArray, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "Filters", valid_600857
  var valid_600858 = formData.getOrDefault("MaxRecords")
  valid_600858 = validateParameter(valid_600858, JInt, required = false, default = nil)
  if valid_600858 != nil:
    section.add "MaxRecords", valid_600858
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600859: Call_PostDescribeDBSubnetGroups_600843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_600859.validator(path, query, header, formData, body)
  let scheme = call_600859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600859.url(scheme.get, call_600859.host, call_600859.base,
                         call_600859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600859, url, valid)

proc call*(call_600860: Call_PostDescribeDBSubnetGroups_600843;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBSubnetGroups
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ##   DBSubnetGroupName: string
  ##                    : The name of the DB subnet group to return details for.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_600861 = newJObject()
  var formData_600862 = newJObject()
  add(formData_600862, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_600862, "Marker", newJString(Marker))
  add(query_600861, "Action", newJString(Action))
  if Filters != nil:
    formData_600862.add "Filters", Filters
  add(formData_600862, "MaxRecords", newJInt(MaxRecords))
  add(query_600861, "Version", newJString(Version))
  result = call_600860.call(nil, query_600861, nil, formData_600862, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_600843(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_600844, base: "/",
    url: url_PostDescribeDBSubnetGroups_600845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_600824 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSubnetGroups_600826(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_600825(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##                    : The name of the DB subnet group to return details for.
  ##   Version: JString (required)
  section = newJObject()
  var valid_600827 = query.getOrDefault("MaxRecords")
  valid_600827 = validateParameter(valid_600827, JInt, required = false, default = nil)
  if valid_600827 != nil:
    section.add "MaxRecords", valid_600827
  var valid_600828 = query.getOrDefault("Filters")
  valid_600828 = validateParameter(valid_600828, JArray, required = false,
                                 default = nil)
  if valid_600828 != nil:
    section.add "Filters", valid_600828
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600829 = query.getOrDefault("Action")
  valid_600829 = validateParameter(valid_600829, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_600829 != nil:
    section.add "Action", valid_600829
  var valid_600830 = query.getOrDefault("Marker")
  valid_600830 = validateParameter(valid_600830, JString, required = false,
                                 default = nil)
  if valid_600830 != nil:
    section.add "Marker", valid_600830
  var valid_600831 = query.getOrDefault("DBSubnetGroupName")
  valid_600831 = validateParameter(valid_600831, JString, required = false,
                                 default = nil)
  if valid_600831 != nil:
    section.add "DBSubnetGroupName", valid_600831
  var valid_600832 = query.getOrDefault("Version")
  valid_600832 = validateParameter(valid_600832, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600832 != nil:
    section.add "Version", valid_600832
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600833 = header.getOrDefault("X-Amz-Date")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "X-Amz-Date", valid_600833
  var valid_600834 = header.getOrDefault("X-Amz-Security-Token")
  valid_600834 = validateParameter(valid_600834, JString, required = false,
                                 default = nil)
  if valid_600834 != nil:
    section.add "X-Amz-Security-Token", valid_600834
  var valid_600835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "X-Amz-Content-Sha256", valid_600835
  var valid_600836 = header.getOrDefault("X-Amz-Algorithm")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Algorithm", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Signature")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Signature", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-SignedHeaders", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Credential")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Credential", valid_600839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600840: Call_GetDescribeDBSubnetGroups_600824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_600840.validator(path, query, header, formData, body)
  let scheme = call_600840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600840.url(scheme.get, call_600840.host, call_600840.base,
                         call_600840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600840, url, valid)

proc call*(call_600841: Call_GetDescribeDBSubnetGroups_600824; MaxRecords: int = 0;
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
  ##                    : The name of the DB subnet group to return details for.
  ##   Version: string (required)
  var query_600842 = newJObject()
  add(query_600842, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_600842.add "Filters", Filters
  add(query_600842, "Action", newJString(Action))
  add(query_600842, "Marker", newJString(Marker))
  add(query_600842, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600842, "Version", newJString(Version))
  result = call_600841.call(nil, query_600842, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_600824(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_600825, base: "/",
    url: url_GetDescribeDBSubnetGroups_600826,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_600882 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEngineDefaultClusterParameters_600884(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultClusterParameters_600883(path: JsonNode;
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
  var valid_600885 = query.getOrDefault("Action")
  valid_600885 = validateParameter(valid_600885, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_600885 != nil:
    section.add "Action", valid_600885
  var valid_600886 = query.getOrDefault("Version")
  valid_600886 = validateParameter(valid_600886, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600886 != nil:
    section.add "Version", valid_600886
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600887 = header.getOrDefault("X-Amz-Date")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Date", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Security-Token")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Security-Token", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Content-Sha256", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Algorithm")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Algorithm", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Signature")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Signature", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-SignedHeaders", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Credential")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Credential", valid_600893
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_600894 = formData.getOrDefault("Marker")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "Marker", valid_600894
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_600895 = formData.getOrDefault("DBParameterGroupFamily")
  valid_600895 = validateParameter(valid_600895, JString, required = true,
                                 default = nil)
  if valid_600895 != nil:
    section.add "DBParameterGroupFamily", valid_600895
  var valid_600896 = formData.getOrDefault("Filters")
  valid_600896 = validateParameter(valid_600896, JArray, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "Filters", valid_600896
  var valid_600897 = formData.getOrDefault("MaxRecords")
  valid_600897 = validateParameter(valid_600897, JInt, required = false, default = nil)
  if valid_600897 != nil:
    section.add "MaxRecords", valid_600897
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600898: Call_PostDescribeEngineDefaultClusterParameters_600882;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_600898.validator(path, query, header, formData, body)
  let scheme = call_600898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600898.url(scheme.get, call_600898.host, call_600898.base,
                         call_600898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600898, url, valid)

proc call*(call_600899: Call_PostDescribeEngineDefaultClusterParameters_600882;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultClusterParameters";
          Filters: JsonNode = nil; MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_600900 = newJObject()
  var formData_600901 = newJObject()
  add(formData_600901, "Marker", newJString(Marker))
  add(query_600900, "Action", newJString(Action))
  add(formData_600901, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_600901.add "Filters", Filters
  add(formData_600901, "MaxRecords", newJInt(MaxRecords))
  add(query_600900, "Version", newJString(Version))
  result = call_600899.call(nil, query_600900, nil, formData_600901, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_600882(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_600883,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_600884,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_600863 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEngineDefaultClusterParameters_600865(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultClusterParameters_600864(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_600866 = query.getOrDefault("MaxRecords")
  valid_600866 = validateParameter(valid_600866, JInt, required = false, default = nil)
  if valid_600866 != nil:
    section.add "MaxRecords", valid_600866
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_600867 = query.getOrDefault("DBParameterGroupFamily")
  valid_600867 = validateParameter(valid_600867, JString, required = true,
                                 default = nil)
  if valid_600867 != nil:
    section.add "DBParameterGroupFamily", valid_600867
  var valid_600868 = query.getOrDefault("Filters")
  valid_600868 = validateParameter(valid_600868, JArray, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "Filters", valid_600868
  var valid_600869 = query.getOrDefault("Action")
  valid_600869 = validateParameter(valid_600869, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_600869 != nil:
    section.add "Action", valid_600869
  var valid_600870 = query.getOrDefault("Marker")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "Marker", valid_600870
  var valid_600871 = query.getOrDefault("Version")
  valid_600871 = validateParameter(valid_600871, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600871 != nil:
    section.add "Version", valid_600871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600872 = header.getOrDefault("X-Amz-Date")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Date", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Security-Token")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Security-Token", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Content-Sha256", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Algorithm")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Algorithm", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-Signature")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-Signature", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-SignedHeaders", valid_600877
  var valid_600878 = header.getOrDefault("X-Amz-Credential")
  valid_600878 = validateParameter(valid_600878, JString, required = false,
                                 default = nil)
  if valid_600878 != nil:
    section.add "X-Amz-Credential", valid_600878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600879: Call_GetDescribeEngineDefaultClusterParameters_600863;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_600879.validator(path, query, header, formData, body)
  let scheme = call_600879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600879.url(scheme.get, call_600879.host, call_600879.base,
                         call_600879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600879, url, valid)

proc call*(call_600880: Call_GetDescribeEngineDefaultClusterParameters_600863;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Filters: JsonNode = nil;
          Action: string = "DescribeEngineDefaultClusterParameters";
          Marker: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the DB cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_600881 = newJObject()
  add(query_600881, "MaxRecords", newJInt(MaxRecords))
  add(query_600881, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_600881.add "Filters", Filters
  add(query_600881, "Action", newJString(Action))
  add(query_600881, "Marker", newJString(Marker))
  add(query_600881, "Version", newJString(Version))
  result = call_600880.call(nil, query_600881, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_600863(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_600864,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_600865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_600919 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEventCategories_600921(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_600920(path: JsonNode; query: JsonNode;
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
  var valid_600922 = query.getOrDefault("Action")
  valid_600922 = validateParameter(valid_600922, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_600922 != nil:
    section.add "Action", valid_600922
  var valid_600923 = query.getOrDefault("Version")
  valid_600923 = validateParameter(valid_600923, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600923 != nil:
    section.add "Version", valid_600923
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600924 = header.getOrDefault("X-Amz-Date")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-Date", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Security-Token")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Security-Token", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-Content-Sha256", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-Algorithm")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Algorithm", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-Signature")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-Signature", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-SignedHeaders", valid_600929
  var valid_600930 = header.getOrDefault("X-Amz-Credential")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "X-Amz-Credential", valid_600930
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  section = newJObject()
  var valid_600931 = formData.getOrDefault("Filters")
  valid_600931 = validateParameter(valid_600931, JArray, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "Filters", valid_600931
  var valid_600932 = formData.getOrDefault("SourceType")
  valid_600932 = validateParameter(valid_600932, JString, required = false,
                                 default = nil)
  if valid_600932 != nil:
    section.add "SourceType", valid_600932
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600933: Call_PostDescribeEventCategories_600919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_600933.validator(path, query, header, formData, body)
  let scheme = call_600933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600933.url(scheme.get, call_600933.host, call_600933.base,
                         call_600933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600933, url, valid)

proc call*(call_600934: Call_PostDescribeEventCategories_600919;
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
  var query_600935 = newJObject()
  var formData_600936 = newJObject()
  add(query_600935, "Action", newJString(Action))
  if Filters != nil:
    formData_600936.add "Filters", Filters
  add(query_600935, "Version", newJString(Version))
  add(formData_600936, "SourceType", newJString(SourceType))
  result = call_600934.call(nil, query_600935, nil, formData_600936, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_600919(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_600920, base: "/",
    url: url_PostDescribeEventCategories_600921,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_600902 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEventCategories_600904(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_600903(path: JsonNode; query: JsonNode;
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
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_600905 = query.getOrDefault("SourceType")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "SourceType", valid_600905
  var valid_600906 = query.getOrDefault("Filters")
  valid_600906 = validateParameter(valid_600906, JArray, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "Filters", valid_600906
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600907 = query.getOrDefault("Action")
  valid_600907 = validateParameter(valid_600907, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_600907 != nil:
    section.add "Action", valid_600907
  var valid_600908 = query.getOrDefault("Version")
  valid_600908 = validateParameter(valid_600908, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600908 != nil:
    section.add "Version", valid_600908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600909 = header.getOrDefault("X-Amz-Date")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Date", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Security-Token")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Security-Token", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-Content-Sha256", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Algorithm")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Algorithm", valid_600912
  var valid_600913 = header.getOrDefault("X-Amz-Signature")
  valid_600913 = validateParameter(valid_600913, JString, required = false,
                                 default = nil)
  if valid_600913 != nil:
    section.add "X-Amz-Signature", valid_600913
  var valid_600914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "X-Amz-SignedHeaders", valid_600914
  var valid_600915 = header.getOrDefault("X-Amz-Credential")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "X-Amz-Credential", valid_600915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600916: Call_GetDescribeEventCategories_600902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_600916.validator(path, query, header, formData, body)
  let scheme = call_600916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600916.url(scheme.get, call_600916.host, call_600916.base,
                         call_600916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600916, url, valid)

proc call*(call_600917: Call_GetDescribeEventCategories_600902;
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
  var query_600918 = newJObject()
  add(query_600918, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_600918.add "Filters", Filters
  add(query_600918, "Action", newJString(Action))
  add(query_600918, "Version", newJString(Version))
  result = call_600917.call(nil, query_600918, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_600902(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_600903, base: "/",
    url: url_GetDescribeEventCategories_600904,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_600961 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEvents_600963(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_600962(path: JsonNode; query: JsonNode;
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
  var valid_600964 = query.getOrDefault("Action")
  valid_600964 = validateParameter(valid_600964, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_600964 != nil:
    section.add "Action", valid_600964
  var valid_600965 = query.getOrDefault("Version")
  valid_600965 = validateParameter(valid_600965, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600965 != nil:
    section.add "Version", valid_600965
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600966 = header.getOrDefault("X-Amz-Date")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-Date", valid_600966
  var valid_600967 = header.getOrDefault("X-Amz-Security-Token")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Security-Token", valid_600967
  var valid_600968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "X-Amz-Content-Sha256", valid_600968
  var valid_600969 = header.getOrDefault("X-Amz-Algorithm")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-Algorithm", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-Signature")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-Signature", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-SignedHeaders", valid_600971
  var valid_600972 = header.getOrDefault("X-Amz-Credential")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "X-Amz-Credential", valid_600972
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
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
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   SourceType: JString
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  section = newJObject()
  var valid_600973 = formData.getOrDefault("SourceIdentifier")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "SourceIdentifier", valid_600973
  var valid_600974 = formData.getOrDefault("EventCategories")
  valid_600974 = validateParameter(valid_600974, JArray, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "EventCategories", valid_600974
  var valid_600975 = formData.getOrDefault("Marker")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "Marker", valid_600975
  var valid_600976 = formData.getOrDefault("StartTime")
  valid_600976 = validateParameter(valid_600976, JString, required = false,
                                 default = nil)
  if valid_600976 != nil:
    section.add "StartTime", valid_600976
  var valid_600977 = formData.getOrDefault("Duration")
  valid_600977 = validateParameter(valid_600977, JInt, required = false, default = nil)
  if valid_600977 != nil:
    section.add "Duration", valid_600977
  var valid_600978 = formData.getOrDefault("Filters")
  valid_600978 = validateParameter(valid_600978, JArray, required = false,
                                 default = nil)
  if valid_600978 != nil:
    section.add "Filters", valid_600978
  var valid_600979 = formData.getOrDefault("EndTime")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "EndTime", valid_600979
  var valid_600980 = formData.getOrDefault("MaxRecords")
  valid_600980 = validateParameter(valid_600980, JInt, required = false, default = nil)
  if valid_600980 != nil:
    section.add "MaxRecords", valid_600980
  var valid_600981 = formData.getOrDefault("SourceType")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_600981 != nil:
    section.add "SourceType", valid_600981
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600982: Call_PostDescribeEvents_600961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_600982.validator(path, query, header, formData, body)
  let scheme = call_600982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600982.url(scheme.get, call_600982.host, call_600982.base,
                         call_600982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600982, url, valid)

proc call*(call_600983: Call_PostDescribeEvents_600961;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; Filters: JsonNode = nil;
          EndTime: string = ""; MaxRecords: int = 0; Version: string = "2014-10-31";
          SourceType: string = "db-instance"): Recallable =
  ## postDescribeEvents
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ##   SourceIdentifier: string
  ##                   : <p>The identifier of the event source for which events are returned. If not specified, then all sources are included in the response.</p> <p>Constraints:</p> <ul> <li> <p>If <code>SourceIdentifier</code> is provided, <code>SourceType</code> must also be provided.</p> </li> <li> <p>If the source type is <code>DBInstance</code>, a <code>DBInstanceIdentifier</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSecurityGroup</code>, a <code>DBSecurityGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBParameterGroup</code>, a <code>DBParameterGroupName</code> must be provided.</p> </li> <li> <p>If the source type is <code>DBSnapshot</code>, a <code>DBSnapshotIdentifier</code> must be provided.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
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
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  ##   SourceType: string
  ##             : The event source to retrieve events for. If no value is specified, all events are returned.
  var query_600984 = newJObject()
  var formData_600985 = newJObject()
  add(formData_600985, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_600985.add "EventCategories", EventCategories
  add(formData_600985, "Marker", newJString(Marker))
  add(formData_600985, "StartTime", newJString(StartTime))
  add(query_600984, "Action", newJString(Action))
  add(formData_600985, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_600985.add "Filters", Filters
  add(formData_600985, "EndTime", newJString(EndTime))
  add(formData_600985, "MaxRecords", newJInt(MaxRecords))
  add(query_600984, "Version", newJString(Version))
  add(formData_600985, "SourceType", newJString(SourceType))
  result = call_600983.call(nil, query_600984, nil, formData_600985, nil)

var postDescribeEvents* = Call_PostDescribeEvents_600961(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_600962, base: "/",
    url: url_PostDescribeEvents_600963, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_600937 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEvents_600939(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_600938(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
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
  var valid_600940 = query.getOrDefault("SourceType")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_600940 != nil:
    section.add "SourceType", valid_600940
  var valid_600941 = query.getOrDefault("MaxRecords")
  valid_600941 = validateParameter(valid_600941, JInt, required = false, default = nil)
  if valid_600941 != nil:
    section.add "MaxRecords", valid_600941
  var valid_600942 = query.getOrDefault("StartTime")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "StartTime", valid_600942
  var valid_600943 = query.getOrDefault("Filters")
  valid_600943 = validateParameter(valid_600943, JArray, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "Filters", valid_600943
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600944 = query.getOrDefault("Action")
  valid_600944 = validateParameter(valid_600944, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_600944 != nil:
    section.add "Action", valid_600944
  var valid_600945 = query.getOrDefault("SourceIdentifier")
  valid_600945 = validateParameter(valid_600945, JString, required = false,
                                 default = nil)
  if valid_600945 != nil:
    section.add "SourceIdentifier", valid_600945
  var valid_600946 = query.getOrDefault("Marker")
  valid_600946 = validateParameter(valid_600946, JString, required = false,
                                 default = nil)
  if valid_600946 != nil:
    section.add "Marker", valid_600946
  var valid_600947 = query.getOrDefault("EventCategories")
  valid_600947 = validateParameter(valid_600947, JArray, required = false,
                                 default = nil)
  if valid_600947 != nil:
    section.add "EventCategories", valid_600947
  var valid_600948 = query.getOrDefault("Duration")
  valid_600948 = validateParameter(valid_600948, JInt, required = false, default = nil)
  if valid_600948 != nil:
    section.add "Duration", valid_600948
  var valid_600949 = query.getOrDefault("EndTime")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "EndTime", valid_600949
  var valid_600950 = query.getOrDefault("Version")
  valid_600950 = validateParameter(valid_600950, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600950 != nil:
    section.add "Version", valid_600950
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600951 = header.getOrDefault("X-Amz-Date")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "X-Amz-Date", valid_600951
  var valid_600952 = header.getOrDefault("X-Amz-Security-Token")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Security-Token", valid_600952
  var valid_600953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "X-Amz-Content-Sha256", valid_600953
  var valid_600954 = header.getOrDefault("X-Amz-Algorithm")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "X-Amz-Algorithm", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-Signature")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Signature", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-SignedHeaders", valid_600956
  var valid_600957 = header.getOrDefault("X-Amz-Credential")
  valid_600957 = validateParameter(valid_600957, JString, required = false,
                                 default = nil)
  if valid_600957 != nil:
    section.add "X-Amz-Credential", valid_600957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600958: Call_GetDescribeEvents_600937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_600958.validator(path, query, header, formData, body)
  let scheme = call_600958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600958.url(scheme.get, call_600958.host, call_600958.base,
                         call_600958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600958, url, valid)

proc call*(call_600959: Call_GetDescribeEvents_600937;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEvents"; SourceIdentifier: string = "";
          Marker: string = ""; EventCategories: JsonNode = nil; Duration: int = 0;
          EndTime: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeEvents
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
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
  var query_600960 = newJObject()
  add(query_600960, "SourceType", newJString(SourceType))
  add(query_600960, "MaxRecords", newJInt(MaxRecords))
  add(query_600960, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_600960.add "Filters", Filters
  add(query_600960, "Action", newJString(Action))
  add(query_600960, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_600960, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_600960.add "EventCategories", EventCategories
  add(query_600960, "Duration", newJInt(Duration))
  add(query_600960, "EndTime", newJString(EndTime))
  add(query_600960, "Version", newJString(Version))
  result = call_600959.call(nil, query_600960, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_600937(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_600938,
    base: "/", url: url_GetDescribeEvents_600939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_601009 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOrderableDBInstanceOptions_601011(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_601010(path: JsonNode;
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
  var valid_601012 = query.getOrDefault("Action")
  valid_601012 = validateParameter(valid_601012, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_601012 != nil:
    section.add "Action", valid_601012
  var valid_601013 = query.getOrDefault("Version")
  valid_601013 = validateParameter(valid_601013, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601013 != nil:
    section.add "Version", valid_601013
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601014 = header.getOrDefault("X-Amz-Date")
  valid_601014 = validateParameter(valid_601014, JString, required = false,
                                 default = nil)
  if valid_601014 != nil:
    section.add "X-Amz-Date", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-Security-Token")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-Security-Token", valid_601015
  var valid_601016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Content-Sha256", valid_601016
  var valid_601017 = header.getOrDefault("X-Amz-Algorithm")
  valid_601017 = validateParameter(valid_601017, JString, required = false,
                                 default = nil)
  if valid_601017 != nil:
    section.add "X-Amz-Algorithm", valid_601017
  var valid_601018 = header.getOrDefault("X-Amz-Signature")
  valid_601018 = validateParameter(valid_601018, JString, required = false,
                                 default = nil)
  if valid_601018 != nil:
    section.add "X-Amz-Signature", valid_601018
  var valid_601019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601019 = validateParameter(valid_601019, JString, required = false,
                                 default = nil)
  if valid_601019 != nil:
    section.add "X-Amz-SignedHeaders", valid_601019
  var valid_601020 = header.getOrDefault("X-Amz-Credential")
  valid_601020 = validateParameter(valid_601020, JString, required = false,
                                 default = nil)
  if valid_601020 != nil:
    section.add "X-Amz-Credential", valid_601020
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: JString
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_601021 = formData.getOrDefault("Engine")
  valid_601021 = validateParameter(valid_601021, JString, required = true,
                                 default = nil)
  if valid_601021 != nil:
    section.add "Engine", valid_601021
  var valid_601022 = formData.getOrDefault("Marker")
  valid_601022 = validateParameter(valid_601022, JString, required = false,
                                 default = nil)
  if valid_601022 != nil:
    section.add "Marker", valid_601022
  var valid_601023 = formData.getOrDefault("Vpc")
  valid_601023 = validateParameter(valid_601023, JBool, required = false, default = nil)
  if valid_601023 != nil:
    section.add "Vpc", valid_601023
  var valid_601024 = formData.getOrDefault("DBInstanceClass")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "DBInstanceClass", valid_601024
  var valid_601025 = formData.getOrDefault("Filters")
  valid_601025 = validateParameter(valid_601025, JArray, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "Filters", valid_601025
  var valid_601026 = formData.getOrDefault("LicenseModel")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "LicenseModel", valid_601026
  var valid_601027 = formData.getOrDefault("MaxRecords")
  valid_601027 = validateParameter(valid_601027, JInt, required = false, default = nil)
  if valid_601027 != nil:
    section.add "MaxRecords", valid_601027
  var valid_601028 = formData.getOrDefault("EngineVersion")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "EngineVersion", valid_601028
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601029: Call_PostDescribeOrderableDBInstanceOptions_601009;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_601029.validator(path, query, header, formData, body)
  let scheme = call_601029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601029.url(scheme.get, call_601029.host, call_601029.base,
                         call_601029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601029, url, valid)

proc call*(call_601030: Call_PostDescribeOrderableDBInstanceOptions_601009;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          LicenseModel: string = ""; MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable DB instance options for the specified engine.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: string
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: string (required)
  var query_601031 = newJObject()
  var formData_601032 = newJObject()
  add(formData_601032, "Engine", newJString(Engine))
  add(formData_601032, "Marker", newJString(Marker))
  add(query_601031, "Action", newJString(Action))
  add(formData_601032, "Vpc", newJBool(Vpc))
  add(formData_601032, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_601032.add "Filters", Filters
  add(formData_601032, "LicenseModel", newJString(LicenseModel))
  add(formData_601032, "MaxRecords", newJInt(MaxRecords))
  add(formData_601032, "EngineVersion", newJString(EngineVersion))
  add(query_601031, "Version", newJString(Version))
  result = call_601030.call(nil, query_601031, nil, formData_601032, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_601009(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_601010, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_601011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_600986 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOrderableDBInstanceOptions_600988(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_600987(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: JString
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_600989 = query.getOrDefault("Engine")
  valid_600989 = validateParameter(valid_600989, JString, required = true,
                                 default = nil)
  if valid_600989 != nil:
    section.add "Engine", valid_600989
  var valid_600990 = query.getOrDefault("MaxRecords")
  valid_600990 = validateParameter(valid_600990, JInt, required = false, default = nil)
  if valid_600990 != nil:
    section.add "MaxRecords", valid_600990
  var valid_600991 = query.getOrDefault("Filters")
  valid_600991 = validateParameter(valid_600991, JArray, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "Filters", valid_600991
  var valid_600992 = query.getOrDefault("LicenseModel")
  valid_600992 = validateParameter(valid_600992, JString, required = false,
                                 default = nil)
  if valid_600992 != nil:
    section.add "LicenseModel", valid_600992
  var valid_600993 = query.getOrDefault("Vpc")
  valid_600993 = validateParameter(valid_600993, JBool, required = false, default = nil)
  if valid_600993 != nil:
    section.add "Vpc", valid_600993
  var valid_600994 = query.getOrDefault("DBInstanceClass")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "DBInstanceClass", valid_600994
  var valid_600995 = query.getOrDefault("Action")
  valid_600995 = validateParameter(valid_600995, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_600995 != nil:
    section.add "Action", valid_600995
  var valid_600996 = query.getOrDefault("Marker")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "Marker", valid_600996
  var valid_600997 = query.getOrDefault("EngineVersion")
  valid_600997 = validateParameter(valid_600997, JString, required = false,
                                 default = nil)
  if valid_600997 != nil:
    section.add "EngineVersion", valid_600997
  var valid_600998 = query.getOrDefault("Version")
  valid_600998 = validateParameter(valid_600998, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_600998 != nil:
    section.add "Version", valid_600998
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600999 = header.getOrDefault("X-Amz-Date")
  valid_600999 = validateParameter(valid_600999, JString, required = false,
                                 default = nil)
  if valid_600999 != nil:
    section.add "X-Amz-Date", valid_600999
  var valid_601000 = header.getOrDefault("X-Amz-Security-Token")
  valid_601000 = validateParameter(valid_601000, JString, required = false,
                                 default = nil)
  if valid_601000 != nil:
    section.add "X-Amz-Security-Token", valid_601000
  var valid_601001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "X-Amz-Content-Sha256", valid_601001
  var valid_601002 = header.getOrDefault("X-Amz-Algorithm")
  valid_601002 = validateParameter(valid_601002, JString, required = false,
                                 default = nil)
  if valid_601002 != nil:
    section.add "X-Amz-Algorithm", valid_601002
  var valid_601003 = header.getOrDefault("X-Amz-Signature")
  valid_601003 = validateParameter(valid_601003, JString, required = false,
                                 default = nil)
  if valid_601003 != nil:
    section.add "X-Amz-Signature", valid_601003
  var valid_601004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601004 = validateParameter(valid_601004, JString, required = false,
                                 default = nil)
  if valid_601004 != nil:
    section.add "X-Amz-SignedHeaders", valid_601004
  var valid_601005 = header.getOrDefault("X-Amz-Credential")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "X-Amz-Credential", valid_601005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601006: Call_GetDescribeOrderableDBInstanceOptions_600986;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_601006.validator(path, query, header, formData, body)
  let scheme = call_601006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601006.url(scheme.get, call_601006.host, call_601006.base,
                         call_601006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601006, url, valid)

proc call*(call_601007: Call_GetDescribeOrderableDBInstanceOptions_600986;
          Engine: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          LicenseModel: string = ""; Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable DB instance options for the specified engine.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve DB instance options for.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: string
  ##                  : The DB instance class filter value. Specify this parameter to show only the available offerings that match the specified DB instance class.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: string (required)
  var query_601008 = newJObject()
  add(query_601008, "Engine", newJString(Engine))
  add(query_601008, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601008.add "Filters", Filters
  add(query_601008, "LicenseModel", newJString(LicenseModel))
  add(query_601008, "Vpc", newJBool(Vpc))
  add(query_601008, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601008, "Action", newJString(Action))
  add(query_601008, "Marker", newJString(Marker))
  add(query_601008, "EngineVersion", newJString(EngineVersion))
  add(query_601008, "Version", newJString(Version))
  result = call_601007.call(nil, query_601008, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_600986(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_600987, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_600988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_601052 = ref object of OpenApiRestCall_599352
proc url_PostDescribePendingMaintenanceActions_601054(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribePendingMaintenanceActions_601053(path: JsonNode;
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
  var valid_601055 = query.getOrDefault("Action")
  valid_601055 = validateParameter(valid_601055, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_601055 != nil:
    section.add "Action", valid_601055
  var valid_601056 = query.getOrDefault("Version")
  valid_601056 = validateParameter(valid_601056, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601056 != nil:
    section.add "Version", valid_601056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601057 = header.getOrDefault("X-Amz-Date")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Date", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Security-Token")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Security-Token", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Content-Sha256", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Algorithm")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Algorithm", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Signature")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Signature", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-SignedHeaders", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Credential")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Credential", valid_601063
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_601064 = formData.getOrDefault("Marker")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "Marker", valid_601064
  var valid_601065 = formData.getOrDefault("ResourceIdentifier")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "ResourceIdentifier", valid_601065
  var valid_601066 = formData.getOrDefault("Filters")
  valid_601066 = validateParameter(valid_601066, JArray, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "Filters", valid_601066
  var valid_601067 = formData.getOrDefault("MaxRecords")
  valid_601067 = validateParameter(valid_601067, JInt, required = false, default = nil)
  if valid_601067 != nil:
    section.add "MaxRecords", valid_601067
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601068: Call_PostDescribePendingMaintenanceActions_601052;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_601068.validator(path, query, header, formData, body)
  let scheme = call_601068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601068.url(scheme.get, call_601068.host, call_601068.base,
                         call_601068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601068, url, valid)

proc call*(call_601069: Call_PostDescribePendingMaintenanceActions_601052;
          Marker: string = ""; Action: string = "DescribePendingMaintenanceActions";
          ResourceIdentifier: string = ""; Filters: JsonNode = nil; MaxRecords: int = 0;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_601070 = newJObject()
  var formData_601071 = newJObject()
  add(formData_601071, "Marker", newJString(Marker))
  add(query_601070, "Action", newJString(Action))
  add(formData_601071, "ResourceIdentifier", newJString(ResourceIdentifier))
  if Filters != nil:
    formData_601071.add "Filters", Filters
  add(formData_601071, "MaxRecords", newJInt(MaxRecords))
  add(query_601070, "Version", newJString(Version))
  result = call_601069.call(nil, query_601070, nil, formData_601071, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_601052(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_601053, base: "/",
    url: url_PostDescribePendingMaintenanceActions_601054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_601033 = ref object of OpenApiRestCall_599352
proc url_GetDescribePendingMaintenanceActions_601035(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribePendingMaintenanceActions_601034(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_601036 = query.getOrDefault("MaxRecords")
  valid_601036 = validateParameter(valid_601036, JInt, required = false, default = nil)
  if valid_601036 != nil:
    section.add "MaxRecords", valid_601036
  var valid_601037 = query.getOrDefault("Filters")
  valid_601037 = validateParameter(valid_601037, JArray, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "Filters", valid_601037
  var valid_601038 = query.getOrDefault("ResourceIdentifier")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "ResourceIdentifier", valid_601038
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601039 = query.getOrDefault("Action")
  valid_601039 = validateParameter(valid_601039, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_601039 != nil:
    section.add "Action", valid_601039
  var valid_601040 = query.getOrDefault("Marker")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "Marker", valid_601040
  var valid_601041 = query.getOrDefault("Version")
  valid_601041 = validateParameter(valid_601041, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601041 != nil:
    section.add "Version", valid_601041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601042 = header.getOrDefault("X-Amz-Date")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Date", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Security-Token")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Security-Token", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Content-Sha256", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Algorithm")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Algorithm", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Signature")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Signature", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-SignedHeaders", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Credential")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Credential", valid_601048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_GetDescribePendingMaintenanceActions_601033;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601049, url, valid)

proc call*(call_601050: Call_GetDescribePendingMaintenanceActions_601033;
          MaxRecords: int = 0; Filters: JsonNode = nil; ResourceIdentifier: string = "";
          Action: string = "DescribePendingMaintenanceActions"; Marker: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the DB clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts DB instance identifiers and DB instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_601051 = newJObject()
  add(query_601051, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601051.add "Filters", Filters
  add(query_601051, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_601051, "Action", newJString(Action))
  add(query_601051, "Marker", newJString(Marker))
  add(query_601051, "Version", newJString(Version))
  result = call_601050.call(nil, query_601051, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_601033(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_601034, base: "/",
    url: url_GetDescribePendingMaintenanceActions_601035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_601089 = ref object of OpenApiRestCall_599352
proc url_PostFailoverDBCluster_601091(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostFailoverDBCluster_601090(path: JsonNode; query: JsonNode;
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
  var valid_601092 = query.getOrDefault("Action")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_601092 != nil:
    section.add "Action", valid_601092
  var valid_601093 = query.getOrDefault("Version")
  valid_601093 = validateParameter(valid_601093, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601093 != nil:
    section.add "Version", valid_601093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601094 = header.getOrDefault("X-Amz-Date")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Date", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Security-Token")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Security-Token", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Content-Sha256", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Algorithm")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Algorithm", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Signature")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Signature", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-SignedHeaders", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Credential")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Credential", valid_601100
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_601101 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "TargetDBInstanceIdentifier", valid_601101
  var valid_601102 = formData.getOrDefault("DBClusterIdentifier")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "DBClusterIdentifier", valid_601102
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601103: Call_PostFailoverDBCluster_601089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_601103.validator(path, query, header, formData, body)
  let scheme = call_601103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601103.url(scheme.get, call_601103.host, call_601103.base,
                         call_601103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601103, url, valid)

proc call*(call_601104: Call_PostFailoverDBCluster_601089;
          Action: string = "FailoverDBCluster";
          TargetDBInstanceIdentifier: string = ""; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postFailoverDBCluster
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ##   Action: string (required)
  ##   TargetDBInstanceIdentifier: string
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_601105 = newJObject()
  var formData_601106 = newJObject()
  add(query_601105, "Action", newJString(Action))
  add(formData_601106, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_601106, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601105, "Version", newJString(Version))
  result = call_601104.call(nil, query_601105, nil, formData_601106, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_601089(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_601090, base: "/",
    url: url_PostFailoverDBCluster_601091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_601072 = ref object of OpenApiRestCall_599352
proc url_GetFailoverDBCluster_601074(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFailoverDBCluster_601073(path: JsonNode; query: JsonNode;
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
  var valid_601075 = query.getOrDefault("DBClusterIdentifier")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "DBClusterIdentifier", valid_601075
  var valid_601076 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "TargetDBInstanceIdentifier", valid_601076
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601077 = query.getOrDefault("Action")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_601077 != nil:
    section.add "Action", valid_601077
  var valid_601078 = query.getOrDefault("Version")
  valid_601078 = validateParameter(valid_601078, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601078 != nil:
    section.add "Version", valid_601078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601079 = header.getOrDefault("X-Amz-Date")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Date", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Security-Token")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Security-Token", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Content-Sha256", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Algorithm")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Algorithm", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Signature")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Signature", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-SignedHeaders", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Credential")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Credential", valid_601085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601086: Call_GetFailoverDBCluster_601072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_601086.validator(path, query, header, formData, body)
  let scheme = call_601086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601086.url(scheme.get, call_601086.host, call_601086.base,
                         call_601086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601086, url, valid)

proc call*(call_601087: Call_GetFailoverDBCluster_601072;
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
  var query_601088 = newJObject()
  add(query_601088, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601088, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_601088, "Action", newJString(Action))
  add(query_601088, "Version", newJString(Version))
  result = call_601087.call(nil, query_601088, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_601072(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_601073, base: "/",
    url: url_GetFailoverDBCluster_601074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_601124 = ref object of OpenApiRestCall_599352
proc url_PostListTagsForResource_601126(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_601125(path: JsonNode; query: JsonNode;
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
  var valid_601127 = query.getOrDefault("Action")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601127 != nil:
    section.add "Action", valid_601127
  var valid_601128 = query.getOrDefault("Version")
  valid_601128 = validateParameter(valid_601128, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601128 != nil:
    section.add "Version", valid_601128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601129 = header.getOrDefault("X-Amz-Date")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Date", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Security-Token")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Security-Token", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Content-Sha256", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Algorithm")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Algorithm", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Signature")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Signature", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-SignedHeaders", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Credential")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Credential", valid_601135
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_601136 = formData.getOrDefault("Filters")
  valid_601136 = validateParameter(valid_601136, JArray, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "Filters", valid_601136
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_601137 = formData.getOrDefault("ResourceName")
  valid_601137 = validateParameter(valid_601137, JString, required = true,
                                 default = nil)
  if valid_601137 != nil:
    section.add "ResourceName", valid_601137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601138: Call_PostListTagsForResource_601124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_601138.validator(path, query, header, formData, body)
  let scheme = call_601138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601138.url(scheme.get, call_601138.host, call_601138.base,
                         call_601138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601138, url, valid)

proc call*(call_601139: Call_PostListTagsForResource_601124; ResourceName: string;
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
  var query_601140 = newJObject()
  var formData_601141 = newJObject()
  add(query_601140, "Action", newJString(Action))
  if Filters != nil:
    formData_601141.add "Filters", Filters
  add(formData_601141, "ResourceName", newJString(ResourceName))
  add(query_601140, "Version", newJString(Version))
  result = call_601139.call(nil, query_601140, nil, formData_601141, nil)

var postListTagsForResource* = Call_PostListTagsForResource_601124(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_601125, base: "/",
    url: url_PostListTagsForResource_601126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_601107 = ref object of OpenApiRestCall_599352
proc url_GetListTagsForResource_601109(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_601108(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_601110 = query.getOrDefault("Filters")
  valid_601110 = validateParameter(valid_601110, JArray, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "Filters", valid_601110
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_601111 = query.getOrDefault("ResourceName")
  valid_601111 = validateParameter(valid_601111, JString, required = true,
                                 default = nil)
  if valid_601111 != nil:
    section.add "ResourceName", valid_601111
  var valid_601112 = query.getOrDefault("Action")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601112 != nil:
    section.add "Action", valid_601112
  var valid_601113 = query.getOrDefault("Version")
  valid_601113 = validateParameter(valid_601113, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601113 != nil:
    section.add "Version", valid_601113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601114 = header.getOrDefault("X-Amz-Date")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Date", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Security-Token")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Security-Token", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Content-Sha256", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Algorithm")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Algorithm", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Signature")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Signature", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-SignedHeaders", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Credential")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Credential", valid_601120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601121: Call_GetListTagsForResource_601107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_601121.validator(path, query, header, formData, body)
  let scheme = call_601121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601121.url(scheme.get, call_601121.host, call_601121.base,
                         call_601121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601121, url, valid)

proc call*(call_601122: Call_GetListTagsForResource_601107; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-10-31"): Recallable =
  ## getListTagsForResource
  ## Lists all tags on an Amazon DocumentDB resource.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601123 = newJObject()
  if Filters != nil:
    query_601123.add "Filters", Filters
  add(query_601123, "ResourceName", newJString(ResourceName))
  add(query_601123, "Action", newJString(Action))
  add(query_601123, "Version", newJString(Version))
  result = call_601122.call(nil, query_601123, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_601107(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_601108, base: "/",
    url: url_GetListTagsForResource_601109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_601171 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBCluster_601173(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBCluster_601172(path: JsonNode; query: JsonNode;
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
  var valid_601174 = query.getOrDefault("Action")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_601174 != nil:
    section.add "Action", valid_601174
  var valid_601175 = query.getOrDefault("Version")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601175 != nil:
    section.add "Version", valid_601175
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601176 = header.getOrDefault("X-Amz-Date")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Date", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Security-Token")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Security-Token", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  ## parameters in `formData` object:
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   Port: JInt
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  var valid_601183 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_601183 = validateParameter(valid_601183, JArray, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_601183
  var valid_601184 = formData.getOrDefault("ApplyImmediately")
  valid_601184 = validateParameter(valid_601184, JBool, required = false, default = nil)
  if valid_601184 != nil:
    section.add "ApplyImmediately", valid_601184
  var valid_601185 = formData.getOrDefault("Port")
  valid_601185 = validateParameter(valid_601185, JInt, required = false, default = nil)
  if valid_601185 != nil:
    section.add "Port", valid_601185
  var valid_601186 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601186 = validateParameter(valid_601186, JArray, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "VpcSecurityGroupIds", valid_601186
  var valid_601187 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601187 = validateParameter(valid_601187, JInt, required = false, default = nil)
  if valid_601187 != nil:
    section.add "BackupRetentionPeriod", valid_601187
  var valid_601188 = formData.getOrDefault("MasterUserPassword")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "MasterUserPassword", valid_601188
  var valid_601189 = formData.getOrDefault("DeletionProtection")
  valid_601189 = validateParameter(valid_601189, JBool, required = false, default = nil)
  if valid_601189 != nil:
    section.add "DeletionProtection", valid_601189
  var valid_601190 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "NewDBClusterIdentifier", valid_601190
  var valid_601191 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_601191 = validateParameter(valid_601191, JArray, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_601191
  var valid_601192 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "DBClusterParameterGroupName", valid_601192
  var valid_601193 = formData.getOrDefault("PreferredBackupWindow")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "PreferredBackupWindow", valid_601193
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_601194 = formData.getOrDefault("DBClusterIdentifier")
  valid_601194 = validateParameter(valid_601194, JString, required = true,
                                 default = nil)
  if valid_601194 != nil:
    section.add "DBClusterIdentifier", valid_601194
  var valid_601195 = formData.getOrDefault("EngineVersion")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "EngineVersion", valid_601195
  var valid_601196 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "PreferredMaintenanceWindow", valid_601196
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601197: Call_PostModifyDBCluster_601171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_601197.validator(path, query, header, formData, body)
  let scheme = call_601197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601197.url(scheme.get, call_601197.host, call_601197.base,
                         call_601197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601197, url, valid)

proc call*(call_601198: Call_PostModifyDBCluster_601171;
          DBClusterIdentifier: string;
          CloudwatchLogsExportConfigurationEnableLogTypes: JsonNode = nil;
          ApplyImmediately: bool = false; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          MasterUserPassword: string = ""; DeletionProtection: bool = false;
          NewDBClusterIdentifier: string = "";
          CloudwatchLogsExportConfigurationDisableLogTypes: JsonNode = nil;
          Action: string = "ModifyDBCluster";
          DBClusterParameterGroupName: string = "";
          PreferredBackupWindow: string = ""; EngineVersion: string = "";
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postModifyDBCluster
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   Port: int
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_601199 = newJObject()
  var formData_601200 = newJObject()
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_601200.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_601200, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_601200, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_601200.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601200, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601200, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601200, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_601200, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_601200.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_601199, "Action", newJString(Action))
  add(formData_601200, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_601200, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601200, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_601200, "EngineVersion", newJString(EngineVersion))
  add(query_601199, "Version", newJString(Version))
  add(formData_601200, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601198.call(nil, query_601199, nil, formData_601200, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_601171(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_601172, base: "/",
    url: url_PostModifyDBCluster_601173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_601142 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBCluster_601144(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBCluster_601143(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: JString (required)
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Port: JInt
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: JString (required)
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_601145 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "PreferredMaintenanceWindow", valid_601145
  var valid_601146 = query.getOrDefault("DBClusterParameterGroupName")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "DBClusterParameterGroupName", valid_601146
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_601147 = query.getOrDefault("DBClusterIdentifier")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = nil)
  if valid_601147 != nil:
    section.add "DBClusterIdentifier", valid_601147
  var valid_601148 = query.getOrDefault("MasterUserPassword")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "MasterUserPassword", valid_601148
  var valid_601149 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_601149 = validateParameter(valid_601149, JArray, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_601149
  var valid_601150 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601150 = validateParameter(valid_601150, JArray, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "VpcSecurityGroupIds", valid_601150
  var valid_601151 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_601151 = validateParameter(valid_601151, JArray, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_601151
  var valid_601152 = query.getOrDefault("BackupRetentionPeriod")
  valid_601152 = validateParameter(valid_601152, JInt, required = false, default = nil)
  if valid_601152 != nil:
    section.add "BackupRetentionPeriod", valid_601152
  var valid_601153 = query.getOrDefault("NewDBClusterIdentifier")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "NewDBClusterIdentifier", valid_601153
  var valid_601154 = query.getOrDefault("DeletionProtection")
  valid_601154 = validateParameter(valid_601154, JBool, required = false, default = nil)
  if valid_601154 != nil:
    section.add "DeletionProtection", valid_601154
  var valid_601155 = query.getOrDefault("Action")
  valid_601155 = validateParameter(valid_601155, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_601155 != nil:
    section.add "Action", valid_601155
  var valid_601156 = query.getOrDefault("EngineVersion")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "EngineVersion", valid_601156
  var valid_601157 = query.getOrDefault("Port")
  valid_601157 = validateParameter(valid_601157, JInt, required = false, default = nil)
  if valid_601157 != nil:
    section.add "Port", valid_601157
  var valid_601158 = query.getOrDefault("PreferredBackupWindow")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "PreferredBackupWindow", valid_601158
  var valid_601159 = query.getOrDefault("Version")
  valid_601159 = validateParameter(valid_601159, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601159 != nil:
    section.add "Version", valid_601159
  var valid_601160 = query.getOrDefault("ApplyImmediately")
  valid_601160 = validateParameter(valid_601160, JBool, required = false, default = nil)
  if valid_601160 != nil:
    section.add "ApplyImmediately", valid_601160
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601161 = header.getOrDefault("X-Amz-Date")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Date", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Security-Token")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Security-Token", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601168: Call_GetModifyDBCluster_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_601168.validator(path, query, header, formData, body)
  let scheme = call_601168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601168.url(scheme.get, call_601168.host, call_601168.base,
                         call_601168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601168, url, valid)

proc call*(call_601169: Call_GetModifyDBCluster_601142;
          DBClusterIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBClusterParameterGroupName: string = ""; MasterUserPassword: string = "";
          CloudwatchLogsExportConfigurationEnableLogTypes: JsonNode = nil;
          VpcSecurityGroupIds: JsonNode = nil;
          CloudwatchLogsExportConfigurationDisableLogTypes: JsonNode = nil;
          BackupRetentionPeriod: int = 0; NewDBClusterIdentifier: string = "";
          DeletionProtection: bool = false; Action: string = "ModifyDBCluster";
          EngineVersion: string = ""; Port: int = 0; PreferredBackupWindow: string = "";
          Version: string = "2014-10-31"; ApplyImmediately: bool = false): Recallable =
  ## getModifyDBCluster
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the DB cluster parameter group to use for the DB cluster.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The DB cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to enable.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the DB cluster will belong to.
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific DB instance or DB cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the DB engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: string (required)
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Port: int
  ##       : <p>The port number on which the DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original DB cluster.</p>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB cluster. If this parameter is set to <code>false</code>, changes to the DB cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  var query_601170 = newJObject()
  add(query_601170, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601170, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_601170, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601170, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_601170.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if VpcSecurityGroupIds != nil:
    query_601170.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_601170.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_601170, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601170, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_601170, "DeletionProtection", newJBool(DeletionProtection))
  add(query_601170, "Action", newJString(Action))
  add(query_601170, "EngineVersion", newJString(EngineVersion))
  add(query_601170, "Port", newJInt(Port))
  add(query_601170, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601170, "Version", newJString(Version))
  add(query_601170, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_601169.call(nil, query_601170, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_601142(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_601143,
    base: "/", url: url_GetModifyDBCluster_601144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_601218 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBClusterParameterGroup_601220(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBClusterParameterGroup_601219(path: JsonNode;
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
  var valid_601221 = query.getOrDefault("Action")
  valid_601221 = validateParameter(valid_601221, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_601221 != nil:
    section.add "Action", valid_601221
  var valid_601222 = query.getOrDefault("Version")
  valid_601222 = validateParameter(valid_601222, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601222 != nil:
    section.add "Version", valid_601222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601223 = header.getOrDefault("X-Amz-Date")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Date", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Security-Token")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Security-Token", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Content-Sha256", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Algorithm")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Algorithm", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Signature")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Signature", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-SignedHeaders", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Credential")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Credential", valid_601229
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_601230 = formData.getOrDefault("Parameters")
  valid_601230 = validateParameter(valid_601230, JArray, required = true, default = nil)
  if valid_601230 != nil:
    section.add "Parameters", valid_601230
  var valid_601231 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_601231 = validateParameter(valid_601231, JString, required = true,
                                 default = nil)
  if valid_601231 != nil:
    section.add "DBClusterParameterGroupName", valid_601231
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601232: Call_PostModifyDBClusterParameterGroup_601218;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_601232.validator(path, query, header, formData, body)
  let scheme = call_601232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601232.url(scheme.get, call_601232.host, call_601232.base,
                         call_601232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601232, url, valid)

proc call*(call_601233: Call_PostModifyDBClusterParameterGroup_601218;
          Parameters: JsonNode; DBClusterParameterGroupName: string;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to modify.
  ##   Version: string (required)
  var query_601234 = newJObject()
  var formData_601235 = newJObject()
  if Parameters != nil:
    formData_601235.add "Parameters", Parameters
  add(query_601234, "Action", newJString(Action))
  add(formData_601235, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_601234, "Version", newJString(Version))
  result = call_601233.call(nil, query_601234, nil, formData_601235, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_601218(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_601219, base: "/",
    url: url_PostModifyDBClusterParameterGroup_601220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_601201 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBClusterParameterGroup_601203(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBClusterParameterGroup_601202(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_601204 = query.getOrDefault("DBClusterParameterGroupName")
  valid_601204 = validateParameter(valid_601204, JString, required = true,
                                 default = nil)
  if valid_601204 != nil:
    section.add "DBClusterParameterGroupName", valid_601204
  var valid_601205 = query.getOrDefault("Parameters")
  valid_601205 = validateParameter(valid_601205, JArray, required = true, default = nil)
  if valid_601205 != nil:
    section.add "Parameters", valid_601205
  var valid_601206 = query.getOrDefault("Action")
  valid_601206 = validateParameter(valid_601206, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_601206 != nil:
    section.add "Action", valid_601206
  var valid_601207 = query.getOrDefault("Version")
  valid_601207 = validateParameter(valid_601207, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601207 != nil:
    section.add "Version", valid_601207
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601208 = header.getOrDefault("X-Amz-Date")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Date", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Security-Token")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Security-Token", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Content-Sha256", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Algorithm")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Algorithm", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Signature")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Signature", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-SignedHeaders", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Credential")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Credential", valid_601214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601215: Call_GetModifyDBClusterParameterGroup_601201;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_601215.validator(path, query, header, formData, body)
  let scheme = call_601215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601215.url(scheme.get, call_601215.host, call_601215.base,
                         call_601215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601215, url, valid)

proc call*(call_601216: Call_GetModifyDBClusterParameterGroup_601201;
          DBClusterParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to modify.
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601217 = newJObject()
  add(query_601217, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_601217.add "Parameters", Parameters
  add(query_601217, "Action", newJString(Action))
  add(query_601217, "Version", newJString(Version))
  result = call_601216.call(nil, query_601217, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_601201(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_601202, base: "/",
    url: url_GetModifyDBClusterParameterGroup_601203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_601255 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBClusterSnapshotAttribute_601257(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBClusterSnapshotAttribute_601256(path: JsonNode;
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
  var valid_601258 = query.getOrDefault("Action")
  valid_601258 = validateParameter(valid_601258, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_601258 != nil:
    section.add "Action", valid_601258
  var valid_601259 = query.getOrDefault("Version")
  valid_601259 = validateParameter(valid_601259, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601259 != nil:
    section.add "Version", valid_601259
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601260 = header.getOrDefault("X-Amz-Date")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Date", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Security-Token")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Security-Token", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Content-Sha256", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Algorithm")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Algorithm", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Signature")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Signature", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-SignedHeaders", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Credential")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Credential", valid_601266
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_601267 = formData.getOrDefault("AttributeName")
  valid_601267 = validateParameter(valid_601267, JString, required = true,
                                 default = nil)
  if valid_601267 != nil:
    section.add "AttributeName", valid_601267
  var valid_601268 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601268 = validateParameter(valid_601268, JString, required = true,
                                 default = nil)
  if valid_601268 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601268
  var valid_601269 = formData.getOrDefault("ValuesToRemove")
  valid_601269 = validateParameter(valid_601269, JArray, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "ValuesToRemove", valid_601269
  var valid_601270 = formData.getOrDefault("ValuesToAdd")
  valid_601270 = validateParameter(valid_601270, JArray, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "ValuesToAdd", valid_601270
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601271: Call_PostModifyDBClusterSnapshotAttribute_601255;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_601271.validator(path, query, header, formData, body)
  let scheme = call_601271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601271.url(scheme.get, call_601271.host, call_601271.base,
                         call_601271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601271, url, valid)

proc call*(call_601272: Call_PostModifyDBClusterSnapshotAttribute_601255;
          AttributeName: string; DBClusterSnapshotIdentifier: string;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToRemove: JsonNode = nil; ValuesToAdd: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   AttributeName: string (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   Action: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Version: string (required)
  var query_601273 = newJObject()
  var formData_601274 = newJObject()
  add(formData_601274, "AttributeName", newJString(AttributeName))
  add(formData_601274, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_601273, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_601274.add "ValuesToRemove", ValuesToRemove
  if ValuesToAdd != nil:
    formData_601274.add "ValuesToAdd", ValuesToAdd
  add(query_601273, "Version", newJString(Version))
  result = call_601272.call(nil, query_601273, nil, formData_601274, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_601255(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_601256, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_601257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_601236 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBClusterSnapshotAttribute_601238(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBClusterSnapshotAttribute_601237(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeName: JString (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Action: JString (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AttributeName` field"
  var valid_601239 = query.getOrDefault("AttributeName")
  valid_601239 = validateParameter(valid_601239, JString, required = true,
                                 default = nil)
  if valid_601239 != nil:
    section.add "AttributeName", valid_601239
  var valid_601240 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_601240 = validateParameter(valid_601240, JString, required = true,
                                 default = nil)
  if valid_601240 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_601240
  var valid_601241 = query.getOrDefault("ValuesToAdd")
  valid_601241 = validateParameter(valid_601241, JArray, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "ValuesToAdd", valid_601241
  var valid_601242 = query.getOrDefault("Action")
  valid_601242 = validateParameter(valid_601242, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_601242 != nil:
    section.add "Action", valid_601242
  var valid_601243 = query.getOrDefault("ValuesToRemove")
  valid_601243 = validateParameter(valid_601243, JArray, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "ValuesToRemove", valid_601243
  var valid_601244 = query.getOrDefault("Version")
  valid_601244 = validateParameter(valid_601244, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601244 != nil:
    section.add "Version", valid_601244
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601245 = header.getOrDefault("X-Amz-Date")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Date", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Security-Token")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Security-Token", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Content-Sha256", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Algorithm")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Algorithm", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Signature")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Signature", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-SignedHeaders", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Credential")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Credential", valid_601251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601252: Call_GetModifyDBClusterSnapshotAttribute_601236;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_601252.validator(path, query, header, formData, body)
  let scheme = call_601252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601252.url(scheme.get, call_601252.host, call_601252.base,
                         call_601252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601252, url, valid)

proc call*(call_601253: Call_GetModifyDBClusterSnapshotAttribute_601236;
          AttributeName: string; DBClusterSnapshotIdentifier: string;
          ValuesToAdd: JsonNode = nil;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToRemove: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   AttributeName: string (required)
  ##                : <p>The name of the DB cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to modify the attributes for.
  ##   ValuesToAdd: JArray
  ##              : <p>A list of DB cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account IDs. To make the manual DB cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Action: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of DB cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the DB cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual DB cluster snapshot.</p>
  ##   Version: string (required)
  var query_601254 = newJObject()
  add(query_601254, "AttributeName", newJString(AttributeName))
  add(query_601254, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if ValuesToAdd != nil:
    query_601254.add "ValuesToAdd", ValuesToAdd
  add(query_601254, "Action", newJString(Action))
  if ValuesToRemove != nil:
    query_601254.add "ValuesToRemove", ValuesToRemove
  add(query_601254, "Version", newJString(Version))
  result = call_601253.call(nil, query_601254, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_601236(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_601237, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_601238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_601298 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBInstance_601300(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_601299(path: JsonNode; query: JsonNode;
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
  var valid_601301 = query.getOrDefault("Action")
  valid_601301 = validateParameter(valid_601301, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_601301 != nil:
    section.add "Action", valid_601301
  var valid_601302 = query.getOrDefault("Version")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601302 != nil:
    section.add "Version", valid_601302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601303 = header.getOrDefault("X-Amz-Date")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Date", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Security-Token")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Security-Token", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Content-Sha256", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Algorithm")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Algorithm", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Signature")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Signature", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-SignedHeaders", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Credential")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Credential", valid_601309
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  section = newJObject()
  var valid_601310 = formData.getOrDefault("ApplyImmediately")
  valid_601310 = validateParameter(valid_601310, JBool, required = false, default = nil)
  if valid_601310 != nil:
    section.add "ApplyImmediately", valid_601310
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601311 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601311 = validateParameter(valid_601311, JString, required = true,
                                 default = nil)
  if valid_601311 != nil:
    section.add "DBInstanceIdentifier", valid_601311
  var valid_601312 = formData.getOrDefault("CACertificateIdentifier")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "CACertificateIdentifier", valid_601312
  var valid_601313 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "NewDBInstanceIdentifier", valid_601313
  var valid_601314 = formData.getOrDefault("PromotionTier")
  valid_601314 = validateParameter(valid_601314, JInt, required = false, default = nil)
  if valid_601314 != nil:
    section.add "PromotionTier", valid_601314
  var valid_601315 = formData.getOrDefault("DBInstanceClass")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "DBInstanceClass", valid_601315
  var valid_601316 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601316 = validateParameter(valid_601316, JBool, required = false, default = nil)
  if valid_601316 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601316
  var valid_601317 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "PreferredMaintenanceWindow", valid_601317
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601318: Call_PostModifyDBInstance_601298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_601318.validator(path, query, header, formData, body)
  let scheme = call_601318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601318.url(scheme.get, call_601318.host, call_601318.base,
                         call_601318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601318, url, valid)

proc call*(call_601319: Call_PostModifyDBInstance_601298;
          DBInstanceIdentifier: string; ApplyImmediately: bool = false;
          CACertificateIdentifier: string = "";
          NewDBInstanceIdentifier: string = ""; Action: string = "ModifyDBInstance";
          PromotionTier: int = 0; DBInstanceClass: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31";
          PreferredMaintenanceWindow: string = ""): Recallable =
  ## postModifyDBInstance
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Action: string (required)
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  var query_601320 = newJObject()
  var formData_601321 = newJObject()
  add(formData_601321, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_601321, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601321, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(formData_601321, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_601320, "Action", newJString(Action))
  add(formData_601321, "PromotionTier", newJInt(PromotionTier))
  add(formData_601321, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601321, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601320, "Version", newJString(Version))
  add(formData_601321, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601319.call(nil, query_601320, nil, formData_601321, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_601298(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_601299, base: "/",
    url: url_PostModifyDBInstance_601300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_601275 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBInstance_601277(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_601276(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CACertificateIdentifier: JString
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   Action: JString (required)
  ##   NewDBInstanceIdentifier: JString
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_601278 = query.getOrDefault("CACertificateIdentifier")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "CACertificateIdentifier", valid_601278
  var valid_601279 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "PreferredMaintenanceWindow", valid_601279
  var valid_601280 = query.getOrDefault("PromotionTier")
  valid_601280 = validateParameter(valid_601280, JInt, required = false, default = nil)
  if valid_601280 != nil:
    section.add "PromotionTier", valid_601280
  var valid_601281 = query.getOrDefault("DBInstanceClass")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "DBInstanceClass", valid_601281
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601282 = query.getOrDefault("Action")
  valid_601282 = validateParameter(valid_601282, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_601282 != nil:
    section.add "Action", valid_601282
  var valid_601283 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "NewDBInstanceIdentifier", valid_601283
  var valid_601284 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601284 = validateParameter(valid_601284, JBool, required = false, default = nil)
  if valid_601284 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601284
  var valid_601285 = query.getOrDefault("Version")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601285 != nil:
    section.add "Version", valid_601285
  var valid_601286 = query.getOrDefault("DBInstanceIdentifier")
  valid_601286 = validateParameter(valid_601286, JString, required = true,
                                 default = nil)
  if valid_601286 != nil:
    section.add "DBInstanceIdentifier", valid_601286
  var valid_601287 = query.getOrDefault("ApplyImmediately")
  valid_601287 = validateParameter(valid_601287, JBool, required = false, default = nil)
  if valid_601287 != nil:
    section.add "ApplyImmediately", valid_601287
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601288 = header.getOrDefault("X-Amz-Date")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Date", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Security-Token")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Security-Token", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Content-Sha256", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Algorithm")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Algorithm", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Signature")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Signature", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-SignedHeaders", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Credential")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Credential", valid_601294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601295: Call_GetModifyDBInstance_601275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_601295.validator(path, query, header, formData, body)
  let scheme = call_601295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601295.url(scheme.get, call_601295.host, call_601295.base,
                         call_601295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601295, url, valid)

proc call*(call_601296: Call_GetModifyDBInstance_601275;
          DBInstanceIdentifier: string; CACertificateIdentifier: string = "";
          PreferredMaintenanceWindow: string = ""; PromotionTier: int = 0;
          DBInstanceClass: string = ""; Action: string = "ModifyDBInstance";
          NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBInstance
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ##   CACertificateIdentifier: string
  ##                          : Indicates the certificate that needs to be associated with the instance.
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the DB instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. Not all DB instance classes are available in all AWS Regions. </p> <p>If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   Action: string (required)
  ##   NewDBInstanceIdentifier: string
  ##                          : <p> The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot occurs immediately if you set <code>Apply Immediately</code> to <code>true</code>. It occurs during the next maintenance window if you set <code>Apply Immediately</code> to <code>false</code>. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ApplyImmediately: bool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  var query_601297 = newJObject()
  add(query_601297, "CACertificateIdentifier", newJString(CACertificateIdentifier))
  add(query_601297, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601297, "PromotionTier", newJInt(PromotionTier))
  add(query_601297, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601297, "Action", newJString(Action))
  add(query_601297, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_601297, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601297, "Version", newJString(Version))
  add(query_601297, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601297, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_601296.call(nil, query_601297, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_601275(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_601276, base: "/",
    url: url_GetModifyDBInstance_601277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_601340 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBSubnetGroup_601342(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_601341(path: JsonNode; query: JsonNode;
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
  var valid_601343 = query.getOrDefault("Action")
  valid_601343 = validateParameter(valid_601343, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_601343 != nil:
    section.add "Action", valid_601343
  var valid_601344 = query.getOrDefault("Version")
  valid_601344 = validateParameter(valid_601344, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601344 != nil:
    section.add "Version", valid_601344
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601345 = header.getOrDefault("X-Amz-Date")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Date", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Security-Token")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Security-Token", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Content-Sha256", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Algorithm")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Algorithm", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Signature")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Signature", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-SignedHeaders", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Credential")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Credential", valid_601351
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the DB subnet group.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601352 = formData.getOrDefault("DBSubnetGroupName")
  valid_601352 = validateParameter(valid_601352, JString, required = true,
                                 default = nil)
  if valid_601352 != nil:
    section.add "DBSubnetGroupName", valid_601352
  var valid_601353 = formData.getOrDefault("SubnetIds")
  valid_601353 = validateParameter(valid_601353, JArray, required = true, default = nil)
  if valid_601353 != nil:
    section.add "SubnetIds", valid_601353
  var valid_601354 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "DBSubnetGroupDescription", valid_601354
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601355: Call_PostModifyDBSubnetGroup_601340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_601355.validator(path, query, header, formData, body)
  let scheme = call_601355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601355.url(scheme.get, call_601355.host, call_601355.base,
                         call_601355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601355, url, valid)

proc call*(call_601356: Call_PostModifyDBSubnetGroup_601340;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-10-31"): Recallable =
  ## postModifyDBSubnetGroup
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the DB subnet group.
  ##   Version: string (required)
  var query_601357 = newJObject()
  var formData_601358 = newJObject()
  add(formData_601358, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601358.add "SubnetIds", SubnetIds
  add(query_601357, "Action", newJString(Action))
  add(formData_601358, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601357, "Version", newJString(Version))
  result = call_601356.call(nil, query_601357, nil, formData_601358, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_601340(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_601341, base: "/",
    url: url_PostModifyDBSubnetGroup_601342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_601322 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBSubnetGroup_601324(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_601323(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the DB subnet group.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601325 = query.getOrDefault("Action")
  valid_601325 = validateParameter(valid_601325, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_601325 != nil:
    section.add "Action", valid_601325
  var valid_601326 = query.getOrDefault("DBSubnetGroupName")
  valid_601326 = validateParameter(valid_601326, JString, required = true,
                                 default = nil)
  if valid_601326 != nil:
    section.add "DBSubnetGroupName", valid_601326
  var valid_601327 = query.getOrDefault("SubnetIds")
  valid_601327 = validateParameter(valid_601327, JArray, required = true, default = nil)
  if valid_601327 != nil:
    section.add "SubnetIds", valid_601327
  var valid_601328 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "DBSubnetGroupDescription", valid_601328
  var valid_601329 = query.getOrDefault("Version")
  valid_601329 = validateParameter(valid_601329, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601329 != nil:
    section.add "Version", valid_601329
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601330 = header.getOrDefault("X-Amz-Date")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Date", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Security-Token")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Security-Token", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Content-Sha256", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Algorithm")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Algorithm", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Signature")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Signature", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-SignedHeaders", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Credential")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Credential", valid_601336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601337: Call_GetModifyDBSubnetGroup_601322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_601337.validator(path, query, header, formData, body)
  let scheme = call_601337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601337.url(scheme.get, call_601337.host, call_601337.base,
                         call_601337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601337, url, valid)

proc call*(call_601338: Call_GetModifyDBSubnetGroup_601322;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBSubnetGroup
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the DB subnet group.
  ##   Version: string (required)
  var query_601339 = newJObject()
  add(query_601339, "Action", newJString(Action))
  add(query_601339, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601339.add "SubnetIds", SubnetIds
  add(query_601339, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601339, "Version", newJString(Version))
  result = call_601338.call(nil, query_601339, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_601322(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_601323, base: "/",
    url: url_GetModifyDBSubnetGroup_601324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_601376 = ref object of OpenApiRestCall_599352
proc url_PostRebootDBInstance_601378(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_601377(path: JsonNode; query: JsonNode;
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
  var valid_601379 = query.getOrDefault("Action")
  valid_601379 = validateParameter(valid_601379, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_601379 != nil:
    section.add "Action", valid_601379
  var valid_601380 = query.getOrDefault("Version")
  valid_601380 = validateParameter(valid_601380, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601380 != nil:
    section.add "Version", valid_601380
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601381 = header.getOrDefault("X-Amz-Date")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Date", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Security-Token")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Security-Token", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Content-Sha256", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Algorithm")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Algorithm", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Signature")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Signature", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-SignedHeaders", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Credential")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Credential", valid_601387
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601388 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601388 = validateParameter(valid_601388, JString, required = true,
                                 default = nil)
  if valid_601388 != nil:
    section.add "DBInstanceIdentifier", valid_601388
  var valid_601389 = formData.getOrDefault("ForceFailover")
  valid_601389 = validateParameter(valid_601389, JBool, required = false, default = nil)
  if valid_601389 != nil:
    section.add "ForceFailover", valid_601389
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601390: Call_PostRebootDBInstance_601376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_601390.validator(path, query, header, formData, body)
  let scheme = call_601390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601390.url(scheme.get, call_601390.host, call_601390.base,
                         call_601390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601390, url, valid)

proc call*(call_601391: Call_PostRebootDBInstance_601376;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-10-31"): Recallable =
  ## postRebootDBInstance
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   Version: string (required)
  var query_601392 = newJObject()
  var formData_601393 = newJObject()
  add(formData_601393, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601392, "Action", newJString(Action))
  add(formData_601393, "ForceFailover", newJBool(ForceFailover))
  add(query_601392, "Version", newJString(Version))
  result = call_601391.call(nil, query_601392, nil, formData_601393, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_601376(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_601377, base: "/",
    url: url_PostRebootDBInstance_601378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_601359 = ref object of OpenApiRestCall_599352
proc url_GetRebootDBInstance_601361(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_601360(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
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
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601362 = query.getOrDefault("Action")
  valid_601362 = validateParameter(valid_601362, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_601362 != nil:
    section.add "Action", valid_601362
  var valid_601363 = query.getOrDefault("ForceFailover")
  valid_601363 = validateParameter(valid_601363, JBool, required = false, default = nil)
  if valid_601363 != nil:
    section.add "ForceFailover", valid_601363
  var valid_601364 = query.getOrDefault("Version")
  valid_601364 = validateParameter(valid_601364, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601364 != nil:
    section.add "Version", valid_601364
  var valid_601365 = query.getOrDefault("DBInstanceIdentifier")
  valid_601365 = validateParameter(valid_601365, JString, required = true,
                                 default = nil)
  if valid_601365 != nil:
    section.add "DBInstanceIdentifier", valid_601365
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601366 = header.getOrDefault("X-Amz-Date")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Date", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Security-Token")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Security-Token", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Content-Sha256", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Algorithm")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Algorithm", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Signature")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Signature", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-SignedHeaders", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Credential")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Credential", valid_601372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601373: Call_GetRebootDBInstance_601359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_601373.validator(path, query, header, formData, body)
  let scheme = call_601373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601373.url(scheme.get, call_601373.host, call_601373.base,
                         call_601373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601373, url, valid)

proc call*(call_601374: Call_GetRebootDBInstance_601359;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getRebootDBInstance
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  var query_601375 = newJObject()
  add(query_601375, "Action", newJString(Action))
  add(query_601375, "ForceFailover", newJBool(ForceFailover))
  add(query_601375, "Version", newJString(Version))
  add(query_601375, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601374.call(nil, query_601375, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_601359(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_601360, base: "/",
    url: url_GetRebootDBInstance_601361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_601411 = ref object of OpenApiRestCall_599352
proc url_PostRemoveTagsFromResource_601413(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_601412(path: JsonNode; query: JsonNode;
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
  var valid_601414 = query.getOrDefault("Action")
  valid_601414 = validateParameter(valid_601414, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_601414 != nil:
    section.add "Action", valid_601414
  var valid_601415 = query.getOrDefault("Version")
  valid_601415 = validateParameter(valid_601415, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601415 != nil:
    section.add "Version", valid_601415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601416 = header.getOrDefault("X-Amz-Date")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Date", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Security-Token")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Security-Token", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Content-Sha256", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Algorithm")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Algorithm", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Signature")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Signature", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-SignedHeaders", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Credential")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Credential", valid_601422
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_601423 = formData.getOrDefault("TagKeys")
  valid_601423 = validateParameter(valid_601423, JArray, required = true, default = nil)
  if valid_601423 != nil:
    section.add "TagKeys", valid_601423
  var valid_601424 = formData.getOrDefault("ResourceName")
  valid_601424 = validateParameter(valid_601424, JString, required = true,
                                 default = nil)
  if valid_601424 != nil:
    section.add "ResourceName", valid_601424
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601425: Call_PostRemoveTagsFromResource_601411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_601425.validator(path, query, header, formData, body)
  let scheme = call_601425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601425.url(scheme.get, call_601425.host, call_601425.base,
                         call_601425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601425, url, valid)

proc call*(call_601426: Call_PostRemoveTagsFromResource_601411; TagKeys: JsonNode;
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
  var query_601427 = newJObject()
  var formData_601428 = newJObject()
  add(query_601427, "Action", newJString(Action))
  if TagKeys != nil:
    formData_601428.add "TagKeys", TagKeys
  add(formData_601428, "ResourceName", newJString(ResourceName))
  add(query_601427, "Version", newJString(Version))
  result = call_601426.call(nil, query_601427, nil, formData_601428, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_601411(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_601412, base: "/",
    url: url_PostRemoveTagsFromResource_601413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_601394 = ref object of OpenApiRestCall_599352
proc url_GetRemoveTagsFromResource_601396(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_601395(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_601397 = query.getOrDefault("ResourceName")
  valid_601397 = validateParameter(valid_601397, JString, required = true,
                                 default = nil)
  if valid_601397 != nil:
    section.add "ResourceName", valid_601397
  var valid_601398 = query.getOrDefault("Action")
  valid_601398 = validateParameter(valid_601398, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_601398 != nil:
    section.add "Action", valid_601398
  var valid_601399 = query.getOrDefault("TagKeys")
  valid_601399 = validateParameter(valid_601399, JArray, required = true, default = nil)
  if valid_601399 != nil:
    section.add "TagKeys", valid_601399
  var valid_601400 = query.getOrDefault("Version")
  valid_601400 = validateParameter(valid_601400, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601400 != nil:
    section.add "Version", valid_601400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601401 = header.getOrDefault("X-Amz-Date")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Date", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Security-Token")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Security-Token", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Content-Sha256", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Algorithm")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Algorithm", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Signature")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Signature", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-SignedHeaders", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Credential")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Credential", valid_601407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601408: Call_GetRemoveTagsFromResource_601394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_601408.validator(path, query, header, formData, body)
  let scheme = call_601408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601408.url(scheme.get, call_601408.host, call_601408.base,
                         call_601408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601408, url, valid)

proc call*(call_601409: Call_GetRemoveTagsFromResource_601394;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-10-31"): Recallable =
  ## getRemoveTagsFromResource
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   Version: string (required)
  var query_601410 = newJObject()
  add(query_601410, "ResourceName", newJString(ResourceName))
  add(query_601410, "Action", newJString(Action))
  if TagKeys != nil:
    query_601410.add "TagKeys", TagKeys
  add(query_601410, "Version", newJString(Version))
  result = call_601409.call(nil, query_601410, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_601394(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_601395, base: "/",
    url: url_GetRemoveTagsFromResource_601396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_601447 = ref object of OpenApiRestCall_599352
proc url_PostResetDBClusterParameterGroup_601449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBClusterParameterGroup_601448(path: JsonNode;
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
  var valid_601450 = query.getOrDefault("Action")
  valid_601450 = validateParameter(valid_601450, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_601450 != nil:
    section.add "Action", valid_601450
  var valid_601451 = query.getOrDefault("Version")
  valid_601451 = validateParameter(valid_601451, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601451 != nil:
    section.add "Version", valid_601451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601452 = header.getOrDefault("X-Amz-Date")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Date", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Security-Token")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Security-Token", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Content-Sha256", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Algorithm")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Algorithm", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Signature")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Signature", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-SignedHeaders", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Credential")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Credential", valid_601458
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  section = newJObject()
  var valid_601459 = formData.getOrDefault("Parameters")
  valid_601459 = validateParameter(valid_601459, JArray, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "Parameters", valid_601459
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_601460 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_601460 = validateParameter(valid_601460, JString, required = true,
                                 default = nil)
  if valid_601460 != nil:
    section.add "DBClusterParameterGroupName", valid_601460
  var valid_601461 = formData.getOrDefault("ResetAllParameters")
  valid_601461 = validateParameter(valid_601461, JBool, required = false, default = nil)
  if valid_601461 != nil:
    section.add "ResetAllParameters", valid_601461
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601462: Call_PostResetDBClusterParameterGroup_601447;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_601462.validator(path, query, header, formData, body)
  let scheme = call_601462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601462.url(scheme.get, call_601462.host, call_601462.base,
                         call_601462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601462, url, valid)

proc call*(call_601463: Call_PostResetDBClusterParameterGroup_601447;
          DBClusterParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBClusterParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-10-31"): Recallable =
  ## postResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Version: string (required)
  var query_601464 = newJObject()
  var formData_601465 = newJObject()
  if Parameters != nil:
    formData_601465.add "Parameters", Parameters
  add(query_601464, "Action", newJString(Action))
  add(formData_601465, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_601465, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_601464, "Version", newJString(Version))
  result = call_601463.call(nil, query_601464, nil, formData_601465, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_601447(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_601448, base: "/",
    url: url_PostResetDBClusterParameterGroup_601449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_601429 = ref object of OpenApiRestCall_599352
proc url_GetResetDBClusterParameterGroup_601431(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBClusterParameterGroup_601430(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   Action: JString (required)
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_601432 = query.getOrDefault("DBClusterParameterGroupName")
  valid_601432 = validateParameter(valid_601432, JString, required = true,
                                 default = nil)
  if valid_601432 != nil:
    section.add "DBClusterParameterGroupName", valid_601432
  var valid_601433 = query.getOrDefault("Parameters")
  valid_601433 = validateParameter(valid_601433, JArray, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "Parameters", valid_601433
  var valid_601434 = query.getOrDefault("Action")
  valid_601434 = validateParameter(valid_601434, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_601434 != nil:
    section.add "Action", valid_601434
  var valid_601435 = query.getOrDefault("ResetAllParameters")
  valid_601435 = validateParameter(valid_601435, JBool, required = false, default = nil)
  if valid_601435 != nil:
    section.add "ResetAllParameters", valid_601435
  var valid_601436 = query.getOrDefault("Version")
  valid_601436 = validateParameter(valid_601436, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601436 != nil:
    section.add "Version", valid_601436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601437 = header.getOrDefault("X-Amz-Date")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Date", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Security-Token")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Security-Token", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Content-Sha256", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Algorithm")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Algorithm", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Signature")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Signature", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-SignedHeaders", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Credential")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Credential", valid_601443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601444: Call_GetResetDBClusterParameterGroup_601429;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_601444.validator(path, query, header, formData, body)
  let scheme = call_601444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601444.url(scheme.get, call_601444.host, call_601444.base,
                         call_601444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601444, url, valid)

proc call*(call_601445: Call_GetResetDBClusterParameterGroup_601429;
          DBClusterParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBClusterParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getResetDBClusterParameterGroup
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ##   DBClusterParameterGroupName: string (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Version: string (required)
  var query_601446 = newJObject()
  add(query_601446, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_601446.add "Parameters", Parameters
  add(query_601446, "Action", newJString(Action))
  add(query_601446, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_601446, "Version", newJString(Version))
  result = call_601445.call(nil, query_601446, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_601429(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_601430, base: "/",
    url: url_GetResetDBClusterParameterGroup_601431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_601493 = ref object of OpenApiRestCall_599352
proc url_PostRestoreDBClusterFromSnapshot_601495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBClusterFromSnapshot_601494(path: JsonNode;
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
  var valid_601496 = query.getOrDefault("Action")
  valid_601496 = validateParameter(valid_601496, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_601496 != nil:
    section.add "Action", valid_601496
  var valid_601497 = query.getOrDefault("Version")
  valid_601497 = validateParameter(valid_601497, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601497 != nil:
    section.add "Version", valid_601497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601498 = header.getOrDefault("X-Amz-Date")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Date", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Security-Token")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Security-Token", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Content-Sha256", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Algorithm")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Algorithm", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Signature")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Signature", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-SignedHeaders", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Credential")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Credential", valid_601504
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new DB cluster.
  section = newJObject()
  var valid_601505 = formData.getOrDefault("Port")
  valid_601505 = validateParameter(valid_601505, JInt, required = false, default = nil)
  if valid_601505 != nil:
    section.add "Port", valid_601505
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_601506 = formData.getOrDefault("Engine")
  valid_601506 = validateParameter(valid_601506, JString, required = true,
                                 default = nil)
  if valid_601506 != nil:
    section.add "Engine", valid_601506
  var valid_601507 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601507 = validateParameter(valid_601507, JArray, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "VpcSecurityGroupIds", valid_601507
  var valid_601508 = formData.getOrDefault("Tags")
  valid_601508 = validateParameter(valid_601508, JArray, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "Tags", valid_601508
  var valid_601509 = formData.getOrDefault("DeletionProtection")
  valid_601509 = validateParameter(valid_601509, JBool, required = false, default = nil)
  if valid_601509 != nil:
    section.add "DeletionProtection", valid_601509
  var valid_601510 = formData.getOrDefault("DBSubnetGroupName")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "DBSubnetGroupName", valid_601510
  var valid_601511 = formData.getOrDefault("AvailabilityZones")
  valid_601511 = validateParameter(valid_601511, JArray, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "AvailabilityZones", valid_601511
  var valid_601512 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_601512 = validateParameter(valid_601512, JArray, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "EnableCloudwatchLogsExports", valid_601512
  var valid_601513 = formData.getOrDefault("KmsKeyId")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "KmsKeyId", valid_601513
  var valid_601514 = formData.getOrDefault("SnapshotIdentifier")
  valid_601514 = validateParameter(valid_601514, JString, required = true,
                                 default = nil)
  if valid_601514 != nil:
    section.add "SnapshotIdentifier", valid_601514
  var valid_601515 = formData.getOrDefault("DBClusterIdentifier")
  valid_601515 = validateParameter(valid_601515, JString, required = true,
                                 default = nil)
  if valid_601515 != nil:
    section.add "DBClusterIdentifier", valid_601515
  var valid_601516 = formData.getOrDefault("EngineVersion")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "EngineVersion", valid_601516
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601517: Call_PostRestoreDBClusterFromSnapshot_601493;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_601517.validator(path, query, header, formData, body)
  let scheme = call_601517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601517.url(scheme.get, call_601517.host, call_601517.base,
                         call_601517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601517, url, valid)

proc call*(call_601518: Call_PostRestoreDBClusterFromSnapshot_601493;
          Engine: string; SnapshotIdentifier: string; DBClusterIdentifier: string;
          Port: int = 0; VpcSecurityGroupIds: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false; DBSubnetGroupName: string = "";
          Action: string = "RestoreDBClusterFromSnapshot";
          AvailabilityZones: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; KmsKeyId: string = "";
          EngineVersion: string = ""; Version: string = "2014-10-31"): Recallable =
  ## postRestoreDBClusterFromSnapshot
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new DB cluster.
  ##   Version: string (required)
  var query_601519 = newJObject()
  var formData_601520 = newJObject()
  add(formData_601520, "Port", newJInt(Port))
  add(formData_601520, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_601520.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if Tags != nil:
    formData_601520.add "Tags", Tags
  add(formData_601520, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_601520, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601519, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_601520.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    formData_601520.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_601520, "KmsKeyId", newJString(KmsKeyId))
  add(formData_601520, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(formData_601520, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_601520, "EngineVersion", newJString(EngineVersion))
  add(query_601519, "Version", newJString(Version))
  result = call_601518.call(nil, query_601519, nil, formData_601520, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_601493(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_601494, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_601495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_601466 = ref object of OpenApiRestCall_599352
proc url_GetRestoreDBClusterFromSnapshot_601468(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBClusterFromSnapshot_601467(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new DB cluster.
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_601469 = query.getOrDefault("Engine")
  valid_601469 = validateParameter(valid_601469, JString, required = true,
                                 default = nil)
  if valid_601469 != nil:
    section.add "Engine", valid_601469
  var valid_601470 = query.getOrDefault("AvailabilityZones")
  valid_601470 = validateParameter(valid_601470, JArray, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "AvailabilityZones", valid_601470
  var valid_601471 = query.getOrDefault("DBClusterIdentifier")
  valid_601471 = validateParameter(valid_601471, JString, required = true,
                                 default = nil)
  if valid_601471 != nil:
    section.add "DBClusterIdentifier", valid_601471
  var valid_601472 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601472 = validateParameter(valid_601472, JArray, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "VpcSecurityGroupIds", valid_601472
  var valid_601473 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_601473 = validateParameter(valid_601473, JArray, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "EnableCloudwatchLogsExports", valid_601473
  var valid_601474 = query.getOrDefault("Tags")
  valid_601474 = validateParameter(valid_601474, JArray, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "Tags", valid_601474
  var valid_601475 = query.getOrDefault("DeletionProtection")
  valid_601475 = validateParameter(valid_601475, JBool, required = false, default = nil)
  if valid_601475 != nil:
    section.add "DeletionProtection", valid_601475
  var valid_601476 = query.getOrDefault("Action")
  valid_601476 = validateParameter(valid_601476, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_601476 != nil:
    section.add "Action", valid_601476
  var valid_601477 = query.getOrDefault("DBSubnetGroupName")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "DBSubnetGroupName", valid_601477
  var valid_601478 = query.getOrDefault("KmsKeyId")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "KmsKeyId", valid_601478
  var valid_601479 = query.getOrDefault("EngineVersion")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "EngineVersion", valid_601479
  var valid_601480 = query.getOrDefault("Port")
  valid_601480 = validateParameter(valid_601480, JInt, required = false, default = nil)
  if valid_601480 != nil:
    section.add "Port", valid_601480
  var valid_601481 = query.getOrDefault("SnapshotIdentifier")
  valid_601481 = validateParameter(valid_601481, JString, required = true,
                                 default = nil)
  if valid_601481 != nil:
    section.add "SnapshotIdentifier", valid_601481
  var valid_601482 = query.getOrDefault("Version")
  valid_601482 = validateParameter(valid_601482, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601482 != nil:
    section.add "Version", valid_601482
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601483 = header.getOrDefault("X-Amz-Date")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Date", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Security-Token")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Security-Token", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Content-Sha256", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Algorithm")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Algorithm", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Signature")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Signature", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-SignedHeaders", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Credential")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Credential", valid_601489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601490: Call_GetRestoreDBClusterFromSnapshot_601466;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_601490.validator(path, query, header, formData, body)
  let scheme = call_601490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601490.url(scheme.get, call_601490.host, call_601490.base,
                         call_601490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601490, url, valid)

proc call*(call_601491: Call_GetRestoreDBClusterFromSnapshot_601466;
          Engine: string; DBClusterIdentifier: string; SnapshotIdentifier: string;
          AvailabilityZones: JsonNode = nil; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false;
          Action: string = "RestoreDBClusterFromSnapshot";
          DBSubnetGroupName: string = ""; KmsKeyId: string = "";
          EngineVersion: string = ""; Port: int = 0; Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterFromSnapshot
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new DB cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
  ##   AvailabilityZones: JArray
  ##                    : Provides the list of Amazon EC2 Availability Zones that instances in the restored DB cluster can be created in.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-snapshot-id</code> </p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the new DB cluster will belong to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the DB subnet group to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB snapshot or DB cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the DB snapshot or the DB cluster snapshot.</p> </li> <li> <p>If the DB snapshot or the DB cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new DB cluster.
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original DB cluster.</p>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the DB snapshot or DB cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Version: string (required)
  var query_601492 = newJObject()
  add(query_601492, "Engine", newJString(Engine))
  if AvailabilityZones != nil:
    query_601492.add "AvailabilityZones", AvailabilityZones
  add(query_601492, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_601492.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_601492.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_601492.add "Tags", Tags
  add(query_601492, "DeletionProtection", newJBool(DeletionProtection))
  add(query_601492, "Action", newJString(Action))
  add(query_601492, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601492, "KmsKeyId", newJString(KmsKeyId))
  add(query_601492, "EngineVersion", newJString(EngineVersion))
  add(query_601492, "Port", newJInt(Port))
  add(query_601492, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(query_601492, "Version", newJString(Version))
  result = call_601491.call(nil, query_601492, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_601466(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_601467, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_601468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_601547 = ref object of OpenApiRestCall_599352
proc url_PostRestoreDBClusterToPointInTime_601549(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBClusterToPointInTime_601548(path: JsonNode;
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
  var valid_601550 = query.getOrDefault("Action")
  valid_601550 = validateParameter(valid_601550, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_601550 != nil:
    section.add "Action", valid_601550
  var valid_601551 = query.getOrDefault("Version")
  valid_601551 = validateParameter(valid_601551, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601551 != nil:
    section.add "Version", valid_601551
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601552 = header.getOrDefault("X-Amz-Date")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Date", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Security-Token")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Security-Token", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Content-Sha256", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Algorithm")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Algorithm", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Signature")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Signature", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-SignedHeaders", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Credential")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Credential", valid_601558
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterIdentifier` field"
  var valid_601559 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_601559 = validateParameter(valid_601559, JString, required = true,
                                 default = nil)
  if valid_601559 != nil:
    section.add "SourceDBClusterIdentifier", valid_601559
  var valid_601560 = formData.getOrDefault("UseLatestRestorableTime")
  valid_601560 = validateParameter(valid_601560, JBool, required = false, default = nil)
  if valid_601560 != nil:
    section.add "UseLatestRestorableTime", valid_601560
  var valid_601561 = formData.getOrDefault("Port")
  valid_601561 = validateParameter(valid_601561, JInt, required = false, default = nil)
  if valid_601561 != nil:
    section.add "Port", valid_601561
  var valid_601562 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601562 = validateParameter(valid_601562, JArray, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "VpcSecurityGroupIds", valid_601562
  var valid_601563 = formData.getOrDefault("RestoreToTime")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "RestoreToTime", valid_601563
  var valid_601564 = formData.getOrDefault("Tags")
  valid_601564 = validateParameter(valid_601564, JArray, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "Tags", valid_601564
  var valid_601565 = formData.getOrDefault("DeletionProtection")
  valid_601565 = validateParameter(valid_601565, JBool, required = false, default = nil)
  if valid_601565 != nil:
    section.add "DeletionProtection", valid_601565
  var valid_601566 = formData.getOrDefault("DBSubnetGroupName")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "DBSubnetGroupName", valid_601566
  var valid_601567 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_601567 = validateParameter(valid_601567, JArray, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "EnableCloudwatchLogsExports", valid_601567
  var valid_601568 = formData.getOrDefault("KmsKeyId")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "KmsKeyId", valid_601568
  var valid_601569 = formData.getOrDefault("DBClusterIdentifier")
  valid_601569 = validateParameter(valid_601569, JString, required = true,
                                 default = nil)
  if valid_601569 != nil:
    section.add "DBClusterIdentifier", valid_601569
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601570: Call_PostRestoreDBClusterToPointInTime_601547;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_601570.validator(path, query, header, formData, body)
  let scheme = call_601570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601570.url(scheme.get, call_601570.host, call_601570.base,
                         call_601570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601570, url, valid)

proc call*(call_601571: Call_PostRestoreDBClusterToPointInTime_601547;
          SourceDBClusterIdentifier: string; DBClusterIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; RestoreToTime: string = "";
          Tags: JsonNode = nil; DeletionProtection: bool = false;
          DBSubnetGroupName: string = "";
          Action: string = "RestoreDBClusterToPointInTime";
          EnableCloudwatchLogsExports: JsonNode = nil; KmsKeyId: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postRestoreDBClusterToPointInTime
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   Version: string (required)
  var query_601572 = newJObject()
  var formData_601573 = newJObject()
  add(formData_601573, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_601573, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_601573, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_601573.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601573, "RestoreToTime", newJString(RestoreToTime))
  if Tags != nil:
    formData_601573.add "Tags", Tags
  add(formData_601573, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_601573, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601572, "Action", newJString(Action))
  if EnableCloudwatchLogsExports != nil:
    formData_601573.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_601573, "KmsKeyId", newJString(KmsKeyId))
  add(formData_601573, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601572, "Version", newJString(Version))
  result = call_601571.call(nil, query_601572, nil, formData_601573, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_601547(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_601548, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_601549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_601521 = ref object of OpenApiRestCall_599352
proc url_GetRestoreDBClusterToPointInTime_601523(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBClusterToPointInTime_601522(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RestoreToTime: JString
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   Port: JInt
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  var valid_601524 = query.getOrDefault("RestoreToTime")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "RestoreToTime", valid_601524
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_601525 = query.getOrDefault("DBClusterIdentifier")
  valid_601525 = validateParameter(valid_601525, JString, required = true,
                                 default = nil)
  if valid_601525 != nil:
    section.add "DBClusterIdentifier", valid_601525
  var valid_601526 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601526 = validateParameter(valid_601526, JArray, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "VpcSecurityGroupIds", valid_601526
  var valid_601527 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_601527 = validateParameter(valid_601527, JArray, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "EnableCloudwatchLogsExports", valid_601527
  var valid_601528 = query.getOrDefault("Tags")
  valid_601528 = validateParameter(valid_601528, JArray, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "Tags", valid_601528
  var valid_601529 = query.getOrDefault("DeletionProtection")
  valid_601529 = validateParameter(valid_601529, JBool, required = false, default = nil)
  if valid_601529 != nil:
    section.add "DeletionProtection", valid_601529
  var valid_601530 = query.getOrDefault("UseLatestRestorableTime")
  valid_601530 = validateParameter(valid_601530, JBool, required = false, default = nil)
  if valid_601530 != nil:
    section.add "UseLatestRestorableTime", valid_601530
  var valid_601531 = query.getOrDefault("Action")
  valid_601531 = validateParameter(valid_601531, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_601531 != nil:
    section.add "Action", valid_601531
  var valid_601532 = query.getOrDefault("DBSubnetGroupName")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "DBSubnetGroupName", valid_601532
  var valid_601533 = query.getOrDefault("KmsKeyId")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "KmsKeyId", valid_601533
  var valid_601534 = query.getOrDefault("Port")
  valid_601534 = validateParameter(valid_601534, JInt, required = false, default = nil)
  if valid_601534 != nil:
    section.add "Port", valid_601534
  var valid_601535 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_601535 = validateParameter(valid_601535, JString, required = true,
                                 default = nil)
  if valid_601535 != nil:
    section.add "SourceDBClusterIdentifier", valid_601535
  var valid_601536 = query.getOrDefault("Version")
  valid_601536 = validateParameter(valid_601536, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601536 != nil:
    section.add "Version", valid_601536
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601537 = header.getOrDefault("X-Amz-Date")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Date", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Security-Token")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Security-Token", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Content-Sha256", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Algorithm")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Algorithm", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-Signature")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Signature", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-SignedHeaders", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Credential")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Credential", valid_601543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601544: Call_GetRestoreDBClusterToPointInTime_601521;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_601544.validator(path, query, header, formData, body)
  let scheme = call_601544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601544.url(scheme.get, call_601544.host, call_601544.base,
                         call_601544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601544, url, valid)

proc call*(call_601545: Call_GetRestoreDBClusterToPointInTime_601521;
          DBClusterIdentifier: string; SourceDBClusterIdentifier: string;
          RestoreToTime: string = ""; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false; UseLatestRestorableTime: bool = false;
          Action: string = "RestoreDBClusterToPointInTime";
          DBSubnetGroupName: string = ""; KmsKeyId: string = ""; Port: int = 0;
          Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterToPointInTime
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ##   RestoreToTime: string
  ##                : <p>The date and time to restore the DB cluster to.</p> <p>Valid values: A time in Universal Coordinated Time (UTC) format.</p> <p>Constraints:</p> <ul> <li> <p>Must be before the latest restorable time for the DB instance.</p> </li> <li> <p>Must be specified if the <code>UseLatestRestorableTime</code> parameter is not provided.</p> </li> <li> <p>Cannot be specified if the <code>UseLatestRestorableTime</code> parameter is <code>true</code>.</p> </li> <li> <p>Cannot be specified if the <code>RestoreType</code> parameter is <code>copy-on-write</code>.</p> </li> </ul> <p>Example: <code>2015-03-07T23:45:00Z</code> </p>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The name of the new DB cluster to be created.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of VPC security groups that the new DB cluster belongs to.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that must be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the restored DB cluster.
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the DB cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : <p>The DB subnet group name to use for the new DB cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a DB cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new DB cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new DB cluster and encrypt the new DB cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the DB cluster is encrypted, then the restored DB cluster is encrypted using the AWS KMS key that was used to encrypt the source DB cluster.</p> </li> <li> <p>If the DB cluster is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a DB cluster that is not encrypted, then the restore request is rejected.</p>
  ##   Port: int
  ##       : <p>The port number on which the new DB cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source DB cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_601546 = newJObject()
  add(query_601546, "RestoreToTime", newJString(RestoreToTime))
  add(query_601546, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_601546.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_601546.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_601546.add "Tags", Tags
  add(query_601546, "DeletionProtection", newJBool(DeletionProtection))
  add(query_601546, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_601546, "Action", newJString(Action))
  add(query_601546, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601546, "KmsKeyId", newJString(KmsKeyId))
  add(query_601546, "Port", newJInt(Port))
  add(query_601546, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_601546, "Version", newJString(Version))
  result = call_601545.call(nil, query_601546, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_601521(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_601522, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_601523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_601590 = ref object of OpenApiRestCall_599352
proc url_PostStartDBCluster_601592(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostStartDBCluster_601591(path: JsonNode; query: JsonNode;
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
  var valid_601593 = query.getOrDefault("Action")
  valid_601593 = validateParameter(valid_601593, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_601593 != nil:
    section.add "Action", valid_601593
  var valid_601594 = query.getOrDefault("Version")
  valid_601594 = validateParameter(valid_601594, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601594 != nil:
    section.add "Version", valid_601594
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601595 = header.getOrDefault("X-Amz-Date")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Date", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Security-Token")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Security-Token", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Content-Sha256", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Algorithm")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Algorithm", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-Signature")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Signature", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-SignedHeaders", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Credential")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Credential", valid_601601
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_601602 = formData.getOrDefault("DBClusterIdentifier")
  valid_601602 = validateParameter(valid_601602, JString, required = true,
                                 default = nil)
  if valid_601602 != nil:
    section.add "DBClusterIdentifier", valid_601602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601603: Call_PostStartDBCluster_601590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_601603.validator(path, query, header, formData, body)
  let scheme = call_601603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601603.url(scheme.get, call_601603.host, call_601603.base,
                         call_601603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601603, url, valid)

proc call*(call_601604: Call_PostStartDBCluster_601590;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_601605 = newJObject()
  var formData_601606 = newJObject()
  add(query_601605, "Action", newJString(Action))
  add(formData_601606, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601605, "Version", newJString(Version))
  result = call_601604.call(nil, query_601605, nil, formData_601606, nil)

var postStartDBCluster* = Call_PostStartDBCluster_601590(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_601591, base: "/",
    url: url_PostStartDBCluster_601592, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_601574 = ref object of OpenApiRestCall_599352
proc url_GetStartDBCluster_601576(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStartDBCluster_601575(path: JsonNode; query: JsonNode;
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
  var valid_601577 = query.getOrDefault("DBClusterIdentifier")
  valid_601577 = validateParameter(valid_601577, JString, required = true,
                                 default = nil)
  if valid_601577 != nil:
    section.add "DBClusterIdentifier", valid_601577
  var valid_601578 = query.getOrDefault("Action")
  valid_601578 = validateParameter(valid_601578, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_601578 != nil:
    section.add "Action", valid_601578
  var valid_601579 = query.getOrDefault("Version")
  valid_601579 = validateParameter(valid_601579, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601579 != nil:
    section.add "Version", valid_601579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601580 = header.getOrDefault("X-Amz-Date")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Date", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Security-Token")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Security-Token", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Content-Sha256", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Algorithm")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Algorithm", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Signature")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Signature", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-SignedHeaders", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Credential")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Credential", valid_601586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601587: Call_GetStartDBCluster_601574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_601587.validator(path, query, header, formData, body)
  let scheme = call_601587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601587.url(scheme.get, call_601587.host, call_601587.base,
                         call_601587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601587, url, valid)

proc call*(call_601588: Call_GetStartDBCluster_601574; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601589 = newJObject()
  add(query_601589, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601589, "Action", newJString(Action))
  add(query_601589, "Version", newJString(Version))
  result = call_601588.call(nil, query_601589, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_601574(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_601575,
    base: "/", url: url_GetStartDBCluster_601576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_601623 = ref object of OpenApiRestCall_599352
proc url_PostStopDBCluster_601625(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostStopDBCluster_601624(path: JsonNode; query: JsonNode;
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
  var valid_601626 = query.getOrDefault("Action")
  valid_601626 = validateParameter(valid_601626, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_601626 != nil:
    section.add "Action", valid_601626
  var valid_601627 = query.getOrDefault("Version")
  valid_601627 = validateParameter(valid_601627, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601627 != nil:
    section.add "Version", valid_601627
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601628 = header.getOrDefault("X-Amz-Date")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Date", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Security-Token")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Security-Token", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Content-Sha256", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Algorithm")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Algorithm", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Signature")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Signature", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-SignedHeaders", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Credential")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Credential", valid_601634
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_601635 = formData.getOrDefault("DBClusterIdentifier")
  valid_601635 = validateParameter(valid_601635, JString, required = true,
                                 default = nil)
  if valid_601635 != nil:
    section.add "DBClusterIdentifier", valid_601635
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601636: Call_PostStopDBCluster_601623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_601636.validator(path, query, header, formData, body)
  let scheme = call_601636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601636.url(scheme.get, call_601636.host, call_601636.base,
                         call_601636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601636, url, valid)

proc call*(call_601637: Call_PostStopDBCluster_601623; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_601638 = newJObject()
  var formData_601639 = newJObject()
  add(query_601638, "Action", newJString(Action))
  add(formData_601639, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601638, "Version", newJString(Version))
  result = call_601637.call(nil, query_601638, nil, formData_601639, nil)

var postStopDBCluster* = Call_PostStopDBCluster_601623(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_601624,
    base: "/", url: url_PostStopDBCluster_601625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_601607 = ref object of OpenApiRestCall_599352
proc url_GetStopDBCluster_601609(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStopDBCluster_601608(path: JsonNode; query: JsonNode;
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
  var valid_601610 = query.getOrDefault("DBClusterIdentifier")
  valid_601610 = validateParameter(valid_601610, JString, required = true,
                                 default = nil)
  if valid_601610 != nil:
    section.add "DBClusterIdentifier", valid_601610
  var valid_601611 = query.getOrDefault("Action")
  valid_601611 = validateParameter(valid_601611, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_601611 != nil:
    section.add "Action", valid_601611
  var valid_601612 = query.getOrDefault("Version")
  valid_601612 = validateParameter(valid_601612, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601612 != nil:
    section.add "Version", valid_601612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601613 = header.getOrDefault("X-Amz-Date")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Date", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Security-Token")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Security-Token", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Content-Sha256", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-Algorithm")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Algorithm", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-Signature")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Signature", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-SignedHeaders", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Credential")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Credential", valid_601619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601620: Call_GetStopDBCluster_601607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_601620.validator(path, query, header, formData, body)
  let scheme = call_601620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601620.url(scheme.get, call_601620.host, call_601620.base,
                         call_601620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601620, url, valid)

proc call*(call_601621: Call_GetStopDBCluster_601607; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601622 = newJObject()
  add(query_601622, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_601622, "Action", newJString(Action))
  add(query_601622, "Version", newJString(Version))
  result = call_601621.call(nil, query_601622, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_601607(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_601608,
    base: "/", url: url_GetStopDBCluster_601609,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)


import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625418 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625418](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625418): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostAddTagsToResource_21626018 = ref object of OpenApiRestCall_21625418
proc url_PostAddTagsToResource_21626020(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTagsToResource_21626019(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626021 = query.getOrDefault("Action")
  valid_21626021 = validateParameter(valid_21626021, JString, required = true,
                                   default = newJString("AddTagsToResource"))
  if valid_21626021 != nil:
    section.add "Action", valid_21626021
  var valid_21626022 = query.getOrDefault("Version")
  valid_21626022 = validateParameter(valid_21626022, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626022 != nil:
    section.add "Version", valid_21626022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626023 = header.getOrDefault("X-Amz-Date")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Date", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Security-Token", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Algorithm", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Signature")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Signature", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-Credential")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Credential", valid_21626029
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_21626030 = formData.getOrDefault("Tags")
  valid_21626030 = validateParameter(valid_21626030, JArray, required = true,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "Tags", valid_21626030
  var valid_21626031 = formData.getOrDefault("ResourceName")
  valid_21626031 = validateParameter(valid_21626031, JString, required = true,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "ResourceName", valid_21626031
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626032: Call_PostAddTagsToResource_21626018;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_PostAddTagsToResource_21626018; Tags: JsonNode;
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
  var query_21626034 = newJObject()
  var formData_21626035 = newJObject()
  if Tags != nil:
    formData_21626035.add "Tags", Tags
  add(query_21626034, "Action", newJString(Action))
  add(formData_21626035, "ResourceName", newJString(ResourceName))
  add(query_21626034, "Version", newJString(Version))
  result = call_21626033.call(nil, query_21626034, nil, formData_21626035, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_21626018(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_21626019, base: "/",
    makeUrl: url_PostAddTagsToResource_21626020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_21625762 = ref object of OpenApiRestCall_21625418
proc url_GetAddTagsToResource_21625764(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTagsToResource_21625763(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625865 = query.getOrDefault("Tags")
  valid_21625865 = validateParameter(valid_21625865, JArray, required = true,
                                   default = nil)
  if valid_21625865 != nil:
    section.add "Tags", valid_21625865
  var valid_21625866 = query.getOrDefault("ResourceName")
  valid_21625866 = validateParameter(valid_21625866, JString, required = true,
                                   default = nil)
  if valid_21625866 != nil:
    section.add "ResourceName", valid_21625866
  var valid_21625881 = query.getOrDefault("Action")
  valid_21625881 = validateParameter(valid_21625881, JString, required = true,
                                   default = newJString("AddTagsToResource"))
  if valid_21625881 != nil:
    section.add "Action", valid_21625881
  var valid_21625882 = query.getOrDefault("Version")
  valid_21625882 = validateParameter(valid_21625882, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21625882 != nil:
    section.add "Version", valid_21625882
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625883 = header.getOrDefault("X-Amz-Date")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Date", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Security-Token", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Algorithm", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Signature")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Signature", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-Credential")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Credential", valid_21625889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625914: Call_GetAddTagsToResource_21625762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_21625914.validator(path, query, header, formData, body, _)
  let scheme = call_21625914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625914.makeUrl(scheme.get, call_21625914.host, call_21625914.base,
                               call_21625914.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625914, uri, valid, _)

proc call*(call_21625977: Call_GetAddTagsToResource_21625762; Tags: JsonNode;
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
  var query_21625979 = newJObject()
  if Tags != nil:
    query_21625979.add "Tags", Tags
  add(query_21625979, "ResourceName", newJString(ResourceName))
  add(query_21625979, "Action", newJString(Action))
  add(query_21625979, "Version", newJString(Version))
  result = call_21625977.call(nil, query_21625979, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_21625762(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_21625763, base: "/",
    makeUrl: url_GetAddTagsToResource_21625764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_21626054 = ref object of OpenApiRestCall_21625418
proc url_PostApplyPendingMaintenanceAction_21626056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplyPendingMaintenanceAction_21626055(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626057 = query.getOrDefault("Action")
  valid_21626057 = validateParameter(valid_21626057, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_21626057 != nil:
    section.add "Action", valid_21626057
  var valid_21626058 = query.getOrDefault("Version")
  valid_21626058 = validateParameter(valid_21626058, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626058 != nil:
    section.add "Version", valid_21626058
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626059 = header.getOrDefault("X-Amz-Date")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Date", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Security-Token", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Algorithm", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Signature")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Signature", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Credential")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Credential", valid_21626065
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
  var valid_21626066 = formData.getOrDefault("ApplyAction")
  valid_21626066 = validateParameter(valid_21626066, JString, required = true,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "ApplyAction", valid_21626066
  var valid_21626067 = formData.getOrDefault("ResourceIdentifier")
  valid_21626067 = validateParameter(valid_21626067, JString, required = true,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "ResourceIdentifier", valid_21626067
  var valid_21626068 = formData.getOrDefault("OptInType")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "OptInType", valid_21626068
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626069: Call_PostApplyPendingMaintenanceAction_21626054;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_21626069.validator(path, query, header, formData, body, _)
  let scheme = call_21626069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626069.makeUrl(scheme.get, call_21626069.host, call_21626069.base,
                               call_21626069.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626069, uri, valid, _)

proc call*(call_21626070: Call_PostApplyPendingMaintenanceAction_21626054;
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
  var query_21626071 = newJObject()
  var formData_21626072 = newJObject()
  add(query_21626071, "Action", newJString(Action))
  add(formData_21626072, "ApplyAction", newJString(ApplyAction))
  add(formData_21626072, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_21626072, "OptInType", newJString(OptInType))
  add(query_21626071, "Version", newJString(Version))
  result = call_21626070.call(nil, query_21626071, nil, formData_21626072, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_21626054(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_21626055, base: "/",
    makeUrl: url_PostApplyPendingMaintenanceAction_21626056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_21626036 = ref object of OpenApiRestCall_21625418
proc url_GetApplyPendingMaintenanceAction_21626038(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplyPendingMaintenanceAction_21626037(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626039 = query.getOrDefault("ApplyAction")
  valid_21626039 = validateParameter(valid_21626039, JString, required = true,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "ApplyAction", valid_21626039
  var valid_21626040 = query.getOrDefault("ResourceIdentifier")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "ResourceIdentifier", valid_21626040
  var valid_21626041 = query.getOrDefault("Action")
  valid_21626041 = validateParameter(valid_21626041, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_21626041 != nil:
    section.add "Action", valid_21626041
  var valid_21626042 = query.getOrDefault("OptInType")
  valid_21626042 = validateParameter(valid_21626042, JString, required = true,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "OptInType", valid_21626042
  var valid_21626043 = query.getOrDefault("Version")
  valid_21626043 = validateParameter(valid_21626043, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626043 != nil:
    section.add "Version", valid_21626043
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626044 = header.getOrDefault("X-Amz-Date")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Date", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Security-Token", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Algorithm", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Signature")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Signature", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Credential")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Credential", valid_21626050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626051: Call_GetApplyPendingMaintenanceAction_21626036;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_21626051.validator(path, query, header, formData, body, _)
  let scheme = call_21626051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626051.makeUrl(scheme.get, call_21626051.host, call_21626051.base,
                               call_21626051.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626051, uri, valid, _)

proc call*(call_21626052: Call_GetApplyPendingMaintenanceAction_21626036;
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
  var query_21626053 = newJObject()
  add(query_21626053, "ApplyAction", newJString(ApplyAction))
  add(query_21626053, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_21626053, "Action", newJString(Action))
  add(query_21626053, "OptInType", newJString(OptInType))
  add(query_21626053, "Version", newJString(Version))
  result = call_21626052.call(nil, query_21626053, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_21626036(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_21626037, base: "/",
    makeUrl: url_GetApplyPendingMaintenanceAction_21626038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_21626092 = ref object of OpenApiRestCall_21625418
proc url_PostCopyDBClusterParameterGroup_21626094(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBClusterParameterGroup_21626093(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626095 = query.getOrDefault("Action")
  valid_21626095 = validateParameter(valid_21626095, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_21626095 != nil:
    section.add "Action", valid_21626095
  var valid_21626096 = query.getOrDefault("Version")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626096 != nil:
    section.add "Version", valid_21626096
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626097 = header.getOrDefault("X-Amz-Date")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Date", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Security-Token", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Algorithm", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Signature")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Signature", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Credential")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Credential", valid_21626103
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
  var valid_21626104 = formData.getOrDefault(
      "TargetDBClusterParameterGroupDescription")
  valid_21626104 = validateParameter(valid_21626104, JString, required = true,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_21626104
  var valid_21626105 = formData.getOrDefault("Tags")
  valid_21626105 = validateParameter(valid_21626105, JArray, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "Tags", valid_21626105
  var valid_21626106 = formData.getOrDefault(
      "SourceDBClusterParameterGroupIdentifier")
  valid_21626106 = validateParameter(valid_21626106, JString, required = true,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_21626106
  var valid_21626107 = formData.getOrDefault(
      "TargetDBClusterParameterGroupIdentifier")
  valid_21626107 = validateParameter(valid_21626107, JString, required = true,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_21626107
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626108: Call_PostCopyDBClusterParameterGroup_21626092;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Copies the specified cluster parameter group.
  ## 
  let valid = call_21626108.validator(path, query, header, formData, body, _)
  let scheme = call_21626108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626108.makeUrl(scheme.get, call_21626108.host, call_21626108.base,
                               call_21626108.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626108, uri, valid, _)

proc call*(call_21626109: Call_PostCopyDBClusterParameterGroup_21626092;
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
  var query_21626110 = newJObject()
  var formData_21626111 = newJObject()
  add(formData_21626111, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    formData_21626111.add "Tags", Tags
  add(query_21626110, "Action", newJString(Action))
  add(formData_21626111, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(formData_21626111, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_21626110, "Version", newJString(Version))
  result = call_21626109.call(nil, query_21626110, nil, formData_21626111, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_21626092(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_21626093, base: "/",
    makeUrl: url_PostCopyDBClusterParameterGroup_21626094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_21626073 = ref object of OpenApiRestCall_21625418
proc url_GetCopyDBClusterParameterGroup_21626075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBClusterParameterGroup_21626074(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626076 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_21626076 = validateParameter(valid_21626076, JString, required = true,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_21626076
  var valid_21626077 = query.getOrDefault("Tags")
  valid_21626077 = validateParameter(valid_21626077, JArray, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "Tags", valid_21626077
  var valid_21626078 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_21626078 = validateParameter(valid_21626078, JString, required = true,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_21626078
  var valid_21626079 = query.getOrDefault("Action")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_21626079 != nil:
    section.add "Action", valid_21626079
  var valid_21626080 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_21626080 = validateParameter(valid_21626080, JString, required = true,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_21626080
  var valid_21626081 = query.getOrDefault("Version")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626081 != nil:
    section.add "Version", valid_21626081
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626082 = header.getOrDefault("X-Amz-Date")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Date", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Security-Token", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Algorithm", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Signature")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Signature", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Credential")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Credential", valid_21626088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626089: Call_GetCopyDBClusterParameterGroup_21626073;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Copies the specified cluster parameter group.
  ## 
  let valid = call_21626089.validator(path, query, header, formData, body, _)
  let scheme = call_21626089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626089.makeUrl(scheme.get, call_21626089.host, call_21626089.base,
                               call_21626089.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626089, uri, valid, _)

proc call*(call_21626090: Call_GetCopyDBClusterParameterGroup_21626073;
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
  var query_21626091 = newJObject()
  add(query_21626091, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  if Tags != nil:
    query_21626091.add "Tags", Tags
  add(query_21626091, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  add(query_21626091, "Action", newJString(Action))
  add(query_21626091, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_21626091, "Version", newJString(Version))
  result = call_21626090.call(nil, query_21626091, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_21626073(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_21626074, base: "/",
    makeUrl: url_GetCopyDBClusterParameterGroup_21626075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_21626134 = ref object of OpenApiRestCall_21625418
proc url_PostCopyDBClusterSnapshot_21626136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBClusterSnapshot_21626135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626137 = query.getOrDefault("Action")
  valid_21626137 = validateParameter(valid_21626137, JString, required = true, default = newJString(
      "CopyDBClusterSnapshot"))
  if valid_21626137 != nil:
    section.add "Action", valid_21626137
  var valid_21626138 = query.getOrDefault("Version")
  valid_21626138 = validateParameter(valid_21626138, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626138 != nil:
    section.add "Version", valid_21626138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626139 = header.getOrDefault("X-Amz-Date")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Date", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Security-Token", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Algorithm", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Signature")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Signature", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Credential")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Credential", valid_21626145
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
  var valid_21626146 = formData.getOrDefault("PreSignedUrl")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "PreSignedUrl", valid_21626146
  var valid_21626147 = formData.getOrDefault("Tags")
  valid_21626147 = validateParameter(valid_21626147, JArray, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "Tags", valid_21626147
  var valid_21626148 = formData.getOrDefault("CopyTags")
  valid_21626148 = validateParameter(valid_21626148, JBool, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "CopyTags", valid_21626148
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_21626149 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_21626149 = validateParameter(valid_21626149, JString, required = true,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_21626149
  var valid_21626150 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_21626150 = validateParameter(valid_21626150, JString, required = true,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_21626150
  var valid_21626151 = formData.getOrDefault("KmsKeyId")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "KmsKeyId", valid_21626151
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626152: Call_PostCopyDBClusterSnapshot_21626134;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_21626152.validator(path, query, header, formData, body, _)
  let scheme = call_21626152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626152.makeUrl(scheme.get, call_21626152.host, call_21626152.base,
                               call_21626152.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626152, uri, valid, _)

proc call*(call_21626153: Call_PostCopyDBClusterSnapshot_21626134;
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
  var query_21626154 = newJObject()
  var formData_21626155 = newJObject()
  add(formData_21626155, "PreSignedUrl", newJString(PreSignedUrl))
  if Tags != nil:
    formData_21626155.add "Tags", Tags
  add(formData_21626155, "CopyTags", newJBool(CopyTags))
  add(formData_21626155, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_21626155, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_21626154, "Action", newJString(Action))
  add(formData_21626155, "KmsKeyId", newJString(KmsKeyId))
  add(query_21626154, "Version", newJString(Version))
  result = call_21626153.call(nil, query_21626154, nil, formData_21626155, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_21626134(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_21626135, base: "/",
    makeUrl: url_PostCopyDBClusterSnapshot_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_21626112 = ref object of OpenApiRestCall_21625418
proc url_GetCopyDBClusterSnapshot_21626114(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBClusterSnapshot_21626113(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   SourceDBClusterSnapshotIdentifier: JString (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Version: JString (required)
  ##   CopyTags: JBool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  section = newJObject()
  var valid_21626115 = query.getOrDefault("PreSignedUrl")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "PreSignedUrl", valid_21626115
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_21626116 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_21626116
  var valid_21626117 = query.getOrDefault("Tags")
  valid_21626117 = validateParameter(valid_21626117, JArray, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "Tags", valid_21626117
  var valid_21626118 = query.getOrDefault("Action")
  valid_21626118 = validateParameter(valid_21626118, JString, required = true, default = newJString(
      "CopyDBClusterSnapshot"))
  if valid_21626118 != nil:
    section.add "Action", valid_21626118
  var valid_21626119 = query.getOrDefault("KmsKeyId")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "KmsKeyId", valid_21626119
  var valid_21626120 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_21626120 = validateParameter(valid_21626120, JString, required = true,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_21626120
  var valid_21626121 = query.getOrDefault("Version")
  valid_21626121 = validateParameter(valid_21626121, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626121 != nil:
    section.add "Version", valid_21626121
  var valid_21626122 = query.getOrDefault("CopyTags")
  valid_21626122 = validateParameter(valid_21626122, JBool, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "CopyTags", valid_21626122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626123 = header.getOrDefault("X-Amz-Date")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Date", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Security-Token", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626130: Call_GetCopyDBClusterSnapshot_21626112;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Copies a snapshot of a cluster.</p> <p>To copy a cluster snapshot from a shared manual cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_21626130.validator(path, query, header, formData, body, _)
  let scheme = call_21626130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626130.makeUrl(scheme.get, call_21626130.host, call_21626130.base,
                               call_21626130.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626130, uri, valid, _)

proc call*(call_21626131: Call_GetCopyDBClusterSnapshot_21626112;
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
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key ID for an encrypted cluster snapshot. The AWS KMS key ID is the Amazon Resource Name (ARN), AWS KMS key identifier, or the AWS KMS key alias for the AWS KMS encryption key. </p> <p>If you copy an encrypted cluster snapshot from your AWS account, you can specify a value for <code>KmsKeyId</code> to encrypt the copy with a new AWS KMS encryption key. If you don't specify a value for <code>KmsKeyId</code>, then the copy of the cluster snapshot is encrypted with the same AWS KMS key as the source cluster snapshot. </p> <p>If you copy an encrypted cluster snapshot that is shared from another AWS account, then you must specify a value for <code>KmsKeyId</code>. </p> <p>To copy an encrypted cluster snapshot to another AWS Region, set <code>KmsKeyId</code> to the AWS KMS key ID that you want to use to encrypt the copy of the cluster snapshot in the destination Region. AWS KMS encryption keys are specific to the AWS Region that they are created in, and you can't use encryption keys from one Region in another Region.</p> <p>If you copy an unencrypted cluster snapshot and specify a value for the <code>KmsKeyId</code> parameter, an error is returned.</p>
  ##   SourceDBClusterSnapshotIdentifier: string (required)
  ##                                    : <p>The identifier of the cluster snapshot to copy. This parameter is not case sensitive.</p> <p>You can't copy an encrypted, shared cluster snapshot from one AWS Region to another.</p> <p>Constraints:</p> <ul> <li> <p>Must specify a valid system snapshot in the "available" state.</p> </li> <li> <p>If the source snapshot is in the same AWS Region as the copy, specify a valid snapshot identifier.</p> </li> <li> <p>If the source snapshot is in a different AWS Region than the copy, specify a valid cluster snapshot ARN.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Version: string (required)
  ##   CopyTags: bool
  ##           : Set to <code>true</code> to copy all tags from the source cluster snapshot to the target cluster snapshot, and otherwise <code>false</code>. The default is <code>false</code>.
  var query_21626132 = newJObject()
  add(query_21626132, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_21626132, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  if Tags != nil:
    query_21626132.add "Tags", Tags
  add(query_21626132, "Action", newJString(Action))
  add(query_21626132, "KmsKeyId", newJString(KmsKeyId))
  add(query_21626132, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_21626132, "Version", newJString(Version))
  add(query_21626132, "CopyTags", newJBool(CopyTags))
  result = call_21626131.call(nil, query_21626132, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_21626112(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_21626113, base: "/",
    makeUrl: url_GetCopyDBClusterSnapshot_21626114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_21626189 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBCluster_21626191(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBCluster_21626190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626192 = query.getOrDefault("Action")
  valid_21626192 = validateParameter(valid_21626192, JString, required = true,
                                   default = newJString("CreateDBCluster"))
  if valid_21626192 != nil:
    section.add "Action", valid_21626192
  var valid_21626193 = query.getOrDefault("Version")
  valid_21626193 = validateParameter(valid_21626193, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626193 != nil:
    section.add "Version", valid_21626193
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626194 = header.getOrDefault("X-Amz-Date")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Date", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Security-Token", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Algorithm", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Signature")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Signature", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Credential")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Credential", valid_21626200
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##       : The port number on which the instances in the cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
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
  var valid_21626201 = formData.getOrDefault("Port")
  valid_21626201 = validateParameter(valid_21626201, JInt, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "Port", valid_21626201
  var valid_21626202 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21626202 = validateParameter(valid_21626202, JArray, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "VpcSecurityGroupIds", valid_21626202
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_21626203 = formData.getOrDefault("Engine")
  valid_21626203 = validateParameter(valid_21626203, JString, required = true,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "Engine", valid_21626203
  var valid_21626204 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21626204 = validateParameter(valid_21626204, JInt, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "BackupRetentionPeriod", valid_21626204
  var valid_21626205 = formData.getOrDefault("Tags")
  valid_21626205 = validateParameter(valid_21626205, JArray, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "Tags", valid_21626205
  var valid_21626206 = formData.getOrDefault("MasterUserPassword")
  valid_21626206 = validateParameter(valid_21626206, JString, required = true,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "MasterUserPassword", valid_21626206
  var valid_21626207 = formData.getOrDefault("DeletionProtection")
  valid_21626207 = validateParameter(valid_21626207, JBool, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "DeletionProtection", valid_21626207
  var valid_21626208 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "DBSubnetGroupName", valid_21626208
  var valid_21626209 = formData.getOrDefault("AvailabilityZones")
  valid_21626209 = validateParameter(valid_21626209, JArray, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "AvailabilityZones", valid_21626209
  var valid_21626210 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "DBClusterParameterGroupName", valid_21626210
  var valid_21626211 = formData.getOrDefault("MasterUsername")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "MasterUsername", valid_21626211
  var valid_21626212 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_21626212 = validateParameter(valid_21626212, JArray, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "EnableCloudwatchLogsExports", valid_21626212
  var valid_21626213 = formData.getOrDefault("PreferredBackupWindow")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "PreferredBackupWindow", valid_21626213
  var valid_21626214 = formData.getOrDefault("KmsKeyId")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "KmsKeyId", valid_21626214
  var valid_21626215 = formData.getOrDefault("StorageEncrypted")
  valid_21626215 = validateParameter(valid_21626215, JBool, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "StorageEncrypted", valid_21626215
  var valid_21626216 = formData.getOrDefault("DBClusterIdentifier")
  valid_21626216 = validateParameter(valid_21626216, JString, required = true,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "DBClusterIdentifier", valid_21626216
  var valid_21626217 = formData.getOrDefault("EngineVersion")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "EngineVersion", valid_21626217
  var valid_21626218 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626218
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626219: Call_PostCreateDBCluster_21626189; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  let valid = call_21626219.validator(path, query, header, formData, body, _)
  let scheme = call_21626219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626219.makeUrl(scheme.get, call_21626219.host, call_21626219.base,
                               call_21626219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626219, uri, valid, _)

proc call*(call_21626220: Call_PostCreateDBCluster_21626189; Engine: string;
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
  ## Creates a new Amazon DocumentDB cluster.
  ##   Port: int
  ##       : The port number on which the instances in the cluster accept connections.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: string
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
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
  var query_21626221 = newJObject()
  var formData_21626222 = newJObject()
  add(formData_21626222, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_21626222.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_21626222, "Engine", newJString(Engine))
  add(formData_21626222, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if Tags != nil:
    formData_21626222.add "Tags", Tags
  add(formData_21626222, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_21626222, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_21626222, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626221, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_21626222.add "AvailabilityZones", AvailabilityZones
  add(formData_21626222, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_21626222, "MasterUsername", newJString(MasterUsername))
  if EnableCloudwatchLogsExports != nil:
    formData_21626222.add "EnableCloudwatchLogsExports",
                         EnableCloudwatchLogsExports
  add(formData_21626222, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_21626222, "KmsKeyId", newJString(KmsKeyId))
  add(formData_21626222, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_21626222, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_21626222, "EngineVersion", newJString(EngineVersion))
  add(query_21626221, "Version", newJString(Version))
  add(formData_21626222, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_21626220.call(nil, query_21626221, nil, formData_21626222, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_21626189(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_21626190, base: "/",
    makeUrl: url_PostCreateDBCluster_21626191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_21626156 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBCluster_21626158(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBCluster_21626157(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   StorageEncrypted: JBool
  ##                   : Specifies whether the cluster is encrypted.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   MasterUserPassword: JString (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to use.
  ##   Port: JInt
  ##       : The port number on which the instances in the cluster accept connections.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: JString (required)
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_21626159 = query.getOrDefault("Engine")
  valid_21626159 = validateParameter(valid_21626159, JString, required = true,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "Engine", valid_21626159
  var valid_21626160 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626160
  var valid_21626161 = query.getOrDefault("DBClusterParameterGroupName")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "DBClusterParameterGroupName", valid_21626161
  var valid_21626162 = query.getOrDefault("StorageEncrypted")
  valid_21626162 = validateParameter(valid_21626162, JBool, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "StorageEncrypted", valid_21626162
  var valid_21626163 = query.getOrDefault("AvailabilityZones")
  valid_21626163 = validateParameter(valid_21626163, JArray, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "AvailabilityZones", valid_21626163
  var valid_21626164 = query.getOrDefault("DBClusterIdentifier")
  valid_21626164 = validateParameter(valid_21626164, JString, required = true,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "DBClusterIdentifier", valid_21626164
  var valid_21626165 = query.getOrDefault("MasterUserPassword")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "MasterUserPassword", valid_21626165
  var valid_21626166 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21626166 = validateParameter(valid_21626166, JArray, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "VpcSecurityGroupIds", valid_21626166
  var valid_21626167 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_21626167 = validateParameter(valid_21626167, JArray, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "EnableCloudwatchLogsExports", valid_21626167
  var valid_21626168 = query.getOrDefault("Tags")
  valid_21626168 = validateParameter(valid_21626168, JArray, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "Tags", valid_21626168
  var valid_21626169 = query.getOrDefault("BackupRetentionPeriod")
  valid_21626169 = validateParameter(valid_21626169, JInt, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "BackupRetentionPeriod", valid_21626169
  var valid_21626170 = query.getOrDefault("DeletionProtection")
  valid_21626170 = validateParameter(valid_21626170, JBool, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "DeletionProtection", valid_21626170
  var valid_21626171 = query.getOrDefault("Action")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true,
                                   default = newJString("CreateDBCluster"))
  if valid_21626171 != nil:
    section.add "Action", valid_21626171
  var valid_21626172 = query.getOrDefault("DBSubnetGroupName")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "DBSubnetGroupName", valid_21626172
  var valid_21626173 = query.getOrDefault("KmsKeyId")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "KmsKeyId", valid_21626173
  var valid_21626174 = query.getOrDefault("EngineVersion")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "EngineVersion", valid_21626174
  var valid_21626175 = query.getOrDefault("Port")
  valid_21626175 = validateParameter(valid_21626175, JInt, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "Port", valid_21626175
  var valid_21626176 = query.getOrDefault("PreferredBackupWindow")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "PreferredBackupWindow", valid_21626176
  var valid_21626177 = query.getOrDefault("Version")
  valid_21626177 = validateParameter(valid_21626177, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626177 != nil:
    section.add "Version", valid_21626177
  var valid_21626178 = query.getOrDefault("MasterUsername")
  valid_21626178 = validateParameter(valid_21626178, JString, required = true,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "MasterUsername", valid_21626178
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626179 = header.getOrDefault("X-Amz-Date")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Date", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Security-Token", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Algorithm", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Signature")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Signature", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Credential")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Credential", valid_21626185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626186: Call_GetCreateDBCluster_21626156; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Amazon DocumentDB cluster.
  ## 
  let valid = call_21626186.validator(path, query, header, formData, body, _)
  let scheme = call_21626186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626186.makeUrl(scheme.get, call_21626186.host, call_21626186.base,
                               call_21626186.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626186, uri, valid, _)

proc call*(call_21626187: Call_GetCreateDBCluster_21626156; Engine: string;
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
  ## Creates a new Amazon DocumentDB cluster.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this cluster.</p> <p>Valid values: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week.</p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: string
  ##                              :  The name of the cluster parameter group to associate with this cluster.
  ##   StorageEncrypted: bool
  ##                   : Specifies whether the cluster is encrypted.
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the cluster can be created in.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   MasterUserPassword: string (required)
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of EC2 VPC security groups to associate with this cluster.
  ##   EnableCloudwatchLogsExports: JArray
  ##                              : A list of log types that need to be enabled for exporting to Amazon CloudWatch Logs.
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : <p>A subnet group to associate with this cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier for an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are creating a cluster using the same AWS account that owns the AWS KMS encryption key that is used to encrypt the new cluster, you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If an encryption key is not specified in <code>KmsKeyId</code>:</p> <ul> <li> <p>If <code>ReplicationSourceIdentifier</code> identifies an encrypted source, then Amazon DocumentDB uses the encryption key that is used to encrypt the source. Otherwise, Amazon DocumentDB uses your default encryption key. </p> </li> <li> <p>If the <code>StorageEncrypted</code> parameter is <code>true</code> and <code>ReplicationSourceIdentifier</code> is not specified, Amazon DocumentDB uses your default encryption key.</p> </li> </ul> <p>AWS KMS creates the default encryption key for your AWS account. Your AWS account has a different default encryption key for each AWS Region.</p> <p>If you create a replica of an encrypted cluster in another AWS Region, you must set <code>KmsKeyId</code> to a KMS key ID that is valid in the destination AWS Region. This key is used to encrypt the replica in that AWS Region.</p>
  ##   EngineVersion: string
  ##                : The version number of the database engine to use.
  ##   Port: int
  ##       : The port number on which the instances in the cluster accept connections.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: string (required)
  ##   MasterUsername: string (required)
  ##                 : <p>The name of the master user for the cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 63 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  var query_21626188 = newJObject()
  add(query_21626188, "Engine", newJString(Engine))
  add(query_21626188, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21626188, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_21626188, "StorageEncrypted", newJBool(StorageEncrypted))
  if AvailabilityZones != nil:
    query_21626188.add "AvailabilityZones", AvailabilityZones
  add(query_21626188, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626188, "MasterUserPassword", newJString(MasterUserPassword))
  if VpcSecurityGroupIds != nil:
    query_21626188.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_21626188.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_21626188.add "Tags", Tags
  add(query_21626188, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21626188, "DeletionProtection", newJBool(DeletionProtection))
  add(query_21626188, "Action", newJString(Action))
  add(query_21626188, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626188, "KmsKeyId", newJString(KmsKeyId))
  add(query_21626188, "EngineVersion", newJString(EngineVersion))
  add(query_21626188, "Port", newJInt(Port))
  add(query_21626188, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21626188, "Version", newJString(Version))
  add(query_21626188, "MasterUsername", newJString(MasterUsername))
  result = call_21626187.call(nil, query_21626188, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_21626156(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_21626157,
    base: "/", makeUrl: url_GetCreateDBCluster_21626158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_21626242 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBClusterParameterGroup_21626244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBClusterParameterGroup_21626243(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626245 = query.getOrDefault("Action")
  valid_21626245 = validateParameter(valid_21626245, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_21626245 != nil:
    section.add "Action", valid_21626245
  var valid_21626246 = query.getOrDefault("Version")
  valid_21626246 = validateParameter(valid_21626246, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626246 != nil:
    section.add "Version", valid_21626246
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626247 = header.getOrDefault("X-Amz-Date")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Date", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Security-Token", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Algorithm", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Signature")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Signature", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Credential")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Credential", valid_21626253
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
  var valid_21626254 = formData.getOrDefault("Tags")
  valid_21626254 = validateParameter(valid_21626254, JArray, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "Tags", valid_21626254
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_21626255 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_21626255 = validateParameter(valid_21626255, JString, required = true,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "DBClusterParameterGroupName", valid_21626255
  var valid_21626256 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21626256 = validateParameter(valid_21626256, JString, required = true,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "DBParameterGroupFamily", valid_21626256
  var valid_21626257 = formData.getOrDefault("Description")
  valid_21626257 = validateParameter(valid_21626257, JString, required = true,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "Description", valid_21626257
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626258: Call_PostCreateDBClusterParameterGroup_21626242;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_21626258.validator(path, query, header, formData, body, _)
  let scheme = call_21626258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626258.makeUrl(scheme.get, call_21626258.host, call_21626258.base,
                               call_21626258.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626258, uri, valid, _)

proc call*(call_21626259: Call_PostCreateDBClusterParameterGroup_21626242;
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
  var query_21626260 = newJObject()
  var formData_21626261 = newJObject()
  if Tags != nil:
    formData_21626261.add "Tags", Tags
  add(query_21626260, "Action", newJString(Action))
  add(formData_21626261, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_21626261, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_21626260, "Version", newJString(Version))
  add(formData_21626261, "Description", newJString(Description))
  result = call_21626259.call(nil, query_21626260, nil, formData_21626261, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_21626242(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_21626243, base: "/",
    makeUrl: url_PostCreateDBClusterParameterGroup_21626244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_21626223 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBClusterParameterGroup_21626225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBClusterParameterGroup_21626224(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626226 = query.getOrDefault("DBClusterParameterGroupName")
  valid_21626226 = validateParameter(valid_21626226, JString, required = true,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "DBClusterParameterGroupName", valid_21626226
  var valid_21626227 = query.getOrDefault("Description")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "Description", valid_21626227
  var valid_21626228 = query.getOrDefault("DBParameterGroupFamily")
  valid_21626228 = validateParameter(valid_21626228, JString, required = true,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "DBParameterGroupFamily", valid_21626228
  var valid_21626229 = query.getOrDefault("Tags")
  valid_21626229 = validateParameter(valid_21626229, JArray, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "Tags", valid_21626229
  var valid_21626230 = query.getOrDefault("Action")
  valid_21626230 = validateParameter(valid_21626230, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_21626230 != nil:
    section.add "Action", valid_21626230
  var valid_21626231 = query.getOrDefault("Version")
  valid_21626231 = validateParameter(valid_21626231, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626231 != nil:
    section.add "Version", valid_21626231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626232 = header.getOrDefault("X-Amz-Date")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Date", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Security-Token", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Algorithm", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Signature")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Signature", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Credential")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Credential", valid_21626238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626239: Call_GetCreateDBClusterParameterGroup_21626223;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new cluster parameter group.</p> <p>Parameters in a cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A cluster parameter group is initially created with the default parameters for the database engine used by instances in the cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the instances in the cluster without failover.</p> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the cluster parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_21626239.validator(path, query, header, formData, body, _)
  let scheme = call_21626239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626239.makeUrl(scheme.get, call_21626239.host, call_21626239.base,
                               call_21626239.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626239, uri, valid, _)

proc call*(call_21626240: Call_GetCreateDBClusterParameterGroup_21626223;
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
  var query_21626241 = newJObject()
  add(query_21626241, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_21626241, "Description", newJString(Description))
  add(query_21626241, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_21626241.add "Tags", Tags
  add(query_21626241, "Action", newJString(Action))
  add(query_21626241, "Version", newJString(Version))
  result = call_21626240.call(nil, query_21626241, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_21626223(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_21626224, base: "/",
    makeUrl: url_GetCreateDBClusterParameterGroup_21626225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_21626280 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBClusterSnapshot_21626282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBClusterSnapshot_21626281(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626283 = query.getOrDefault("Action")
  valid_21626283 = validateParameter(valid_21626283, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_21626283 != nil:
    section.add "Action", valid_21626283
  var valid_21626284 = query.getOrDefault("Version")
  valid_21626284 = validateParameter(valid_21626284, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626284 != nil:
    section.add "Version", valid_21626284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626285 = header.getOrDefault("X-Amz-Date")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Date", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Security-Token", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Algorithm", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Signature")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Signature", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Credential")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Credential", valid_21626291
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
  var valid_21626292 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21626292 = validateParameter(valid_21626292, JString, required = true,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21626292
  var valid_21626293 = formData.getOrDefault("Tags")
  valid_21626293 = validateParameter(valid_21626293, JArray, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "Tags", valid_21626293
  var valid_21626294 = formData.getOrDefault("DBClusterIdentifier")
  valid_21626294 = validateParameter(valid_21626294, JString, required = true,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "DBClusterIdentifier", valid_21626294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626295: Call_PostCreateDBClusterSnapshot_21626280;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a snapshot of a cluster. 
  ## 
  let valid = call_21626295.validator(path, query, header, formData, body, _)
  let scheme = call_21626295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626295.makeUrl(scheme.get, call_21626295.host, call_21626295.base,
                               call_21626295.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626295, uri, valid, _)

proc call*(call_21626296: Call_PostCreateDBClusterSnapshot_21626280;
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
  var query_21626297 = newJObject()
  var formData_21626298 = newJObject()
  add(formData_21626298, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    formData_21626298.add "Tags", Tags
  add(query_21626297, "Action", newJString(Action))
  add(formData_21626298, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626297, "Version", newJString(Version))
  result = call_21626296.call(nil, query_21626297, nil, formData_21626298, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_21626280(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_21626281, base: "/",
    makeUrl: url_PostCreateDBClusterSnapshot_21626282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_21626262 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBClusterSnapshot_21626264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBClusterSnapshot_21626263(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a snapshot of a cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The identifier of the cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_21626265 = query.getOrDefault("DBClusterIdentifier")
  valid_21626265 = validateParameter(valid_21626265, JString, required = true,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "DBClusterIdentifier", valid_21626265
  var valid_21626266 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21626266 = validateParameter(valid_21626266, JString, required = true,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21626266
  var valid_21626267 = query.getOrDefault("Tags")
  valid_21626267 = validateParameter(valid_21626267, JArray, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "Tags", valid_21626267
  var valid_21626268 = query.getOrDefault("Action")
  valid_21626268 = validateParameter(valid_21626268, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_21626268 != nil:
    section.add "Action", valid_21626268
  var valid_21626269 = query.getOrDefault("Version")
  valid_21626269 = validateParameter(valid_21626269, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626269 != nil:
    section.add "Version", valid_21626269
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626270 = header.getOrDefault("X-Amz-Date")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Date", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Security-Token", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Algorithm", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Signature")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Signature", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Credential")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Credential", valid_21626276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626277: Call_GetCreateDBClusterSnapshot_21626262;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a snapshot of a cluster. 
  ## 
  let valid = call_21626277.validator(path, query, header, formData, body, _)
  let scheme = call_21626277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626277.makeUrl(scheme.get, call_21626277.host, call_21626277.base,
                               call_21626277.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626277, uri, valid, _)

proc call*(call_21626278: Call_GetCreateDBClusterSnapshot_21626262;
          DBClusterIdentifier: string; DBClusterSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBClusterSnapshot";
          Version: string = "2014-10-31"): Recallable =
  ## getCreateDBClusterSnapshot
  ## Creates a snapshot of a cluster. 
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The identifier of the cluster to create a snapshot for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul> <p>Example: <code>my-cluster</code> </p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster-snapshot1</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the cluster snapshot.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626279 = newJObject()
  add(query_21626279, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626279, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_21626279.add "Tags", Tags
  add(query_21626279, "Action", newJString(Action))
  add(query_21626279, "Version", newJString(Version))
  result = call_21626278.call(nil, query_21626279, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_21626262(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_21626263, base: "/",
    makeUrl: url_GetCreateDBClusterSnapshot_21626264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_21626323 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBInstance_21626325(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_21626324(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626326 = query.getOrDefault("Action")
  valid_21626326 = validateParameter(valid_21626326, JString, required = true,
                                   default = newJString("CreateDBInstance"))
  if valid_21626326 != nil:
    section.add "Action", valid_21626326
  var valid_21626327 = query.getOrDefault("Version")
  valid_21626327 = validateParameter(valid_21626327, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626327 != nil:
    section.add "Version", valid_21626327
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626328 = header.getOrDefault("X-Amz-Date")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Date", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-Security-Token", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Algorithm", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Signature")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Signature", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Credential")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Credential", valid_21626334
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   PromotionTier: JInt
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_21626335 = formData.getOrDefault("Engine")
  valid_21626335 = validateParameter(valid_21626335, JString, required = true,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "Engine", valid_21626335
  var valid_21626336 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626336 = validateParameter(valid_21626336, JString, required = true,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "DBInstanceIdentifier", valid_21626336
  var valid_21626337 = formData.getOrDefault("Tags")
  valid_21626337 = validateParameter(valid_21626337, JArray, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "Tags", valid_21626337
  var valid_21626338 = formData.getOrDefault("AvailabilityZone")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "AvailabilityZone", valid_21626338
  var valid_21626339 = formData.getOrDefault("PromotionTier")
  valid_21626339 = validateParameter(valid_21626339, JInt, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "PromotionTier", valid_21626339
  var valid_21626340 = formData.getOrDefault("DBInstanceClass")
  valid_21626340 = validateParameter(valid_21626340, JString, required = true,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "DBInstanceClass", valid_21626340
  var valid_21626341 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626341 = validateParameter(valid_21626341, JBool, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626341
  var valid_21626342 = formData.getOrDefault("DBClusterIdentifier")
  valid_21626342 = validateParameter(valid_21626342, JString, required = true,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "DBClusterIdentifier", valid_21626342
  var valid_21626343 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626343
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626344: Call_PostCreateDBInstance_21626323; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new instance.
  ## 
  let valid = call_21626344.validator(path, query, header, formData, body, _)
  let scheme = call_21626344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626344.makeUrl(scheme.get, call_21626344.host, call_21626344.base,
                               call_21626344.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626344, uri, valid, _)

proc call*(call_21626345: Call_PostCreateDBInstance_21626323; Engine: string;
          DBInstanceIdentifier: string; DBInstanceClass: string;
          DBClusterIdentifier: string; Tags: JsonNode = nil;
          AvailabilityZone: string = ""; Action: string = "CreateDBInstance";
          PromotionTier: int = 0; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2014-10-31"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postCreateDBInstance
  ## Creates a new instance.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Action: string (required)
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_21626346 = newJObject()
  var formData_21626347 = newJObject()
  add(formData_21626347, "Engine", newJString(Engine))
  add(formData_21626347, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_21626347.add "Tags", Tags
  add(formData_21626347, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626346, "Action", newJString(Action))
  add(formData_21626347, "PromotionTier", newJInt(PromotionTier))
  add(formData_21626347, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21626347, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_21626347, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626346, "Version", newJString(Version))
  add(formData_21626347, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_21626345.call(nil, query_21626346, nil, formData_21626347, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_21626323(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_21626324, base: "/",
    makeUrl: url_PostCreateDBInstance_21626325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_21626299 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBInstance_21626301(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_21626300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new instance.
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
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   AvailabilityZone: JString
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   DBInstanceClass: JString (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   Action: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_21626302 = query.getOrDefault("Engine")
  valid_21626302 = validateParameter(valid_21626302, JString, required = true,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "Engine", valid_21626302
  var valid_21626303 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626303
  var valid_21626304 = query.getOrDefault("PromotionTier")
  valid_21626304 = validateParameter(valid_21626304, JInt, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "PromotionTier", valid_21626304
  var valid_21626305 = query.getOrDefault("DBClusterIdentifier")
  valid_21626305 = validateParameter(valid_21626305, JString, required = true,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "DBClusterIdentifier", valid_21626305
  var valid_21626306 = query.getOrDefault("AvailabilityZone")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "AvailabilityZone", valid_21626306
  var valid_21626307 = query.getOrDefault("Tags")
  valid_21626307 = validateParameter(valid_21626307, JArray, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "Tags", valid_21626307
  var valid_21626308 = query.getOrDefault("DBInstanceClass")
  valid_21626308 = validateParameter(valid_21626308, JString, required = true,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "DBInstanceClass", valid_21626308
  var valid_21626309 = query.getOrDefault("Action")
  valid_21626309 = validateParameter(valid_21626309, JString, required = true,
                                   default = newJString("CreateDBInstance"))
  if valid_21626309 != nil:
    section.add "Action", valid_21626309
  var valid_21626310 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626310 = validateParameter(valid_21626310, JBool, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626310
  var valid_21626311 = query.getOrDefault("Version")
  valid_21626311 = validateParameter(valid_21626311, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626311 != nil:
    section.add "Version", valid_21626311
  var valid_21626312 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626312 = validateParameter(valid_21626312, JString, required = true,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "DBInstanceIdentifier", valid_21626312
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626313 = header.getOrDefault("X-Amz-Date")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Date", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Security-Token", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Algorithm", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Signature")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Signature", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Credential")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Credential", valid_21626319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626320: Call_GetCreateDBInstance_21626299; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new instance.
  ## 
  let valid = call_21626320.validator(path, query, header, formData, body, _)
  let scheme = call_21626320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626320.makeUrl(scheme.get, call_21626320.host, call_21626320.base,
                               call_21626320.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626320, uri, valid, _)

proc call*(call_21626321: Call_GetCreateDBInstance_21626299; Engine: string;
          DBClusterIdentifier: string; DBInstanceClass: string;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          PromotionTier: int = 0; AvailabilityZone: string = ""; Tags: JsonNode = nil;
          Action: string = "CreateDBInstance";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31"): Recallable =
  ## getCreateDBInstance
  ## Creates a new instance.
  ##   Engine: string (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p> Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   PromotionTier: int
  ##                : <p>A value that specifies the order in which an Amazon DocumentDB replica is promoted to the primary instance after a failure of the existing primary instance.</p> <p>Default: 1</p> <p>Valid values: 0-15</p>
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster that the instance will belong to.
  ##   AvailabilityZone: string
  ##                   : <p> The Amazon EC2 Availability Zone that the instance is created in.</p> <p>Default: A random, system-chosen Availability Zone in the endpoint's AWS Region.</p> <p> Example: <code>us-east-1d</code> </p> <p> Constraint: The <code>AvailabilityZone</code> parameter can't be specified if the <code>MultiAZ</code> parameter is set to <code>true</code>. The specified Availability Zone must be in the same AWS Region as the current endpoint. </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the instance. You can assign up to 10 tags to an instance.
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the instance; for example, <code>db.r5.large</code>. 
  ##   Action: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  var query_21626322 = newJObject()
  add(query_21626322, "Engine", newJString(Engine))
  add(query_21626322, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21626322, "PromotionTier", newJInt(PromotionTier))
  add(query_21626322, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626322, "AvailabilityZone", newJString(AvailabilityZone))
  if Tags != nil:
    query_21626322.add "Tags", Tags
  add(query_21626322, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21626322, "Action", newJString(Action))
  add(query_21626322, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21626322, "Version", newJString(Version))
  add(query_21626322, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626321.call(nil, query_21626322, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_21626299(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_21626300, base: "/",
    makeUrl: url_GetCreateDBInstance_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_21626367 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSubnetGroup_21626369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_21626368(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626370 = query.getOrDefault("Action")
  valid_21626370 = validateParameter(valid_21626370, JString, required = true,
                                   default = newJString("CreateDBSubnetGroup"))
  if valid_21626370 != nil:
    section.add "Action", valid_21626370
  var valid_21626371 = query.getOrDefault("Version")
  valid_21626371 = validateParameter(valid_21626371, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626371 != nil:
    section.add "Version", valid_21626371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626372 = header.getOrDefault("X-Amz-Date")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Date", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Security-Token", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-Algorithm", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Signature")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Signature", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Credential")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Credential", valid_21626378
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupDescription: JString (required)
  ##                           : The description for the subnet group.
  section = newJObject()
  var valid_21626379 = formData.getOrDefault("Tags")
  valid_21626379 = validateParameter(valid_21626379, JArray, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "Tags", valid_21626379
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21626380 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626380 = validateParameter(valid_21626380, JString, required = true,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "DBSubnetGroupName", valid_21626380
  var valid_21626381 = formData.getOrDefault("SubnetIds")
  valid_21626381 = validateParameter(valid_21626381, JArray, required = true,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "SubnetIds", valid_21626381
  var valid_21626382 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_21626382 = validateParameter(valid_21626382, JString, required = true,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "DBSubnetGroupDescription", valid_21626382
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626383: Call_PostCreateDBSubnetGroup_21626367;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_21626383.validator(path, query, header, formData, body, _)
  let scheme = call_21626383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626383.makeUrl(scheme.get, call_21626383.host, call_21626383.base,
                               call_21626383.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626383, uri, valid, _)

proc call*(call_21626384: Call_PostCreateDBSubnetGroup_21626367;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-10-31"): Recallable =
  ## postCreateDBSubnetGroup
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   Tags: JArray
  ##       : The tags to be assigned to the subnet group.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string.</p> <p>Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##                           : The description for the subnet group.
  ##   Version: string (required)
  var query_21626385 = newJObject()
  var formData_21626386 = newJObject()
  if Tags != nil:
    formData_21626386.add "Tags", Tags
  add(formData_21626386, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_21626386.add "SubnetIds", SubnetIds
  add(query_21626385, "Action", newJString(Action))
  add(formData_21626386, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21626385, "Version", newJString(Version))
  result = call_21626384.call(nil, query_21626385, nil, formData_21626386, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_21626367(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_21626368, base: "/",
    makeUrl: url_PostCreateDBSubnetGroup_21626369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_21626348 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSubnetGroup_21626350(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_21626349(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626351 = query.getOrDefault("Tags")
  valid_21626351 = validateParameter(valid_21626351, JArray, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "Tags", valid_21626351
  var valid_21626352 = query.getOrDefault("Action")
  valid_21626352 = validateParameter(valid_21626352, JString, required = true,
                                   default = newJString("CreateDBSubnetGroup"))
  if valid_21626352 != nil:
    section.add "Action", valid_21626352
  var valid_21626353 = query.getOrDefault("DBSubnetGroupName")
  valid_21626353 = validateParameter(valid_21626353, JString, required = true,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "DBSubnetGroupName", valid_21626353
  var valid_21626354 = query.getOrDefault("SubnetIds")
  valid_21626354 = validateParameter(valid_21626354, JArray, required = true,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "SubnetIds", valid_21626354
  var valid_21626355 = query.getOrDefault("DBSubnetGroupDescription")
  valid_21626355 = validateParameter(valid_21626355, JString, required = true,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "DBSubnetGroupDescription", valid_21626355
  var valid_21626356 = query.getOrDefault("Version")
  valid_21626356 = validateParameter(valid_21626356, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626356 != nil:
    section.add "Version", valid_21626356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626357 = header.getOrDefault("X-Amz-Date")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Date", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Security-Token", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Algorithm", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Signature")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Signature", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Credential")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Credential", valid_21626363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626364: Call_GetCreateDBSubnetGroup_21626348;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_21626364.validator(path, query, header, formData, body, _)
  let scheme = call_21626364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626364.makeUrl(scheme.get, call_21626364.host, call_21626364.base,
                               call_21626364.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626364, uri, valid, _)

proc call*(call_21626365: Call_GetCreateDBSubnetGroup_21626348;
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
  var query_21626366 = newJObject()
  if Tags != nil:
    query_21626366.add "Tags", Tags
  add(query_21626366, "Action", newJString(Action))
  add(query_21626366, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_21626366.add "SubnetIds", SubnetIds
  add(query_21626366, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21626366, "Version", newJString(Version))
  result = call_21626365.call(nil, query_21626366, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_21626348(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_21626349, base: "/",
    makeUrl: url_GetCreateDBSubnetGroup_21626350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_21626405 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBCluster_21626407(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBCluster_21626406(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626408 = query.getOrDefault("Action")
  valid_21626408 = validateParameter(valid_21626408, JString, required = true,
                                   default = newJString("DeleteDBCluster"))
  if valid_21626408 != nil:
    section.add "Action", valid_21626408
  var valid_21626409 = query.getOrDefault("Version")
  valid_21626409 = validateParameter(valid_21626409, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626409 != nil:
    section.add "Version", valid_21626409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626410 = header.getOrDefault("X-Amz-Date")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Date", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Security-Token", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Algorithm", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Signature")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Signature", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Credential")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Credential", valid_21626416
  result.add "header", section
  ## parameters in `formData` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The cluster snapshot identifier of the new cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final cluster snapshot is created before the cluster is deleted. If <code>true</code> is specified, no cluster snapshot is created. If <code>false</code> is specified, a cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_21626417 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_21626417
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_21626418 = formData.getOrDefault("DBClusterIdentifier")
  valid_21626418 = validateParameter(valid_21626418, JString, required = true,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "DBClusterIdentifier", valid_21626418
  var valid_21626419 = formData.getOrDefault("SkipFinalSnapshot")
  valid_21626419 = validateParameter(valid_21626419, JBool, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "SkipFinalSnapshot", valid_21626419
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626420: Call_PostDeleteDBCluster_21626405; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ## 
  let valid = call_21626420.validator(path, query, header, formData, body, _)
  let scheme = call_21626420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626420.makeUrl(scheme.get, call_21626420.host, call_21626420.base,
                               call_21626420.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626420, uri, valid, _)

proc call*(call_21626421: Call_PostDeleteDBCluster_21626405;
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
  var query_21626422 = newJObject()
  var formData_21626423 = newJObject()
  add(formData_21626423, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_21626422, "Action", newJString(Action))
  add(formData_21626423, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626422, "Version", newJString(Version))
  add(formData_21626423, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_21626421.call(nil, query_21626422, nil, formData_21626423, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_21626405(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_21626406, base: "/",
    makeUrl: url_PostDeleteDBCluster_21626407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_21626387 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBCluster_21626389(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBCluster_21626388(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626390 = query.getOrDefault("DBClusterIdentifier")
  valid_21626390 = validateParameter(valid_21626390, JString, required = true,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "DBClusterIdentifier", valid_21626390
  var valid_21626391 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_21626391
  var valid_21626392 = query.getOrDefault("Action")
  valid_21626392 = validateParameter(valid_21626392, JString, required = true,
                                   default = newJString("DeleteDBCluster"))
  if valid_21626392 != nil:
    section.add "Action", valid_21626392
  var valid_21626393 = query.getOrDefault("SkipFinalSnapshot")
  valid_21626393 = validateParameter(valid_21626393, JBool, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "SkipFinalSnapshot", valid_21626393
  var valid_21626394 = query.getOrDefault("Version")
  valid_21626394 = validateParameter(valid_21626394, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626394 != nil:
    section.add "Version", valid_21626394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626395 = header.getOrDefault("X-Amz-Date")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Date", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Security-Token", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Algorithm", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Signature")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Signature", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Credential")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Credential", valid_21626401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626402: Call_GetDeleteDBCluster_21626387; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a previously provisioned cluster. When you delete a cluster, all automated backups for that cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified cluster are not deleted.</p> <p/>
  ## 
  let valid = call_21626402.validator(path, query, header, formData, body, _)
  let scheme = call_21626402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626402.makeUrl(scheme.get, call_21626402.host, call_21626402.base,
                               call_21626402.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626402, uri, valid, _)

proc call*(call_21626403: Call_GetDeleteDBCluster_21626387;
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
  var query_21626404 = newJObject()
  add(query_21626404, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626404, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_21626404, "Action", newJString(Action))
  add(query_21626404, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_21626404, "Version", newJString(Version))
  result = call_21626403.call(nil, query_21626404, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_21626387(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_21626388,
    base: "/", makeUrl: url_GetDeleteDBCluster_21626389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_21626440 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBClusterParameterGroup_21626442(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBClusterParameterGroup_21626441(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626443 = query.getOrDefault("Action")
  valid_21626443 = validateParameter(valid_21626443, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_21626443 != nil:
    section.add "Action", valid_21626443
  var valid_21626444 = query.getOrDefault("Version")
  valid_21626444 = validateParameter(valid_21626444, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626444 != nil:
    section.add "Version", valid_21626444
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626445 = header.getOrDefault("X-Amz-Date")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Date", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Security-Token", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Algorithm", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Signature")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Signature", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Credential")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Credential", valid_21626451
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_21626452 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_21626452 = validateParameter(valid_21626452, JString, required = true,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "DBClusterParameterGroupName", valid_21626452
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626453: Call_PostDeleteDBClusterParameterGroup_21626440;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ## 
  let valid = call_21626453.validator(path, query, header, formData, body, _)
  let scheme = call_21626453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626453.makeUrl(scheme.get, call_21626453.host, call_21626453.base,
                               call_21626453.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626453, uri, valid, _)

proc call*(call_21626454: Call_PostDeleteDBClusterParameterGroup_21626440;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_21626455 = newJObject()
  var formData_21626456 = newJObject()
  add(query_21626455, "Action", newJString(Action))
  add(formData_21626456, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_21626455, "Version", newJString(Version))
  result = call_21626454.call(nil, query_21626455, nil, formData_21626456, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_21626440(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_21626441, base: "/",
    makeUrl: url_PostDeleteDBClusterParameterGroup_21626442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_21626424 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBClusterParameterGroup_21626426(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBClusterParameterGroup_21626425(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626427 = query.getOrDefault("DBClusterParameterGroupName")
  valid_21626427 = validateParameter(valid_21626427, JString, required = true,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "DBClusterParameterGroupName", valid_21626427
  var valid_21626428 = query.getOrDefault("Action")
  valid_21626428 = validateParameter(valid_21626428, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_21626428 != nil:
    section.add "Action", valid_21626428
  var valid_21626429 = query.getOrDefault("Version")
  valid_21626429 = validateParameter(valid_21626429, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626429 != nil:
    section.add "Version", valid_21626429
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626430 = header.getOrDefault("X-Amz-Date")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Date", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Security-Token", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Algorithm", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Signature")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Signature", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Credential")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Credential", valid_21626436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626437: Call_GetDeleteDBClusterParameterGroup_21626424;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ## 
  let valid = call_21626437.validator(path, query, header, formData, body, _)
  let scheme = call_21626437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626437.makeUrl(scheme.get, call_21626437.host, call_21626437.base,
                               call_21626437.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626437, uri, valid, _)

proc call*(call_21626438: Call_GetDeleteDBClusterParameterGroup_21626424;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified cluster parameter group. The cluster parameter group to be deleted can't be associated with any clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing cluster parameter group.</p> </li> <li> <p>You can't delete a default cluster parameter group.</p> </li> <li> <p>Cannot be associated with any clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626439 = newJObject()
  add(query_21626439, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_21626439, "Action", newJString(Action))
  add(query_21626439, "Version", newJString(Version))
  result = call_21626438.call(nil, query_21626439, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_21626424(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_21626425, base: "/",
    makeUrl: url_GetDeleteDBClusterParameterGroup_21626426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_21626473 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBClusterSnapshot_21626475(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBClusterSnapshot_21626474(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626476 = query.getOrDefault("Action")
  valid_21626476 = validateParameter(valid_21626476, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_21626476 != nil:
    section.add "Action", valid_21626476
  var valid_21626477 = query.getOrDefault("Version")
  valid_21626477 = validateParameter(valid_21626477, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626477 != nil:
    section.add "Version", valid_21626477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626478 = header.getOrDefault("X-Amz-Date")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Date", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Security-Token", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Algorithm", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Signature")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Signature", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Credential")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Credential", valid_21626484
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_21626485 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21626485 = validateParameter(valid_21626485, JString, required = true,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21626485
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626486: Call_PostDeleteDBClusterSnapshot_21626473;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_21626486.validator(path, query, header, formData, body, _)
  let scheme = call_21626486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626486.makeUrl(scheme.get, call_21626486.host, call_21626486.base,
                               call_21626486.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626486, uri, valid, _)

proc call*(call_21626487: Call_PostDeleteDBClusterSnapshot_21626473;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626488 = newJObject()
  var formData_21626489 = newJObject()
  add(formData_21626489, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_21626488, "Action", newJString(Action))
  add(query_21626488, "Version", newJString(Version))
  result = call_21626487.call(nil, query_21626488, nil, formData_21626489, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_21626473(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_21626474, base: "/",
    makeUrl: url_PostDeleteDBClusterSnapshot_21626475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_21626457 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBClusterSnapshot_21626459(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBClusterSnapshot_21626458(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626460 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21626460 = validateParameter(valid_21626460, JString, required = true,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21626460
  var valid_21626461 = query.getOrDefault("Action")
  valid_21626461 = validateParameter(valid_21626461, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_21626461 != nil:
    section.add "Action", valid_21626461
  var valid_21626462 = query.getOrDefault("Version")
  valid_21626462 = validateParameter(valid_21626462, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626462 != nil:
    section.add "Version", valid_21626462
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626463 = header.getOrDefault("X-Amz-Date")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Date", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Security-Token", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Algorithm", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Signature")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Signature", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Credential")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Credential", valid_21626469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626470: Call_GetDeleteDBClusterSnapshot_21626457;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_21626470.validator(path, query, header, formData, body, _)
  let scheme = call_21626470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626470.makeUrl(scheme.get, call_21626470.host, call_21626470.base,
                               call_21626470.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626470, uri, valid, _)

proc call*(call_21626471: Call_GetDeleteDBClusterSnapshot_21626457;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626472 = newJObject()
  add(query_21626472, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_21626472, "Action", newJString(Action))
  add(query_21626472, "Version", newJString(Version))
  result = call_21626471.call(nil, query_21626472, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_21626457(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_21626458, base: "/",
    makeUrl: url_GetDeleteDBClusterSnapshot_21626459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_21626506 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBInstance_21626508(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_21626507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626509 = query.getOrDefault("Action")
  valid_21626509 = validateParameter(valid_21626509, JString, required = true,
                                   default = newJString("DeleteDBInstance"))
  if valid_21626509 != nil:
    section.add "Action", valid_21626509
  var valid_21626510 = query.getOrDefault("Version")
  valid_21626510 = validateParameter(valid_21626510, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626510 != nil:
    section.add "Version", valid_21626510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626511 = header.getOrDefault("X-Amz-Date")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Date", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Security-Token", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Algorithm", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Signature")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Signature", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Credential")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Credential", valid_21626517
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626518 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626518 = validateParameter(valid_21626518, JString, required = true,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "DBInstanceIdentifier", valid_21626518
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626519: Call_PostDeleteDBInstance_21626506; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a previously provisioned instance. 
  ## 
  let valid = call_21626519.validator(path, query, header, formData, body, _)
  let scheme = call_21626519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626519.makeUrl(scheme.get, call_21626519.host, call_21626519.base,
                               call_21626519.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626519, uri, valid, _)

proc call*(call_21626520: Call_PostDeleteDBInstance_21626506;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626521 = newJObject()
  var formData_21626522 = newJObject()
  add(formData_21626522, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21626521, "Action", newJString(Action))
  add(query_21626521, "Version", newJString(Version))
  result = call_21626520.call(nil, query_21626521, nil, formData_21626522, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_21626506(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_21626507, base: "/",
    makeUrl: url_PostDeleteDBInstance_21626508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_21626490 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBInstance_21626492(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_21626491(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626493 = query.getOrDefault("Action")
  valid_21626493 = validateParameter(valid_21626493, JString, required = true,
                                   default = newJString("DeleteDBInstance"))
  if valid_21626493 != nil:
    section.add "Action", valid_21626493
  var valid_21626494 = query.getOrDefault("Version")
  valid_21626494 = validateParameter(valid_21626494, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626494 != nil:
    section.add "Version", valid_21626494
  var valid_21626495 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626495 = validateParameter(valid_21626495, JString, required = true,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "DBInstanceIdentifier", valid_21626495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626496 = header.getOrDefault("X-Amz-Date")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Date", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Security-Token", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Algorithm", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Signature")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Signature", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Credential")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Credential", valid_21626502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626503: Call_GetDeleteDBInstance_21626490; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a previously provisioned instance. 
  ## 
  let valid = call_21626503.validator(path, query, header, formData, body, _)
  let scheme = call_21626503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626503.makeUrl(scheme.get, call_21626503.host, call_21626503.base,
                               call_21626503.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626503, uri, valid, _)

proc call*(call_21626504: Call_GetDeleteDBInstance_21626490;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned instance. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The instance identifier for the instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing instance.</p> </li> </ul>
  var query_21626505 = newJObject()
  add(query_21626505, "Action", newJString(Action))
  add(query_21626505, "Version", newJString(Version))
  add(query_21626505, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626504.call(nil, query_21626505, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_21626490(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_21626491, base: "/",
    makeUrl: url_GetDeleteDBInstance_21626492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_21626539 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSubnetGroup_21626541(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_21626540(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626542 = query.getOrDefault("Action")
  valid_21626542 = validateParameter(valid_21626542, JString, required = true,
                                   default = newJString("DeleteDBSubnetGroup"))
  if valid_21626542 != nil:
    section.add "Action", valid_21626542
  var valid_21626543 = query.getOrDefault("Version")
  valid_21626543 = validateParameter(valid_21626543, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626543 != nil:
    section.add "Version", valid_21626543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626544 = header.getOrDefault("X-Amz-Date")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Date", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Security-Token", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Algorithm", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Signature")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Signature", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-Credential")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-Credential", valid_21626550
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21626551 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626551 = validateParameter(valid_21626551, JString, required = true,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "DBSubnetGroupName", valid_21626551
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626552: Call_PostDeleteDBSubnetGroup_21626539;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_21626552.validator(path, query, header, formData, body, _)
  let scheme = call_21626552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626552.makeUrl(scheme.get, call_21626552.host, call_21626552.base,
                               call_21626552.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626552, uri, valid, _)

proc call*(call_21626553: Call_PostDeleteDBSubnetGroup_21626539;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626554 = newJObject()
  var formData_21626555 = newJObject()
  add(formData_21626555, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626554, "Action", newJString(Action))
  add(query_21626554, "Version", newJString(Version))
  result = call_21626553.call(nil, query_21626554, nil, formData_21626555, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_21626539(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_21626540, base: "/",
    makeUrl: url_PostDeleteDBSubnetGroup_21626541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_21626523 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSubnetGroup_21626525(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_21626524(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626526 = query.getOrDefault("Action")
  valid_21626526 = validateParameter(valid_21626526, JString, required = true,
                                   default = newJString("DeleteDBSubnetGroup"))
  if valid_21626526 != nil:
    section.add "Action", valid_21626526
  var valid_21626527 = query.getOrDefault("DBSubnetGroupName")
  valid_21626527 = validateParameter(valid_21626527, JString, required = true,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "DBSubnetGroupName", valid_21626527
  var valid_21626528 = query.getOrDefault("Version")
  valid_21626528 = validateParameter(valid_21626528, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626528 != nil:
    section.add "Version", valid_21626528
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626529 = header.getOrDefault("X-Amz-Date")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Date", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Security-Token", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Algorithm", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Signature")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Signature", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Credential")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Credential", valid_21626535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626536: Call_GetDeleteDBSubnetGroup_21626523;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_21626536.validator(path, query, header, formData, body, _)
  let scheme = call_21626536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626536.makeUrl(scheme.get, call_21626536.host, call_21626536.base,
                               call_21626536.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626536, uri, valid, _)

proc call*(call_21626537: Call_GetDeleteDBSubnetGroup_21626523;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_21626538 = newJObject()
  add(query_21626538, "Action", newJString(Action))
  add(query_21626538, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626538, "Version", newJString(Version))
  result = call_21626537.call(nil, query_21626538, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_21626523(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_21626524, base: "/",
    makeUrl: url_GetDeleteDBSubnetGroup_21626525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeCertificates_21626575 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeCertificates_21626577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeCertificates_21626576(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626578 = query.getOrDefault("Action")
  valid_21626578 = validateParameter(valid_21626578, JString, required = true,
                                   default = newJString("DescribeCertificates"))
  if valid_21626578 != nil:
    section.add "Action", valid_21626578
  var valid_21626579 = query.getOrDefault("Version")
  valid_21626579 = validateParameter(valid_21626579, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626579 != nil:
    section.add "Version", valid_21626579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626580 = header.getOrDefault("X-Amz-Date")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Date", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Security-Token", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Algorithm", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Signature")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Signature", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Credential")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Credential", valid_21626586
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
  var valid_21626587 = formData.getOrDefault("CertificateIdentifier")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "CertificateIdentifier", valid_21626587
  var valid_21626588 = formData.getOrDefault("Marker")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "Marker", valid_21626588
  var valid_21626589 = formData.getOrDefault("Filters")
  valid_21626589 = validateParameter(valid_21626589, JArray, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "Filters", valid_21626589
  var valid_21626590 = formData.getOrDefault("MaxRecords")
  valid_21626590 = validateParameter(valid_21626590, JInt, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "MaxRecords", valid_21626590
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626591: Call_PostDescribeCertificates_21626575;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account.
  ## 
  let valid = call_21626591.validator(path, query, header, formData, body, _)
  let scheme = call_21626591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626591.makeUrl(scheme.get, call_21626591.host, call_21626591.base,
                               call_21626591.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626591, uri, valid, _)

proc call*(call_21626592: Call_PostDescribeCertificates_21626575;
          CertificateIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeCertificates"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeCertificates
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account.
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
  var query_21626593 = newJObject()
  var formData_21626594 = newJObject()
  add(formData_21626594, "CertificateIdentifier",
      newJString(CertificateIdentifier))
  add(formData_21626594, "Marker", newJString(Marker))
  add(query_21626593, "Action", newJString(Action))
  if Filters != nil:
    formData_21626594.add "Filters", Filters
  add(formData_21626594, "MaxRecords", newJInt(MaxRecords))
  add(query_21626593, "Version", newJString(Version))
  result = call_21626592.call(nil, query_21626593, nil, formData_21626594, nil)

var postDescribeCertificates* = Call_PostDescribeCertificates_21626575(
    name: "postDescribeCertificates", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_PostDescribeCertificates_21626576, base: "/",
    makeUrl: url_PostDescribeCertificates_21626577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeCertificates_21626556 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeCertificates_21626558(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeCertificates_21626557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626559 = query.getOrDefault("MaxRecords")
  valid_21626559 = validateParameter(valid_21626559, JInt, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "MaxRecords", valid_21626559
  var valid_21626560 = query.getOrDefault("CertificateIdentifier")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "CertificateIdentifier", valid_21626560
  var valid_21626561 = query.getOrDefault("Filters")
  valid_21626561 = validateParameter(valid_21626561, JArray, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "Filters", valid_21626561
  var valid_21626562 = query.getOrDefault("Action")
  valid_21626562 = validateParameter(valid_21626562, JString, required = true,
                                   default = newJString("DescribeCertificates"))
  if valid_21626562 != nil:
    section.add "Action", valid_21626562
  var valid_21626563 = query.getOrDefault("Marker")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "Marker", valid_21626563
  var valid_21626564 = query.getOrDefault("Version")
  valid_21626564 = validateParameter(valid_21626564, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626564 != nil:
    section.add "Version", valid_21626564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626565 = header.getOrDefault("X-Amz-Date")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Date", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Security-Token", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-Algorithm", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Signature")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Signature", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Credential")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Credential", valid_21626571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626572: Call_GetDescribeCertificates_21626556;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon DocumentDB for this AWS account.
  ## 
  let valid = call_21626572.validator(path, query, header, formData, body, _)
  let scheme = call_21626572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626572.makeUrl(scheme.get, call_21626572.host, call_21626572.base,
                               call_21626572.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626572, uri, valid, _)

proc call*(call_21626573: Call_GetDescribeCertificates_21626556;
          MaxRecords: int = 0; CertificateIdentifier: string = "";
          Filters: JsonNode = nil; Action: string = "DescribeCertificates";
          Marker: string = ""; Version: string = "2014-10-31"): Recallable =
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
  var query_21626574 = newJObject()
  add(query_21626574, "MaxRecords", newJInt(MaxRecords))
  add(query_21626574, "CertificateIdentifier", newJString(CertificateIdentifier))
  if Filters != nil:
    query_21626574.add "Filters", Filters
  add(query_21626574, "Action", newJString(Action))
  add(query_21626574, "Marker", newJString(Marker))
  add(query_21626574, "Version", newJString(Version))
  result = call_21626573.call(nil, query_21626574, nil, nil, nil)

var getDescribeCertificates* = Call_GetDescribeCertificates_21626556(
    name: "getDescribeCertificates", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_GetDescribeCertificates_21626557, base: "/",
    makeUrl: url_GetDescribeCertificates_21626558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_21626614 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBClusterParameterGroups_21626616(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterParameterGroups_21626615(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626617 = query.getOrDefault("Action")
  valid_21626617 = validateParameter(valid_21626617, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_21626617 != nil:
    section.add "Action", valid_21626617
  var valid_21626618 = query.getOrDefault("Version")
  valid_21626618 = validateParameter(valid_21626618, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626618 != nil:
    section.add "Version", valid_21626618
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626619 = header.getOrDefault("X-Amz-Date")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Date", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Security-Token", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Algorithm", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-Signature")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-Signature", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626624
  var valid_21626625 = header.getOrDefault("X-Amz-Credential")
  valid_21626625 = validateParameter(valid_21626625, JString, required = false,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "X-Amz-Credential", valid_21626625
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: JString
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_21626626 = formData.getOrDefault("Marker")
  valid_21626626 = validateParameter(valid_21626626, JString, required = false,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "Marker", valid_21626626
  var valid_21626627 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "DBClusterParameterGroupName", valid_21626627
  var valid_21626628 = formData.getOrDefault("Filters")
  valid_21626628 = validateParameter(valid_21626628, JArray, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "Filters", valid_21626628
  var valid_21626629 = formData.getOrDefault("MaxRecords")
  valid_21626629 = validateParameter(valid_21626629, JInt, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "MaxRecords", valid_21626629
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626630: Call_PostDescribeDBClusterParameterGroups_21626614;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ## 
  let valid = call_21626630.validator(path, query, header, formData, body, _)
  let scheme = call_21626630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626630.makeUrl(scheme.get, call_21626630.host, call_21626630.base,
                               call_21626630.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626630, uri, valid, _)

proc call*(call_21626631: Call_PostDescribeDBClusterParameterGroups_21626614;
          Marker: string = ""; Action: string = "DescribeDBClusterParameterGroups";
          DBClusterParameterGroupName: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterParameterGroups
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : <p>The name of a specific cluster parameter group to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_21626632 = newJObject()
  var formData_21626633 = newJObject()
  add(formData_21626633, "Marker", newJString(Marker))
  add(query_21626632, "Action", newJString(Action))
  add(formData_21626633, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_21626633.add "Filters", Filters
  add(formData_21626633, "MaxRecords", newJInt(MaxRecords))
  add(query_21626632, "Version", newJString(Version))
  result = call_21626631.call(nil, query_21626632, nil, formData_21626633, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_21626614(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_21626615, base: "/",
    makeUrl: url_PostDescribeDBClusterParameterGroups_21626616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_21626595 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBClusterParameterGroups_21626597(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterParameterGroups_21626596(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626598 = query.getOrDefault("MaxRecords")
  valid_21626598 = validateParameter(valid_21626598, JInt, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "MaxRecords", valid_21626598
  var valid_21626599 = query.getOrDefault("DBClusterParameterGroupName")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "DBClusterParameterGroupName", valid_21626599
  var valid_21626600 = query.getOrDefault("Filters")
  valid_21626600 = validateParameter(valid_21626600, JArray, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "Filters", valid_21626600
  var valid_21626601 = query.getOrDefault("Action")
  valid_21626601 = validateParameter(valid_21626601, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_21626601 != nil:
    section.add "Action", valid_21626601
  var valid_21626602 = query.getOrDefault("Marker")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "Marker", valid_21626602
  var valid_21626603 = query.getOrDefault("Version")
  valid_21626603 = validateParameter(valid_21626603, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626603 != nil:
    section.add "Version", valid_21626603
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626604 = header.getOrDefault("X-Amz-Date")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Date", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Security-Token", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Algorithm", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-Signature")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-Signature", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626609
  var valid_21626610 = header.getOrDefault("X-Amz-Credential")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "X-Amz-Credential", valid_21626610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626611: Call_GetDescribeDBClusterParameterGroups_21626595;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified cluster parameter group. 
  ## 
  let valid = call_21626611.validator(path, query, header, formData, body, _)
  let scheme = call_21626611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626611.makeUrl(scheme.get, call_21626611.host, call_21626611.base,
                               call_21626611.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626611, uri, valid, _)

proc call*(call_21626612: Call_GetDescribeDBClusterParameterGroups_21626595;
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
  var query_21626613 = newJObject()
  add(query_21626613, "MaxRecords", newJInt(MaxRecords))
  add(query_21626613, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_21626613.add "Filters", Filters
  add(query_21626613, "Action", newJString(Action))
  add(query_21626613, "Marker", newJString(Marker))
  add(query_21626613, "Version", newJString(Version))
  result = call_21626612.call(nil, query_21626613, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_21626595(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_21626596, base: "/",
    makeUrl: url_GetDescribeDBClusterParameterGroups_21626597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_21626654 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBClusterParameters_21626656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterParameters_21626655(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626657 = query.getOrDefault("Action")
  valid_21626657 = validateParameter(valid_21626657, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_21626657 != nil:
    section.add "Action", valid_21626657
  var valid_21626658 = query.getOrDefault("Version")
  valid_21626658 = validateParameter(valid_21626658, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626658 != nil:
    section.add "Version", valid_21626658
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626659 = header.getOrDefault("X-Amz-Date")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Date", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Security-Token", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Algorithm", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Signature")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Signature", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Credential")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Credential", valid_21626665
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Source: JString
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  section = newJObject()
  var valid_21626666 = formData.getOrDefault("Marker")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "Marker", valid_21626666
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_21626667 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_21626667 = validateParameter(valid_21626667, JString, required = true,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "DBClusterParameterGroupName", valid_21626667
  var valid_21626668 = formData.getOrDefault("Filters")
  valid_21626668 = validateParameter(valid_21626668, JArray, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "Filters", valid_21626668
  var valid_21626669 = formData.getOrDefault("MaxRecords")
  valid_21626669 = validateParameter(valid_21626669, JInt, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "MaxRecords", valid_21626669
  var valid_21626670 = formData.getOrDefault("Source")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "Source", valid_21626670
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626671: Call_PostDescribeDBClusterParameters_21626654;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ## 
  let valid = call_21626671.validator(path, query, header, formData, body, _)
  let scheme = call_21626671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626671.makeUrl(scheme.get, call_21626671.host, call_21626671.base,
                               call_21626671.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626671, uri, valid, _)

proc call*(call_21626672: Call_PostDescribeDBClusterParameters_21626654;
          DBClusterParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBClusterParameters"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"; Source: string = ""): Recallable =
  ## postDescribeDBClusterParameters
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of a specific cluster parameter group to return parameter details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the name of an existing <code>DBClusterParameterGroup</code>.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  ##   Source: string
  ##         :  A value that indicates to return only parameters for a specific source. Parameter sources can be <code>engine</code>, <code>service</code>, or <code>customer</code>. 
  var query_21626673 = newJObject()
  var formData_21626674 = newJObject()
  add(formData_21626674, "Marker", newJString(Marker))
  add(query_21626673, "Action", newJString(Action))
  add(formData_21626674, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_21626674.add "Filters", Filters
  add(formData_21626674, "MaxRecords", newJInt(MaxRecords))
  add(query_21626673, "Version", newJString(Version))
  add(formData_21626674, "Source", newJString(Source))
  result = call_21626672.call(nil, query_21626673, nil, formData_21626674, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_21626654(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_21626655, base: "/",
    makeUrl: url_PostDescribeDBClusterParameters_21626656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_21626634 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBClusterParameters_21626636(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterParameters_21626635(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626637 = query.getOrDefault("MaxRecords")
  valid_21626637 = validateParameter(valid_21626637, JInt, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "MaxRecords", valid_21626637
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_21626638 = query.getOrDefault("DBClusterParameterGroupName")
  valid_21626638 = validateParameter(valid_21626638, JString, required = true,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "DBClusterParameterGroupName", valid_21626638
  var valid_21626639 = query.getOrDefault("Filters")
  valid_21626639 = validateParameter(valid_21626639, JArray, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "Filters", valid_21626639
  var valid_21626640 = query.getOrDefault("Action")
  valid_21626640 = validateParameter(valid_21626640, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_21626640 != nil:
    section.add "Action", valid_21626640
  var valid_21626641 = query.getOrDefault("Marker")
  valid_21626641 = validateParameter(valid_21626641, JString, required = false,
                                   default = nil)
  if valid_21626641 != nil:
    section.add "Marker", valid_21626641
  var valid_21626642 = query.getOrDefault("Source")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "Source", valid_21626642
  var valid_21626643 = query.getOrDefault("Version")
  valid_21626643 = validateParameter(valid_21626643, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626643 != nil:
    section.add "Version", valid_21626643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626644 = header.getOrDefault("X-Amz-Date")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Date", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Security-Token", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Algorithm", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Signature")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Signature", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Credential")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Credential", valid_21626650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626651: Call_GetDescribeDBClusterParameters_21626634;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the detailed parameter list for a particular cluster parameter group.
  ## 
  let valid = call_21626651.validator(path, query, header, formData, body, _)
  let scheme = call_21626651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626651.makeUrl(scheme.get, call_21626651.host, call_21626651.base,
                               call_21626651.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626651, uri, valid, _)

proc call*(call_21626652: Call_GetDescribeDBClusterParameters_21626634;
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
  var query_21626653 = newJObject()
  add(query_21626653, "MaxRecords", newJInt(MaxRecords))
  add(query_21626653, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_21626653.add "Filters", Filters
  add(query_21626653, "Action", newJString(Action))
  add(query_21626653, "Marker", newJString(Marker))
  add(query_21626653, "Source", newJString(Source))
  add(query_21626653, "Version", newJString(Version))
  result = call_21626652.call(nil, query_21626653, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_21626634(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_21626635, base: "/",
    makeUrl: url_GetDescribeDBClusterParameters_21626636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_21626691 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBClusterSnapshotAttributes_21626693(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_21626692(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626694 = query.getOrDefault("Action")
  valid_21626694 = validateParameter(valid_21626694, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_21626694 != nil:
    section.add "Action", valid_21626694
  var valid_21626695 = query.getOrDefault("Version")
  valid_21626695 = validateParameter(valid_21626695, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626695 != nil:
    section.add "Version", valid_21626695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626696 = header.getOrDefault("X-Amz-Date")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Date", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Security-Token", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Algorithm", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Signature")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Signature", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-Credential")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Credential", valid_21626702
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_21626703 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21626703 = validateParameter(valid_21626703, JString, required = true,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21626703
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626704: Call_PostDescribeDBClusterSnapshotAttributes_21626691;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_21626704.validator(path, query, header, formData, body, _)
  let scheme = call_21626704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626704.makeUrl(scheme.get, call_21626704.host, call_21626704.base,
                               call_21626704.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626704, uri, valid, _)

proc call*(call_21626705: Call_PostDescribeDBClusterSnapshotAttributes_21626691;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626706 = newJObject()
  var formData_21626707 = newJObject()
  add(formData_21626707, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_21626706, "Action", newJString(Action))
  add(query_21626706, "Version", newJString(Version))
  result = call_21626705.call(nil, query_21626706, nil, formData_21626707, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_21626691(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_21626692,
    base: "/", makeUrl: url_PostDescribeDBClusterSnapshotAttributes_21626693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_21626675 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBClusterSnapshotAttributes_21626677(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_21626676(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626678 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21626678 = validateParameter(valid_21626678, JString, required = true,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21626678
  var valid_21626679 = query.getOrDefault("Action")
  valid_21626679 = validateParameter(valid_21626679, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_21626679 != nil:
    section.add "Action", valid_21626679
  var valid_21626680 = query.getOrDefault("Version")
  valid_21626680 = validateParameter(valid_21626680, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626680 != nil:
    section.add "Version", valid_21626680
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626681 = header.getOrDefault("X-Amz-Date")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Date", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Security-Token", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Algorithm", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Signature")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Signature", valid_21626685
  var valid_21626686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626686
  var valid_21626687 = header.getOrDefault("X-Amz-Credential")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Credential", valid_21626687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626688: Call_GetDescribeDBClusterSnapshotAttributes_21626675;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_21626688.validator(path, query, header, formData, body, _)
  let scheme = call_21626688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626688.makeUrl(scheme.get, call_21626688.host, call_21626688.base,
                               call_21626688.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626688, uri, valid, _)

proc call*(call_21626689: Call_GetDescribeDBClusterSnapshotAttributes_21626675;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626690 = newJObject()
  add(query_21626690, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_21626690, "Action", newJString(Action))
  add(query_21626690, "Version", newJString(Version))
  result = call_21626689.call(nil, query_21626690, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_21626675(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_21626676,
    base: "/", makeUrl: url_GetDescribeDBClusterSnapshotAttributes_21626677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_21626731 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBClusterSnapshots_21626733(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusterSnapshots_21626732(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626734 = query.getOrDefault("Action")
  valid_21626734 = validateParameter(valid_21626734, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_21626734 != nil:
    section.add "Action", valid_21626734
  var valid_21626735 = query.getOrDefault("Version")
  valid_21626735 = validateParameter(valid_21626735, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626735 != nil:
    section.add "Version", valid_21626735
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626736 = header.getOrDefault("X-Amz-Date")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Date", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Security-Token", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Algorithm", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Signature")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Signature", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-Credential")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Credential", valid_21626742
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SnapshotType: JString
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_21626743 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21626743
  var valid_21626744 = formData.getOrDefault("IncludeShared")
  valid_21626744 = validateParameter(valid_21626744, JBool, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "IncludeShared", valid_21626744
  var valid_21626745 = formData.getOrDefault("IncludePublic")
  valid_21626745 = validateParameter(valid_21626745, JBool, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "IncludePublic", valid_21626745
  var valid_21626746 = formData.getOrDefault("SnapshotType")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "SnapshotType", valid_21626746
  var valid_21626747 = formData.getOrDefault("Marker")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "Marker", valid_21626747
  var valid_21626748 = formData.getOrDefault("Filters")
  valid_21626748 = validateParameter(valid_21626748, JArray, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "Filters", valid_21626748
  var valid_21626749 = formData.getOrDefault("MaxRecords")
  valid_21626749 = validateParameter(valid_21626749, JInt, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "MaxRecords", valid_21626749
  var valid_21626750 = formData.getOrDefault("DBClusterIdentifier")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "DBClusterIdentifier", valid_21626750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626751: Call_PostDescribeDBClusterSnapshots_21626731;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_21626751.validator(path, query, header, formData, body, _)
  let scheme = call_21626751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626751.makeUrl(scheme.get, call_21626751.host, call_21626751.base,
                               call_21626751.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626751, uri, valid, _)

proc call*(call_21626752: Call_PostDescribeDBClusterSnapshots_21626731;
          DBClusterSnapshotIdentifier: string = ""; IncludeShared: bool = false;
          IncludePublic: bool = false; SnapshotType: string = ""; Marker: string = "";
          Action: string = "DescribeDBClusterSnapshots"; Filters: JsonNode = nil;
          MaxRecords: int = 0; DBClusterIdentifier: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshots
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   SnapshotType: string
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_21626753 = newJObject()
  var formData_21626754 = newJObject()
  add(formData_21626754, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_21626754, "IncludeShared", newJBool(IncludeShared))
  add(formData_21626754, "IncludePublic", newJBool(IncludePublic))
  add(formData_21626754, "SnapshotType", newJString(SnapshotType))
  add(formData_21626754, "Marker", newJString(Marker))
  add(query_21626753, "Action", newJString(Action))
  if Filters != nil:
    formData_21626754.add "Filters", Filters
  add(formData_21626754, "MaxRecords", newJInt(MaxRecords))
  add(formData_21626754, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626753, "Version", newJString(Version))
  result = call_21626752.call(nil, query_21626753, nil, formData_21626754, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_21626731(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_21626732, base: "/",
    makeUrl: url_PostDescribeDBClusterSnapshots_21626733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_21626708 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBClusterSnapshots_21626710(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusterSnapshots_21626709(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IncludePublic: JBool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterSnapshotIdentifier: JString
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   IncludeShared: JBool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SnapshotType: JString
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626711 = query.getOrDefault("IncludePublic")
  valid_21626711 = validateParameter(valid_21626711, JBool, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "IncludePublic", valid_21626711
  var valid_21626712 = query.getOrDefault("MaxRecords")
  valid_21626712 = validateParameter(valid_21626712, JInt, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "MaxRecords", valid_21626712
  var valid_21626713 = query.getOrDefault("DBClusterIdentifier")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "DBClusterIdentifier", valid_21626713
  var valid_21626714 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21626714
  var valid_21626715 = query.getOrDefault("Filters")
  valid_21626715 = validateParameter(valid_21626715, JArray, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "Filters", valid_21626715
  var valid_21626716 = query.getOrDefault("IncludeShared")
  valid_21626716 = validateParameter(valid_21626716, JBool, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "IncludeShared", valid_21626716
  var valid_21626717 = query.getOrDefault("Action")
  valid_21626717 = validateParameter(valid_21626717, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_21626717 != nil:
    section.add "Action", valid_21626717
  var valid_21626718 = query.getOrDefault("Marker")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "Marker", valid_21626718
  var valid_21626719 = query.getOrDefault("SnapshotType")
  valid_21626719 = validateParameter(valid_21626719, JString, required = false,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "SnapshotType", valid_21626719
  var valid_21626720 = query.getOrDefault("Version")
  valid_21626720 = validateParameter(valid_21626720, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626720 != nil:
    section.add "Version", valid_21626720
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626721 = header.getOrDefault("X-Amz-Date")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Date", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Security-Token", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Algorithm", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Signature")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Signature", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Credential")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Credential", valid_21626727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626728: Call_GetDescribeDBClusterSnapshots_21626708;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_21626728.validator(path, query, header, formData, body, _)
  let scheme = call_21626728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626728.makeUrl(scheme.get, call_21626728.host, call_21626728.base,
                               call_21626728.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626728, uri, valid, _)

proc call*(call_21626729: Call_GetDescribeDBClusterSnapshots_21626708;
          IncludePublic: bool = false; MaxRecords: int = 0;
          DBClusterIdentifier: string = "";
          DBClusterSnapshotIdentifier: string = ""; Filters: JsonNode = nil;
          IncludeShared: bool = false;
          Action: string = "DescribeDBClusterSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshots
  ## Returns information about cluster snapshots. This API operation supports pagination.
  ##   IncludePublic: bool
  ##                : Set to <code>true</code> to include manual cluster snapshots that are public and can be copied or restored by any AWS account, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The ID of the cluster to retrieve the list of cluster snapshots for. This parameter can't be used with the <code>DBClusterSnapshotIdentifier</code> parameter. This parameter is not case sensitive. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   DBClusterSnapshotIdentifier: string
  ##                              : <p>A specific cluster snapshot identifier to describe. This parameter can't be used with the <code>DBClusterIdentifier</code> parameter. This value is stored as a lowercase string. </p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBClusterSnapshot</code>.</p> </li> <li> <p>If this identifier is for an automated snapshot, the <code>SnapshotType</code> parameter must also be specified.</p> </li> </ul>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   IncludeShared: bool
  ##                : Set to <code>true</code> to include shared manual cluster snapshots from other AWS accounts that this AWS account has been given permission to copy or restore, and otherwise <code>false</code>. The default is <code>false</code>.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   SnapshotType: string
  ##               : <p>The type of cluster snapshots to be returned. You can specify one of the following values:</p> <ul> <li> <p> <code>automated</code> - Return all cluster snapshots that Amazon DocumentDB has automatically created for your AWS account.</p> </li> <li> <p> <code>manual</code> - Return all cluster snapshots that you have manually created for your AWS account.</p> </li> <li> <p> <code>shared</code> - Return all manual cluster snapshots that have been shared to your AWS account.</p> </li> <li> <p> <code>public</code> - Return all cluster snapshots that have been marked as public.</p> </li> </ul> <p>If you don't specify a <code>SnapshotType</code> value, then both automated and manual cluster snapshots are returned. You can include shared cluster snapshots with these results by setting the <code>IncludeShared</code> parameter to <code>true</code>. You can include public cluster snapshots with these results by setting the <code>IncludePublic</code> parameter to <code>true</code>.</p> <p>The <code>IncludeShared</code> and <code>IncludePublic</code> parameters don't apply for <code>SnapshotType</code> values of <code>manual</code> or <code>automated</code>. The <code>IncludePublic</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>shared</code>. The <code>IncludeShared</code> parameter doesn't apply when <code>SnapshotType</code> is set to <code>public</code>.</p>
  ##   Version: string (required)
  var query_21626730 = newJObject()
  add(query_21626730, "IncludePublic", newJBool(IncludePublic))
  add(query_21626730, "MaxRecords", newJInt(MaxRecords))
  add(query_21626730, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626730, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Filters != nil:
    query_21626730.add "Filters", Filters
  add(query_21626730, "IncludeShared", newJBool(IncludeShared))
  add(query_21626730, "Action", newJString(Action))
  add(query_21626730, "Marker", newJString(Marker))
  add(query_21626730, "SnapshotType", newJString(SnapshotType))
  add(query_21626730, "Version", newJString(Version))
  result = call_21626729.call(nil, query_21626730, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_21626708(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_21626709, base: "/",
    makeUrl: url_GetDescribeDBClusterSnapshots_21626710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_21626774 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBClusters_21626776(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBClusters_21626775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626777 = query.getOrDefault("Action")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true,
                                   default = newJString("DescribeDBClusters"))
  if valid_21626777 != nil:
    section.add "Action", valid_21626777
  var valid_21626778 = query.getOrDefault("Version")
  valid_21626778 = validateParameter(valid_21626778, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626778 != nil:
    section.add "Version", valid_21626778
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626779 = header.getOrDefault("X-Amz-Date")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Date", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Security-Token", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Algorithm", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Signature")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Signature", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Credential")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Credential", valid_21626785
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_21626786 = formData.getOrDefault("Marker")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "Marker", valid_21626786
  var valid_21626787 = formData.getOrDefault("Filters")
  valid_21626787 = validateParameter(valid_21626787, JArray, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "Filters", valid_21626787
  var valid_21626788 = formData.getOrDefault("MaxRecords")
  valid_21626788 = validateParameter(valid_21626788, JInt, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "MaxRecords", valid_21626788
  var valid_21626789 = formData.getOrDefault("DBClusterIdentifier")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "DBClusterIdentifier", valid_21626789
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626790: Call_PostDescribeDBClusters_21626774;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ## 
  let valid = call_21626790.validator(path, query, header, formData, body, _)
  let scheme = call_21626790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626790.makeUrl(scheme.get, call_21626790.host, call_21626790.base,
                               call_21626790.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626790, uri, valid, _)

proc call*(call_21626791: Call_PostDescribeDBClusters_21626774;
          Marker: string = ""; Action: string = "DescribeDBClusters";
          Filters: JsonNode = nil; MaxRecords: int = 0;
          DBClusterIdentifier: string = ""; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusters
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more clusters to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list only includes information about the clusters identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBClusterIdentifier: string
  ##                      : <p>The user-provided cluster identifier. If this parameter is specified, information from only the specific cluster is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_21626792 = newJObject()
  var formData_21626793 = newJObject()
  add(formData_21626793, "Marker", newJString(Marker))
  add(query_21626792, "Action", newJString(Action))
  if Filters != nil:
    formData_21626793.add "Filters", Filters
  add(formData_21626793, "MaxRecords", newJInt(MaxRecords))
  add(formData_21626793, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21626792, "Version", newJString(Version))
  result = call_21626791.call(nil, query_21626792, nil, formData_21626793, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_21626774(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_21626775, base: "/",
    makeUrl: url_PostDescribeDBClusters_21626776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_21626755 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBClusters_21626757(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBClusters_21626756(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626758 = query.getOrDefault("MaxRecords")
  valid_21626758 = validateParameter(valid_21626758, JInt, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "MaxRecords", valid_21626758
  var valid_21626759 = query.getOrDefault("DBClusterIdentifier")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "DBClusterIdentifier", valid_21626759
  var valid_21626760 = query.getOrDefault("Filters")
  valid_21626760 = validateParameter(valid_21626760, JArray, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "Filters", valid_21626760
  var valid_21626761 = query.getOrDefault("Action")
  valid_21626761 = validateParameter(valid_21626761, JString, required = true,
                                   default = newJString("DescribeDBClusters"))
  if valid_21626761 != nil:
    section.add "Action", valid_21626761
  var valid_21626762 = query.getOrDefault("Marker")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "Marker", valid_21626762
  var valid_21626763 = query.getOrDefault("Version")
  valid_21626763 = validateParameter(valid_21626763, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626763 != nil:
    section.add "Version", valid_21626763
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626764 = header.getOrDefault("X-Amz-Date")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Date", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Security-Token", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Algorithm", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Signature")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Signature", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Credential")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Credential", valid_21626770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626771: Call_GetDescribeDBClusters_21626755;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about provisioned Amazon DocumentDB clusters. This API operation supports pagination. For certain management features such as cluster and instance lifecycle management, Amazon DocumentDB leverages operational technology that is shared with Amazon RDS and Amazon Neptune. Use the <code>filterName=engine,Values=docdb</code> filter parameter to return only Amazon DocumentDB clusters.
  ## 
  let valid = call_21626771.validator(path, query, header, formData, body, _)
  let scheme = call_21626771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626771.makeUrl(scheme.get, call_21626771.host, call_21626771.base,
                               call_21626771.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626771, uri, valid, _)

proc call*(call_21626772: Call_GetDescribeDBClusters_21626755; MaxRecords: int = 0;
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
  var query_21626773 = newJObject()
  add(query_21626773, "MaxRecords", newJInt(MaxRecords))
  add(query_21626773, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Filters != nil:
    query_21626773.add "Filters", Filters
  add(query_21626773, "Action", newJString(Action))
  add(query_21626773, "Marker", newJString(Marker))
  add(query_21626773, "Version", newJString(Version))
  result = call_21626772.call(nil, query_21626773, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_21626755(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_21626756, base: "/",
    makeUrl: url_GetDescribeDBClusters_21626757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_21626818 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBEngineVersions_21626820(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_21626819(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626821 = query.getOrDefault("Action")
  valid_21626821 = validateParameter(valid_21626821, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_21626821 != nil:
    section.add "Action", valid_21626821
  var valid_21626822 = query.getOrDefault("Version")
  valid_21626822 = validateParameter(valid_21626822, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626822 != nil:
    section.add "Version", valid_21626822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626823 = header.getOrDefault("X-Amz-Date")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Date", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-Security-Token", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626825
  var valid_21626826 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "X-Amz-Algorithm", valid_21626826
  var valid_21626827 = header.getOrDefault("X-Amz-Signature")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Signature", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Credential")
  valid_21626829 = validateParameter(valid_21626829, JString, required = false,
                                   default = nil)
  if valid_21626829 != nil:
    section.add "X-Amz-Credential", valid_21626829
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListSupportedCharacterSets: JBool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Engine: JString
  ##         : The database engine to return.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBParameterGroupFamily: JString
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
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
  var valid_21626830 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_21626830 = validateParameter(valid_21626830, JBool, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "ListSupportedCharacterSets", valid_21626830
  var valid_21626831 = formData.getOrDefault("Engine")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "Engine", valid_21626831
  var valid_21626832 = formData.getOrDefault("Marker")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "Marker", valid_21626832
  var valid_21626833 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "DBParameterGroupFamily", valid_21626833
  var valid_21626834 = formData.getOrDefault("Filters")
  valid_21626834 = validateParameter(valid_21626834, JArray, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "Filters", valid_21626834
  var valid_21626835 = formData.getOrDefault("MaxRecords")
  valid_21626835 = validateParameter(valid_21626835, JInt, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "MaxRecords", valid_21626835
  var valid_21626836 = formData.getOrDefault("EngineVersion")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "EngineVersion", valid_21626836
  var valid_21626837 = formData.getOrDefault("ListSupportedTimezones")
  valid_21626837 = validateParameter(valid_21626837, JBool, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "ListSupportedTimezones", valid_21626837
  var valid_21626838 = formData.getOrDefault("DefaultOnly")
  valid_21626838 = validateParameter(valid_21626838, JBool, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "DefaultOnly", valid_21626838
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626839: Call_PostDescribeDBEngineVersions_21626818;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the available engines.
  ## 
  let valid = call_21626839.validator(path, query, header, formData, body, _)
  let scheme = call_21626839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626839.makeUrl(scheme.get, call_21626839.host, call_21626839.base,
                               call_21626839.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626839, uri, valid, _)

proc call*(call_21626840: Call_PostDescribeDBEngineVersions_21626818;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; EngineVersion: string = "";
          ListSupportedTimezones: bool = false; Version: string = "2014-10-31";
          DefaultOnly: bool = false): Recallable =
  ## postDescribeDBEngineVersions
  ## Returns a list of the available engines.
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   Engine: string
  ##         : The database engine to return.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
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
  var query_21626841 = newJObject()
  var formData_21626842 = newJObject()
  add(formData_21626842, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_21626842, "Engine", newJString(Engine))
  add(formData_21626842, "Marker", newJString(Marker))
  add(query_21626841, "Action", newJString(Action))
  add(formData_21626842, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_21626842.add "Filters", Filters
  add(formData_21626842, "MaxRecords", newJInt(MaxRecords))
  add(formData_21626842, "EngineVersion", newJString(EngineVersion))
  add(formData_21626842, "ListSupportedTimezones",
      newJBool(ListSupportedTimezones))
  add(query_21626841, "Version", newJString(Version))
  add(formData_21626842, "DefaultOnly", newJBool(DefaultOnly))
  result = call_21626840.call(nil, query_21626841, nil, formData_21626842, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_21626818(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_21626819, base: "/",
    makeUrl: url_PostDescribeDBEngineVersions_21626820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_21626794 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBEngineVersions_21626796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_21626795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the available engines.
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
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
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
  var valid_21626797 = query.getOrDefault("Engine")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "Engine", valid_21626797
  var valid_21626798 = query.getOrDefault("ListSupportedCharacterSets")
  valid_21626798 = validateParameter(valid_21626798, JBool, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "ListSupportedCharacterSets", valid_21626798
  var valid_21626799 = query.getOrDefault("MaxRecords")
  valid_21626799 = validateParameter(valid_21626799, JInt, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "MaxRecords", valid_21626799
  var valid_21626800 = query.getOrDefault("DBParameterGroupFamily")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "DBParameterGroupFamily", valid_21626800
  var valid_21626801 = query.getOrDefault("Filters")
  valid_21626801 = validateParameter(valid_21626801, JArray, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "Filters", valid_21626801
  var valid_21626802 = query.getOrDefault("ListSupportedTimezones")
  valid_21626802 = validateParameter(valid_21626802, JBool, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "ListSupportedTimezones", valid_21626802
  var valid_21626803 = query.getOrDefault("Action")
  valid_21626803 = validateParameter(valid_21626803, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_21626803 != nil:
    section.add "Action", valid_21626803
  var valid_21626804 = query.getOrDefault("Marker")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "Marker", valid_21626804
  var valid_21626805 = query.getOrDefault("EngineVersion")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "EngineVersion", valid_21626805
  var valid_21626806 = query.getOrDefault("DefaultOnly")
  valid_21626806 = validateParameter(valid_21626806, JBool, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "DefaultOnly", valid_21626806
  var valid_21626807 = query.getOrDefault("Version")
  valid_21626807 = validateParameter(valid_21626807, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626807 != nil:
    section.add "Version", valid_21626807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626808 = header.getOrDefault("X-Amz-Date")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-Date", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Security-Token", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-Algorithm", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Signature")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Signature", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Credential")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Credential", valid_21626814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626815: Call_GetDescribeDBEngineVersions_21626794;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the available engines.
  ## 
  let valid = call_21626815.validator(path, query, header, formData, body, _)
  let scheme = call_21626815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626815.makeUrl(scheme.get, call_21626815.host, call_21626815.base,
                               call_21626815.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626815, uri, valid, _)

proc call*(call_21626816: Call_GetDescribeDBEngineVersions_21626794;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Filters: JsonNode = nil; ListSupportedTimezones: bool = false;
          Action: string = "DescribeDBEngineVersions"; Marker: string = "";
          EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBEngineVersions
  ## Returns a list of the available engines.
  ##   Engine: string
  ##         : The database engine to return.
  ##   ListSupportedCharacterSets: bool
  ##                             : If this parameter is specified and the requested engine supports the <code>CharacterSetName</code> parameter for <code>CreateDBInstance</code>, the response includes a list of supported character sets for each engine version. 
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: string
  ##                         : <p>The name of a specific parameter group family to return details for.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match an existing <code>DBParameterGroupFamily</code>.</p> </li> </ul>
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
  var query_21626817 = newJObject()
  add(query_21626817, "Engine", newJString(Engine))
  add(query_21626817, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_21626817, "MaxRecords", newJInt(MaxRecords))
  add(query_21626817, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_21626817.add "Filters", Filters
  add(query_21626817, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_21626817, "Action", newJString(Action))
  add(query_21626817, "Marker", newJString(Marker))
  add(query_21626817, "EngineVersion", newJString(EngineVersion))
  add(query_21626817, "DefaultOnly", newJBool(DefaultOnly))
  add(query_21626817, "Version", newJString(Version))
  result = call_21626816.call(nil, query_21626817, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_21626794(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_21626795, base: "/",
    makeUrl: url_GetDescribeDBEngineVersions_21626796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_21626862 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBInstances_21626864(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_21626863(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626865 = query.getOrDefault("Action")
  valid_21626865 = validateParameter(valid_21626865, JString, required = true,
                                   default = newJString("DescribeDBInstances"))
  if valid_21626865 != nil:
    section.add "Action", valid_21626865
  var valid_21626866 = query.getOrDefault("Version")
  valid_21626866 = validateParameter(valid_21626866, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626866 != nil:
    section.add "Version", valid_21626866
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626867 = header.getOrDefault("X-Amz-Date")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Date", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Security-Token", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Algorithm", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Signature")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Signature", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Credential")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Credential", valid_21626873
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_21626874 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "DBInstanceIdentifier", valid_21626874
  var valid_21626875 = formData.getOrDefault("Marker")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "Marker", valid_21626875
  var valid_21626876 = formData.getOrDefault("Filters")
  valid_21626876 = validateParameter(valid_21626876, JArray, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "Filters", valid_21626876
  var valid_21626877 = formData.getOrDefault("MaxRecords")
  valid_21626877 = validateParameter(valid_21626877, JInt, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "MaxRecords", valid_21626877
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626878: Call_PostDescribeDBInstances_21626862;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_21626878.validator(path, query, header, formData, body, _)
  let scheme = call_21626878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626878.makeUrl(scheme.get, call_21626878.host, call_21626878.base,
                               call_21626878.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626878, uri, valid, _)

proc call*(call_21626879: Call_PostDescribeDBInstances_21626862;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBInstances
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ##   DBInstanceIdentifier: string
  ##                       : <p>The user-provided instance identifier. If this parameter is specified, information from only the specific instance is returned. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>If provided, must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more instances to describe.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only the information about the instances that are associated with the clusters that are identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only the information about the instances that are identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_21626880 = newJObject()
  var formData_21626881 = newJObject()
  add(formData_21626881, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626881, "Marker", newJString(Marker))
  add(query_21626880, "Action", newJString(Action))
  if Filters != nil:
    formData_21626881.add "Filters", Filters
  add(formData_21626881, "MaxRecords", newJInt(MaxRecords))
  add(query_21626880, "Version", newJString(Version))
  result = call_21626879.call(nil, query_21626880, nil, formData_21626881, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_21626862(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_21626863, base: "/",
    makeUrl: url_PostDescribeDBInstances_21626864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_21626843 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBInstances_21626845(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_21626844(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626846 = query.getOrDefault("MaxRecords")
  valid_21626846 = validateParameter(valid_21626846, JInt, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "MaxRecords", valid_21626846
  var valid_21626847 = query.getOrDefault("Filters")
  valid_21626847 = validateParameter(valid_21626847, JArray, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "Filters", valid_21626847
  var valid_21626848 = query.getOrDefault("Action")
  valid_21626848 = validateParameter(valid_21626848, JString, required = true,
                                   default = newJString("DescribeDBInstances"))
  if valid_21626848 != nil:
    section.add "Action", valid_21626848
  var valid_21626849 = query.getOrDefault("Marker")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "Marker", valid_21626849
  var valid_21626850 = query.getOrDefault("Version")
  valid_21626850 = validateParameter(valid_21626850, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626850 != nil:
    section.add "Version", valid_21626850
  var valid_21626851 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "DBInstanceIdentifier", valid_21626851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626852 = header.getOrDefault("X-Amz-Date")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "X-Amz-Date", valid_21626852
  var valid_21626853 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "X-Amz-Security-Token", valid_21626853
  var valid_21626854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626854 = validateParameter(valid_21626854, JString, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626854
  var valid_21626855 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Algorithm", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Signature")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Signature", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Credential")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Credential", valid_21626858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626859: Call_GetDescribeDBInstances_21626843;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_21626859.validator(path, query, header, formData, body, _)
  let scheme = call_21626859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626859.makeUrl(scheme.get, call_21626859.host, call_21626859.base,
                               call_21626859.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626859, uri, valid, _)

proc call*(call_21626860: Call_GetDescribeDBInstances_21626843;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2014-10-31"; DBInstanceIdentifier: string = ""): Recallable =
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
  var query_21626861 = newJObject()
  add(query_21626861, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21626861.add "Filters", Filters
  add(query_21626861, "Action", newJString(Action))
  add(query_21626861, "Marker", newJString(Marker))
  add(query_21626861, "Version", newJString(Version))
  add(query_21626861, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626860.call(nil, query_21626861, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_21626843(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_21626844, base: "/",
    makeUrl: url_GetDescribeDBInstances_21626845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_21626901 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSubnetGroups_21626903(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_21626902(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626904 = query.getOrDefault("Action")
  valid_21626904 = validateParameter(valid_21626904, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_21626904 != nil:
    section.add "Action", valid_21626904
  var valid_21626905 = query.getOrDefault("Version")
  valid_21626905 = validateParameter(valid_21626905, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626905 != nil:
    section.add "Version", valid_21626905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626906 = header.getOrDefault("X-Amz-Date")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-Date", valid_21626906
  var valid_21626907 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626907 = validateParameter(valid_21626907, JString, required = false,
                                   default = nil)
  if valid_21626907 != nil:
    section.add "X-Amz-Security-Token", valid_21626907
  var valid_21626908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626908 = validateParameter(valid_21626908, JString, required = false,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626908
  var valid_21626909 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Algorithm", valid_21626909
  var valid_21626910 = header.getOrDefault("X-Amz-Signature")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Signature", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Credential")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Credential", valid_21626912
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##                    : The name of the subnet group to return details for.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_21626913 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "DBSubnetGroupName", valid_21626913
  var valid_21626914 = formData.getOrDefault("Marker")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "Marker", valid_21626914
  var valid_21626915 = formData.getOrDefault("Filters")
  valid_21626915 = validateParameter(valid_21626915, JArray, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "Filters", valid_21626915
  var valid_21626916 = formData.getOrDefault("MaxRecords")
  valid_21626916 = validateParameter(valid_21626916, JInt, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "MaxRecords", valid_21626916
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626917: Call_PostDescribeDBSubnetGroups_21626901;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_21626917.validator(path, query, header, formData, body, _)
  let scheme = call_21626917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626917.makeUrl(scheme.get, call_21626917.host, call_21626917.base,
                               call_21626917.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626917, uri, valid, _)

proc call*(call_21626918: Call_PostDescribeDBSubnetGroups_21626901;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBSubnetGroups
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ##   DBSubnetGroupName: string
  ##                    : The name of the subnet group to return details for.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_21626919 = newJObject()
  var formData_21626920 = newJObject()
  add(formData_21626920, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21626920, "Marker", newJString(Marker))
  add(query_21626919, "Action", newJString(Action))
  if Filters != nil:
    formData_21626920.add "Filters", Filters
  add(formData_21626920, "MaxRecords", newJInt(MaxRecords))
  add(query_21626919, "Version", newJString(Version))
  result = call_21626918.call(nil, query_21626919, nil, formData_21626920, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_21626901(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_21626902, base: "/",
    makeUrl: url_PostDescribeDBSubnetGroups_21626903,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_21626882 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSubnetGroups_21626884(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_21626883(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626885 = query.getOrDefault("MaxRecords")
  valid_21626885 = validateParameter(valid_21626885, JInt, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "MaxRecords", valid_21626885
  var valid_21626886 = query.getOrDefault("Filters")
  valid_21626886 = validateParameter(valid_21626886, JArray, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "Filters", valid_21626886
  var valid_21626887 = query.getOrDefault("Action")
  valid_21626887 = validateParameter(valid_21626887, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_21626887 != nil:
    section.add "Action", valid_21626887
  var valid_21626888 = query.getOrDefault("Marker")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "Marker", valid_21626888
  var valid_21626889 = query.getOrDefault("DBSubnetGroupName")
  valid_21626889 = validateParameter(valid_21626889, JString, required = false,
                                   default = nil)
  if valid_21626889 != nil:
    section.add "DBSubnetGroupName", valid_21626889
  var valid_21626890 = query.getOrDefault("Version")
  valid_21626890 = validateParameter(valid_21626890, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626890 != nil:
    section.add "Version", valid_21626890
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626891 = header.getOrDefault("X-Amz-Date")
  valid_21626891 = validateParameter(valid_21626891, JString, required = false,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "X-Amz-Date", valid_21626891
  var valid_21626892 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626892 = validateParameter(valid_21626892, JString, required = false,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "X-Amz-Security-Token", valid_21626892
  var valid_21626893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626893 = validateParameter(valid_21626893, JString, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626893
  var valid_21626894 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Algorithm", valid_21626894
  var valid_21626895 = header.getOrDefault("X-Amz-Signature")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Signature", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Credential")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Credential", valid_21626897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626898: Call_GetDescribeDBSubnetGroups_21626882;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_21626898.validator(path, query, header, formData, body, _)
  let scheme = call_21626898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626898.makeUrl(scheme.get, call_21626898.host, call_21626898.base,
                               call_21626898.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626898, uri, valid, _)

proc call*(call_21626899: Call_GetDescribeDBSubnetGroups_21626882;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2014-10-31"): Recallable =
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
  var query_21626900 = newJObject()
  add(query_21626900, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21626900.add "Filters", Filters
  add(query_21626900, "Action", newJString(Action))
  add(query_21626900, "Marker", newJString(Marker))
  add(query_21626900, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626900, "Version", newJString(Version))
  result = call_21626899.call(nil, query_21626900, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_21626882(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_21626883, base: "/",
    makeUrl: url_GetDescribeDBSubnetGroups_21626884,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_21626940 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEngineDefaultClusterParameters_21626942(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultClusterParameters_21626941(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626943 = query.getOrDefault("Action")
  valid_21626943 = validateParameter(valid_21626943, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_21626943 != nil:
    section.add "Action", valid_21626943
  var valid_21626944 = query.getOrDefault("Version")
  valid_21626944 = validateParameter(valid_21626944, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626944 != nil:
    section.add "Version", valid_21626944
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626945 = header.getOrDefault("X-Amz-Date")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Date", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Security-Token", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Algorithm", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Signature")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Signature", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Credential")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Credential", valid_21626951
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   DBParameterGroupFamily: JString (required)
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_21626952 = formData.getOrDefault("Marker")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "Marker", valid_21626952
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_21626953 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21626953 = validateParameter(valid_21626953, JString, required = true,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "DBParameterGroupFamily", valid_21626953
  var valid_21626954 = formData.getOrDefault("Filters")
  valid_21626954 = validateParameter(valid_21626954, JArray, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "Filters", valid_21626954
  var valid_21626955 = formData.getOrDefault("MaxRecords")
  valid_21626955 = validateParameter(valid_21626955, JInt, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "MaxRecords", valid_21626955
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626956: Call_PostDescribeEngineDefaultClusterParameters_21626940;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_21626956.validator(path, query, header, formData, body, _)
  let scheme = call_21626956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626956.makeUrl(scheme.get, call_21626956.host, call_21626956.base,
                               call_21626956.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626956, uri, valid, _)

proc call*(call_21626957: Call_PostDescribeEngineDefaultClusterParameters_21626940;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultClusterParameters";
          Filters: JsonNode = nil; MaxRecords: int = 0; Version: string = "2014-10-31"): Recallable =
  ## postDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_21626958 = newJObject()
  var formData_21626959 = newJObject()
  add(formData_21626959, "Marker", newJString(Marker))
  add(query_21626958, "Action", newJString(Action))
  add(formData_21626959, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_21626959.add "Filters", Filters
  add(formData_21626959, "MaxRecords", newJInt(MaxRecords))
  add(query_21626958, "Version", newJString(Version))
  result = call_21626957.call(nil, query_21626958, nil, formData_21626959, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_21626940(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_21626941,
    base: "/", makeUrl: url_PostDescribeEngineDefaultClusterParameters_21626942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_21626921 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEngineDefaultClusterParameters_21626923(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultClusterParameters_21626922(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626924 = query.getOrDefault("MaxRecords")
  valid_21626924 = validateParameter(valid_21626924, JInt, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "MaxRecords", valid_21626924
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_21626925 = query.getOrDefault("DBParameterGroupFamily")
  valid_21626925 = validateParameter(valid_21626925, JString, required = true,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "DBParameterGroupFamily", valid_21626925
  var valid_21626926 = query.getOrDefault("Filters")
  valid_21626926 = validateParameter(valid_21626926, JArray, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "Filters", valid_21626926
  var valid_21626927 = query.getOrDefault("Action")
  valid_21626927 = validateParameter(valid_21626927, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_21626927 != nil:
    section.add "Action", valid_21626927
  var valid_21626928 = query.getOrDefault("Marker")
  valid_21626928 = validateParameter(valid_21626928, JString, required = false,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "Marker", valid_21626928
  var valid_21626929 = query.getOrDefault("Version")
  valid_21626929 = validateParameter(valid_21626929, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626929 != nil:
    section.add "Version", valid_21626929
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626930 = header.getOrDefault("X-Amz-Date")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "X-Amz-Date", valid_21626930
  var valid_21626931 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Security-Token", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Algorithm", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Signature")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Signature", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-Credential")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-Credential", valid_21626936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626937: Call_GetDescribeEngineDefaultClusterParameters_21626921;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_21626937.validator(path, query, header, formData, body, _)
  let scheme = call_21626937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626937.makeUrl(scheme.get, call_21626937.host, call_21626937.base,
                               call_21626937.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626937, uri, valid, _)

proc call*(call_21626938: Call_GetDescribeEngineDefaultClusterParameters_21626921;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Filters: JsonNode = nil;
          Action: string = "DescribeEngineDefaultClusterParameters";
          Marker: string = ""; Version: string = "2014-10-31"): Recallable =
  ## getDescribeEngineDefaultClusterParameters
  ## Returns the default engine and system parameter information for the cluster database engine.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   DBParameterGroupFamily: string (required)
  ##                         : The name of the cluster parameter group family to return the engine parameter information for.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Version: string (required)
  var query_21626939 = newJObject()
  add(query_21626939, "MaxRecords", newJInt(MaxRecords))
  add(query_21626939, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_21626939.add "Filters", Filters
  add(query_21626939, "Action", newJString(Action))
  add(query_21626939, "Marker", newJString(Marker))
  add(query_21626939, "Version", newJString(Version))
  result = call_21626938.call(nil, query_21626939, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_21626921(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_21626922,
    base: "/", makeUrl: url_GetDescribeEngineDefaultClusterParameters_21626923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_21626977 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEventCategories_21626979(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_21626978(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626980 = query.getOrDefault("Action")
  valid_21626980 = validateParameter(valid_21626980, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_21626980 != nil:
    section.add "Action", valid_21626980
  var valid_21626981 = query.getOrDefault("Version")
  valid_21626981 = validateParameter(valid_21626981, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626981 != nil:
    section.add "Version", valid_21626981
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626982 = header.getOrDefault("X-Amz-Date")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Date", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-Security-Token", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Algorithm", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-Signature")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-Signature", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-Credential")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Credential", valid_21626988
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  section = newJObject()
  var valid_21626989 = formData.getOrDefault("Filters")
  valid_21626989 = validateParameter(valid_21626989, JArray, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "Filters", valid_21626989
  var valid_21626990 = formData.getOrDefault("SourceType")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "SourceType", valid_21626990
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626991: Call_PostDescribeEventCategories_21626977;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_21626991.validator(path, query, header, formData, body, _)
  let scheme = call_21626991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626991.makeUrl(scheme.get, call_21626991.host, call_21626991.base,
                               call_21626991.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626991, uri, valid, _)

proc call*(call_21626992: Call_PostDescribeEventCategories_21626977;
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
  var query_21626993 = newJObject()
  var formData_21626994 = newJObject()
  add(query_21626993, "Action", newJString(Action))
  if Filters != nil:
    formData_21626994.add "Filters", Filters
  add(query_21626993, "Version", newJString(Version))
  add(formData_21626994, "SourceType", newJString(SourceType))
  result = call_21626992.call(nil, query_21626993, nil, formData_21626994, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_21626977(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_21626978, base: "/",
    makeUrl: url_PostDescribeEventCategories_21626979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_21626960 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEventCategories_21626962(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_21626961(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626963 = query.getOrDefault("SourceType")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "SourceType", valid_21626963
  var valid_21626964 = query.getOrDefault("Filters")
  valid_21626964 = validateParameter(valid_21626964, JArray, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "Filters", valid_21626964
  var valid_21626965 = query.getOrDefault("Action")
  valid_21626965 = validateParameter(valid_21626965, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_21626965 != nil:
    section.add "Action", valid_21626965
  var valid_21626966 = query.getOrDefault("Version")
  valid_21626966 = validateParameter(valid_21626966, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21626966 != nil:
    section.add "Version", valid_21626966
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626967 = header.getOrDefault("X-Amz-Date")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Date", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-Security-Token", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Algorithm", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-Signature")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-Signature", valid_21626971
  var valid_21626972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626972
  var valid_21626973 = header.getOrDefault("X-Amz-Credential")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "X-Amz-Credential", valid_21626973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626974: Call_GetDescribeEventCategories_21626960;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_21626974.validator(path, query, header, formData, body, _)
  let scheme = call_21626974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626974.makeUrl(scheme.get, call_21626974.host, call_21626974.base,
                               call_21626974.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626974, uri, valid, _)

proc call*(call_21626975: Call_GetDescribeEventCategories_21626960;
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
  var query_21626976 = newJObject()
  add(query_21626976, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_21626976.add "Filters", Filters
  add(query_21626976, "Action", newJString(Action))
  add(query_21626976, "Version", newJString(Version))
  result = call_21626975.call(nil, query_21626976, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_21626960(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_21626961, base: "/",
    makeUrl: url_GetDescribeEventCategories_21626962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_21627019 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEvents_21627021(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_21627020(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627022 = query.getOrDefault("Action")
  valid_21627022 = validateParameter(valid_21627022, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627022 != nil:
    section.add "Action", valid_21627022
  var valid_21627023 = query.getOrDefault("Version")
  valid_21627023 = validateParameter(valid_21627023, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627023 != nil:
    section.add "Version", valid_21627023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627024 = header.getOrDefault("X-Amz-Date")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-Date", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-Security-Token", valid_21627025
  var valid_21627026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Algorithm", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-Signature")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-Signature", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627029
  var valid_21627030 = header.getOrDefault("X-Amz-Credential")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Credential", valid_21627030
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
  var valid_21627031 = formData.getOrDefault("SourceIdentifier")
  valid_21627031 = validateParameter(valid_21627031, JString, required = false,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "SourceIdentifier", valid_21627031
  var valid_21627032 = formData.getOrDefault("EventCategories")
  valid_21627032 = validateParameter(valid_21627032, JArray, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "EventCategories", valid_21627032
  var valid_21627033 = formData.getOrDefault("Marker")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "Marker", valid_21627033
  var valid_21627034 = formData.getOrDefault("StartTime")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "StartTime", valid_21627034
  var valid_21627035 = formData.getOrDefault("Duration")
  valid_21627035 = validateParameter(valid_21627035, JInt, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "Duration", valid_21627035
  var valid_21627036 = formData.getOrDefault("Filters")
  valid_21627036 = validateParameter(valid_21627036, JArray, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "Filters", valid_21627036
  var valid_21627037 = formData.getOrDefault("EndTime")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "EndTime", valid_21627037
  var valid_21627038 = formData.getOrDefault("MaxRecords")
  valid_21627038 = validateParameter(valid_21627038, JInt, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "MaxRecords", valid_21627038
  var valid_21627039 = formData.getOrDefault("SourceType")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = newJString("db-instance"))
  if valid_21627039 != nil:
    section.add "SourceType", valid_21627039
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627040: Call_PostDescribeEvents_21627019; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_21627040.validator(path, query, header, formData, body, _)
  let scheme = call_21627040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627040.makeUrl(scheme.get, call_21627040.host, call_21627040.base,
                               call_21627040.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627040, uri, valid, _)

proc call*(call_21627041: Call_PostDescribeEvents_21627019;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; Filters: JsonNode = nil;
          EndTime: string = ""; MaxRecords: int = 0; Version: string = "2014-10-31";
          SourceType: string = "db-instance"): Recallable =
  ## postDescribeEvents
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
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
  var query_21627042 = newJObject()
  var formData_21627043 = newJObject()
  add(formData_21627043, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_21627043.add "EventCategories", EventCategories
  add(formData_21627043, "Marker", newJString(Marker))
  add(formData_21627043, "StartTime", newJString(StartTime))
  add(query_21627042, "Action", newJString(Action))
  add(formData_21627043, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_21627043.add "Filters", Filters
  add(formData_21627043, "EndTime", newJString(EndTime))
  add(formData_21627043, "MaxRecords", newJInt(MaxRecords))
  add(query_21627042, "Version", newJString(Version))
  add(formData_21627043, "SourceType", newJString(SourceType))
  result = call_21627041.call(nil, query_21627042, nil, formData_21627043, nil)

var postDescribeEvents* = Call_PostDescribeEvents_21627019(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_21627020, base: "/",
    makeUrl: url_PostDescribeEvents_21627021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_21626995 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEvents_21626997(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_21626996(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626998 = query.getOrDefault("SourceType")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = newJString("db-instance"))
  if valid_21626998 != nil:
    section.add "SourceType", valid_21626998
  var valid_21626999 = query.getOrDefault("MaxRecords")
  valid_21626999 = validateParameter(valid_21626999, JInt, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "MaxRecords", valid_21626999
  var valid_21627000 = query.getOrDefault("StartTime")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "StartTime", valid_21627000
  var valid_21627001 = query.getOrDefault("Filters")
  valid_21627001 = validateParameter(valid_21627001, JArray, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "Filters", valid_21627001
  var valid_21627002 = query.getOrDefault("Action")
  valid_21627002 = validateParameter(valid_21627002, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627002 != nil:
    section.add "Action", valid_21627002
  var valid_21627003 = query.getOrDefault("SourceIdentifier")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "SourceIdentifier", valid_21627003
  var valid_21627004 = query.getOrDefault("Marker")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "Marker", valid_21627004
  var valid_21627005 = query.getOrDefault("EventCategories")
  valid_21627005 = validateParameter(valid_21627005, JArray, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "EventCategories", valid_21627005
  var valid_21627006 = query.getOrDefault("Duration")
  valid_21627006 = validateParameter(valid_21627006, JInt, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "Duration", valid_21627006
  var valid_21627007 = query.getOrDefault("EndTime")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "EndTime", valid_21627007
  var valid_21627008 = query.getOrDefault("Version")
  valid_21627008 = validateParameter(valid_21627008, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627008 != nil:
    section.add "Version", valid_21627008
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627009 = header.getOrDefault("X-Amz-Date")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-Date", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Security-Token", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-Algorithm", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-Signature")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-Signature", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627014
  var valid_21627015 = header.getOrDefault("X-Amz-Credential")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Credential", valid_21627015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627016: Call_GetDescribeEvents_21626995; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns events related to instances, security groups, snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, security group, snapshot, or parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_21627016.validator(path, query, header, formData, body, _)
  let scheme = call_21627016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627016.makeUrl(scheme.get, call_21627016.host, call_21627016.base,
                               call_21627016.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627016, uri, valid, _)

proc call*(call_21627017: Call_GetDescribeEvents_21626995;
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
  var query_21627018 = newJObject()
  add(query_21627018, "SourceType", newJString(SourceType))
  add(query_21627018, "MaxRecords", newJInt(MaxRecords))
  add(query_21627018, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_21627018.add "Filters", Filters
  add(query_21627018, "Action", newJString(Action))
  add(query_21627018, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_21627018, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_21627018.add "EventCategories", EventCategories
  add(query_21627018, "Duration", newJInt(Duration))
  add(query_21627018, "EndTime", newJString(EndTime))
  add(query_21627018, "Version", newJString(Version))
  result = call_21627017.call(nil, query_21627018, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_21626995(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_21626996,
    base: "/", makeUrl: url_GetDescribeEvents_21626997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_21627067 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOrderableDBInstanceOptions_21627069(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_21627068(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627070 = query.getOrDefault("Action")
  valid_21627070 = validateParameter(valid_21627070, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_21627070 != nil:
    section.add "Action", valid_21627070
  var valid_21627071 = query.getOrDefault("Version")
  valid_21627071 = validateParameter(valid_21627071, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627071 != nil:
    section.add "Version", valid_21627071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627072 = header.getOrDefault("X-Amz-Date")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Date", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-Security-Token", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627074
  var valid_21627075 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "X-Amz-Algorithm", valid_21627075
  var valid_21627076 = header.getOrDefault("X-Amz-Signature")
  valid_21627076 = validateParameter(valid_21627076, JString, required = false,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "X-Amz-Signature", valid_21627076
  var valid_21627077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627077 = validateParameter(valid_21627077, JString, required = false,
                                   default = nil)
  if valid_21627077 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627077
  var valid_21627078 = header.getOrDefault("X-Amz-Credential")
  valid_21627078 = validateParameter(valid_21627078, JString, required = false,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "X-Amz-Credential", valid_21627078
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: JString
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
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
  var valid_21627079 = formData.getOrDefault("Engine")
  valid_21627079 = validateParameter(valid_21627079, JString, required = true,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "Engine", valid_21627079
  var valid_21627080 = formData.getOrDefault("Marker")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "Marker", valid_21627080
  var valid_21627081 = formData.getOrDefault("Vpc")
  valid_21627081 = validateParameter(valid_21627081, JBool, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "Vpc", valid_21627081
  var valid_21627082 = formData.getOrDefault("DBInstanceClass")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "DBInstanceClass", valid_21627082
  var valid_21627083 = formData.getOrDefault("Filters")
  valid_21627083 = validateParameter(valid_21627083, JArray, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "Filters", valid_21627083
  var valid_21627084 = formData.getOrDefault("LicenseModel")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "LicenseModel", valid_21627084
  var valid_21627085 = formData.getOrDefault("MaxRecords")
  valid_21627085 = validateParameter(valid_21627085, JInt, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "MaxRecords", valid_21627085
  var valid_21627086 = formData.getOrDefault("EngineVersion")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "EngineVersion", valid_21627086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627087: Call_PostDescribeOrderableDBInstanceOptions_21627067;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  let valid = call_21627087.validator(path, query, header, formData, body, _)
  let scheme = call_21627087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627087.makeUrl(scheme.get, call_21627087.host, call_21627087.base,
                               call_21627087.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627087, uri, valid, _)

proc call*(call_21627088: Call_PostDescribeOrderableDBInstanceOptions_21627067;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          LicenseModel: string = ""; MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable instance options for the specified engine.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: string
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: string (required)
  var query_21627089 = newJObject()
  var formData_21627090 = newJObject()
  add(formData_21627090, "Engine", newJString(Engine))
  add(formData_21627090, "Marker", newJString(Marker))
  add(query_21627089, "Action", newJString(Action))
  add(formData_21627090, "Vpc", newJBool(Vpc))
  add(formData_21627090, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_21627090.add "Filters", Filters
  add(formData_21627090, "LicenseModel", newJString(LicenseModel))
  add(formData_21627090, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627090, "EngineVersion", newJString(EngineVersion))
  add(query_21627089, "Version", newJString(Version))
  result = call_21627088.call(nil, query_21627089, nil, formData_21627090, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_21627067(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_21627068,
    base: "/", makeUrl: url_PostDescribeOrderableDBInstanceOptions_21627069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_21627044 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOrderableDBInstanceOptions_21627046(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_21627045(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: JString
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: JBool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: JString
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: JString
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_21627047 = query.getOrDefault("Engine")
  valid_21627047 = validateParameter(valid_21627047, JString, required = true,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "Engine", valid_21627047
  var valid_21627048 = query.getOrDefault("MaxRecords")
  valid_21627048 = validateParameter(valid_21627048, JInt, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "MaxRecords", valid_21627048
  var valid_21627049 = query.getOrDefault("Filters")
  valid_21627049 = validateParameter(valid_21627049, JArray, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "Filters", valid_21627049
  var valid_21627050 = query.getOrDefault("LicenseModel")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "LicenseModel", valid_21627050
  var valid_21627051 = query.getOrDefault("Vpc")
  valid_21627051 = validateParameter(valid_21627051, JBool, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "Vpc", valid_21627051
  var valid_21627052 = query.getOrDefault("DBInstanceClass")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "DBInstanceClass", valid_21627052
  var valid_21627053 = query.getOrDefault("Action")
  valid_21627053 = validateParameter(valid_21627053, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_21627053 != nil:
    section.add "Action", valid_21627053
  var valid_21627054 = query.getOrDefault("Marker")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "Marker", valid_21627054
  var valid_21627055 = query.getOrDefault("EngineVersion")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "EngineVersion", valid_21627055
  var valid_21627056 = query.getOrDefault("Version")
  valid_21627056 = validateParameter(valid_21627056, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627056 != nil:
    section.add "Version", valid_21627056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627057 = header.getOrDefault("X-Amz-Date")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Date", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-Security-Token", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627059
  var valid_21627060 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627060 = validateParameter(valid_21627060, JString, required = false,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "X-Amz-Algorithm", valid_21627060
  var valid_21627061 = header.getOrDefault("X-Amz-Signature")
  valid_21627061 = validateParameter(valid_21627061, JString, required = false,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "X-Amz-Signature", valid_21627061
  var valid_21627062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627062 = validateParameter(valid_21627062, JString, required = false,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627062
  var valid_21627063 = header.getOrDefault("X-Amz-Credential")
  valid_21627063 = validateParameter(valid_21627063, JString, required = false,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "X-Amz-Credential", valid_21627063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627064: Call_GetDescribeOrderableDBInstanceOptions_21627044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of orderable instance options for the specified engine.
  ## 
  let valid = call_21627064.validator(path, query, header, formData, body, _)
  let scheme = call_21627064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627064.makeUrl(scheme.get, call_21627064.host, call_21627064.base,
                               call_21627064.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627064, uri, valid, _)

proc call*(call_21627065: Call_GetDescribeOrderableDBInstanceOptions_21627044;
          Engine: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          LicenseModel: string = ""; Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ## Returns a list of orderable instance options for the specified engine.
  ##   Engine: string (required)
  ##         : The name of the engine to retrieve instance options for.
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   LicenseModel: string
  ##               : The license model filter value. Specify this parameter to show only the available offerings that match the specified license model.
  ##   Vpc: bool
  ##      : The virtual private cloud (VPC) filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  ##   DBInstanceClass: string
  ##                  : The instance class filter value. Specify this parameter to show only the available offerings that match the specified instance class.
  ##   Action: string (required)
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   EngineVersion: string
  ##                : The engine version filter value. Specify this parameter to show only the available offerings that match the specified engine version.
  ##   Version: string (required)
  var query_21627066 = newJObject()
  add(query_21627066, "Engine", newJString(Engine))
  add(query_21627066, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627066.add "Filters", Filters
  add(query_21627066, "LicenseModel", newJString(LicenseModel))
  add(query_21627066, "Vpc", newJBool(Vpc))
  add(query_21627066, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627066, "Action", newJString(Action))
  add(query_21627066, "Marker", newJString(Marker))
  add(query_21627066, "EngineVersion", newJString(EngineVersion))
  add(query_21627066, "Version", newJString(Version))
  result = call_21627065.call(nil, query_21627066, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_21627044(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_21627045, base: "/",
    makeUrl: url_GetDescribeOrderableDBInstanceOptions_21627046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_21627110 = ref object of OpenApiRestCall_21625418
proc url_PostDescribePendingMaintenanceActions_21627112(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribePendingMaintenanceActions_21627111(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627113 = query.getOrDefault("Action")
  valid_21627113 = validateParameter(valid_21627113, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_21627113 != nil:
    section.add "Action", valid_21627113
  var valid_21627114 = query.getOrDefault("Version")
  valid_21627114 = validateParameter(valid_21627114, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627114 != nil:
    section.add "Version", valid_21627114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627115 = header.getOrDefault("X-Amz-Date")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Date", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Security-Token", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-Algorithm", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Signature")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Signature", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627120
  var valid_21627121 = header.getOrDefault("X-Amz-Credential")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Credential", valid_21627121
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   ResourceIdentifier: JString
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: JInt
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  section = newJObject()
  var valid_21627122 = formData.getOrDefault("Marker")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "Marker", valid_21627122
  var valid_21627123 = formData.getOrDefault("ResourceIdentifier")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "ResourceIdentifier", valid_21627123
  var valid_21627124 = formData.getOrDefault("Filters")
  valid_21627124 = validateParameter(valid_21627124, JArray, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "Filters", valid_21627124
  var valid_21627125 = formData.getOrDefault("MaxRecords")
  valid_21627125 = validateParameter(valid_21627125, JInt, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "MaxRecords", valid_21627125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627126: Call_PostDescribePendingMaintenanceActions_21627110;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ## 
  let valid = call_21627126.validator(path, query, header, formData, body, _)
  let scheme = call_21627126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627126.makeUrl(scheme.get, call_21627126.host, call_21627126.base,
                               call_21627126.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627126, uri, valid, _)

proc call*(call_21627127: Call_PostDescribePendingMaintenanceActions_21627110;
          Marker: string = ""; Action: string = "DescribePendingMaintenanceActions";
          ResourceIdentifier: string = ""; Filters: JsonNode = nil; MaxRecords: int = 0;
          Version: string = "2014-10-31"): Recallable =
  ## postDescribePendingMaintenanceActions
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ##   Marker: string
  ##         : An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by <code>MaxRecords</code>.
  ##   Action: string (required)
  ##   ResourceIdentifier: string
  ##                     : The ARN of a resource to return pending maintenance actions for.
  ##   Filters: JArray
  ##          : <p>A filter that specifies one or more resources to return pending maintenance actions for.</p> <p>Supported filters:</p> <ul> <li> <p> <code>db-cluster-id</code> - Accepts cluster identifiers and cluster Amazon Resource Names (ARNs). The results list includes only pending maintenance actions for the clusters identified by these ARNs.</p> </li> <li> <p> <code>db-instance-id</code> - Accepts instance identifiers and instance ARNs. The results list includes only pending maintenance actions for the DB instances identified by these ARNs.</p> </li> </ul>
  ##   MaxRecords: int
  ##             : <p> The maximum number of records to include in the response. If more records exist than the specified <code>MaxRecords</code> value, a pagination token (marker) is included in the response so that the remaining results can be retrieved.</p> <p>Default: 100</p> <p>Constraints: Minimum 20, maximum 100.</p>
  ##   Version: string (required)
  var query_21627128 = newJObject()
  var formData_21627129 = newJObject()
  add(formData_21627129, "Marker", newJString(Marker))
  add(query_21627128, "Action", newJString(Action))
  add(formData_21627129, "ResourceIdentifier", newJString(ResourceIdentifier))
  if Filters != nil:
    formData_21627129.add "Filters", Filters
  add(formData_21627129, "MaxRecords", newJInt(MaxRecords))
  add(query_21627128, "Version", newJString(Version))
  result = call_21627127.call(nil, query_21627128, nil, formData_21627129, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_21627110(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_21627111, base: "/",
    makeUrl: url_PostDescribePendingMaintenanceActions_21627112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_21627091 = ref object of OpenApiRestCall_21625418
proc url_GetDescribePendingMaintenanceActions_21627093(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribePendingMaintenanceActions_21627092(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627094 = query.getOrDefault("MaxRecords")
  valid_21627094 = validateParameter(valid_21627094, JInt, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "MaxRecords", valid_21627094
  var valid_21627095 = query.getOrDefault("Filters")
  valid_21627095 = validateParameter(valid_21627095, JArray, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "Filters", valid_21627095
  var valid_21627096 = query.getOrDefault("ResourceIdentifier")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "ResourceIdentifier", valid_21627096
  var valid_21627097 = query.getOrDefault("Action")
  valid_21627097 = validateParameter(valid_21627097, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_21627097 != nil:
    section.add "Action", valid_21627097
  var valid_21627098 = query.getOrDefault("Marker")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "Marker", valid_21627098
  var valid_21627099 = query.getOrDefault("Version")
  valid_21627099 = validateParameter(valid_21627099, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627099 != nil:
    section.add "Version", valid_21627099
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627100 = header.getOrDefault("X-Amz-Date")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Date", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Security-Token", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-Algorithm", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-Signature")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Signature", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627105
  var valid_21627106 = header.getOrDefault("X-Amz-Credential")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "X-Amz-Credential", valid_21627106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627107: Call_GetDescribePendingMaintenanceActions_21627091;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of resources (for example, instances) that have at least one pending maintenance action.
  ## 
  let valid = call_21627107.validator(path, query, header, formData, body, _)
  let scheme = call_21627107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627107.makeUrl(scheme.get, call_21627107.host, call_21627107.base,
                               call_21627107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627107, uri, valid, _)

proc call*(call_21627108: Call_GetDescribePendingMaintenanceActions_21627091;
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
  var query_21627109 = newJObject()
  add(query_21627109, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627109.add "Filters", Filters
  add(query_21627109, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_21627109, "Action", newJString(Action))
  add(query_21627109, "Marker", newJString(Marker))
  add(query_21627109, "Version", newJString(Version))
  result = call_21627108.call(nil, query_21627109, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_21627091(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_21627092, base: "/",
    makeUrl: url_GetDescribePendingMaintenanceActions_21627093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_21627147 = ref object of OpenApiRestCall_21625418
proc url_PostFailoverDBCluster_21627149(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostFailoverDBCluster_21627148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627150 = query.getOrDefault("Action")
  valid_21627150 = validateParameter(valid_21627150, JString, required = true,
                                   default = newJString("FailoverDBCluster"))
  if valid_21627150 != nil:
    section.add "Action", valid_21627150
  var valid_21627151 = query.getOrDefault("Version")
  valid_21627151 = validateParameter(valid_21627151, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627151 != nil:
    section.add "Version", valid_21627151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627152 = header.getOrDefault("X-Amz-Date")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Date", valid_21627152
  var valid_21627153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Security-Token", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Algorithm", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-Signature")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-Signature", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627157
  var valid_21627158 = header.getOrDefault("X-Amz-Credential")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Credential", valid_21627158
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_21627159 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "TargetDBInstanceIdentifier", valid_21627159
  var valid_21627160 = formData.getOrDefault("DBClusterIdentifier")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "DBClusterIdentifier", valid_21627160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627161: Call_PostFailoverDBCluster_21627147;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_21627161.validator(path, query, header, formData, body, _)
  let scheme = call_21627161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627161.makeUrl(scheme.get, call_21627161.host, call_21627161.base,
                               call_21627161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627161, uri, valid, _)

proc call*(call_21627162: Call_PostFailoverDBCluster_21627147;
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
  var query_21627163 = newJObject()
  var formData_21627164 = newJObject()
  add(query_21627163, "Action", newJString(Action))
  add(formData_21627164, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_21627164, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21627163, "Version", newJString(Version))
  result = call_21627162.call(nil, query_21627163, nil, formData_21627164, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_21627147(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_21627148, base: "/",
    makeUrl: url_PostFailoverDBCluster_21627149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_21627130 = ref object of OpenApiRestCall_21625418
proc url_GetFailoverDBCluster_21627132(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFailoverDBCluster_21627131(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627133 = query.getOrDefault("DBClusterIdentifier")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "DBClusterIdentifier", valid_21627133
  var valid_21627134 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "TargetDBInstanceIdentifier", valid_21627134
  var valid_21627135 = query.getOrDefault("Action")
  valid_21627135 = validateParameter(valid_21627135, JString, required = true,
                                   default = newJString("FailoverDBCluster"))
  if valid_21627135 != nil:
    section.add "Action", valid_21627135
  var valid_21627136 = query.getOrDefault("Version")
  valid_21627136 = validateParameter(valid_21627136, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627136 != nil:
    section.add "Version", valid_21627136
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627137 = header.getOrDefault("X-Amz-Date")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "X-Amz-Date", valid_21627137
  var valid_21627138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Security-Token", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-Algorithm", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-Signature")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-Signature", valid_21627141
  var valid_21627142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627142
  var valid_21627143 = header.getOrDefault("X-Amz-Credential")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-Credential", valid_21627143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627144: Call_GetFailoverDBCluster_21627130; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Forces a failover for a cluster.</p> <p>A failover for a cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_21627144.validator(path, query, header, formData, body, _)
  let scheme = call_21627144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627144.makeUrl(scheme.get, call_21627144.host, call_21627144.base,
                               call_21627144.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627144, uri, valid, _)

proc call*(call_21627145: Call_GetFailoverDBCluster_21627130;
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
  var query_21627146 = newJObject()
  add(query_21627146, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21627146, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_21627146, "Action", newJString(Action))
  add(query_21627146, "Version", newJString(Version))
  result = call_21627145.call(nil, query_21627146, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_21627130(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_21627131, base: "/",
    makeUrl: url_GetFailoverDBCluster_21627132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_21627182 = ref object of OpenApiRestCall_21625418
proc url_PostListTagsForResource_21627184(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_21627183(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627185 = query.getOrDefault("Action")
  valid_21627185 = validateParameter(valid_21627185, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627185 != nil:
    section.add "Action", valid_21627185
  var valid_21627186 = query.getOrDefault("Version")
  valid_21627186 = validateParameter(valid_21627186, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627186 != nil:
    section.add "Version", valid_21627186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627187 = header.getOrDefault("X-Amz-Date")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Date", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Security-Token", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Algorithm", valid_21627190
  var valid_21627191 = header.getOrDefault("X-Amz-Signature")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-Signature", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-Credential")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "X-Amz-Credential", valid_21627193
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_21627194 = formData.getOrDefault("Filters")
  valid_21627194 = validateParameter(valid_21627194, JArray, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "Filters", valid_21627194
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_21627195 = formData.getOrDefault("ResourceName")
  valid_21627195 = validateParameter(valid_21627195, JString, required = true,
                                   default = nil)
  if valid_21627195 != nil:
    section.add "ResourceName", valid_21627195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627196: Call_PostListTagsForResource_21627182;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_21627196.validator(path, query, header, formData, body, _)
  let scheme = call_21627196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627196.makeUrl(scheme.get, call_21627196.host, call_21627196.base,
                               call_21627196.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627196, uri, valid, _)

proc call*(call_21627197: Call_PostListTagsForResource_21627182;
          ResourceName: string; Action: string = "ListTagsForResource";
          Filters: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## postListTagsForResource
  ## Lists all tags on an Amazon DocumentDB resource.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_21627198 = newJObject()
  var formData_21627199 = newJObject()
  add(query_21627198, "Action", newJString(Action))
  if Filters != nil:
    formData_21627199.add "Filters", Filters
  add(formData_21627199, "ResourceName", newJString(ResourceName))
  add(query_21627198, "Version", newJString(Version))
  result = call_21627197.call(nil, query_21627198, nil, formData_21627199, nil)

var postListTagsForResource* = Call_PostListTagsForResource_21627182(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_21627183, base: "/",
    makeUrl: url_PostListTagsForResource_21627184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_21627165 = ref object of OpenApiRestCall_21625418
proc url_GetListTagsForResource_21627167(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_21627166(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627168 = query.getOrDefault("Filters")
  valid_21627168 = validateParameter(valid_21627168, JArray, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "Filters", valid_21627168
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_21627169 = query.getOrDefault("ResourceName")
  valid_21627169 = validateParameter(valid_21627169, JString, required = true,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "ResourceName", valid_21627169
  var valid_21627170 = query.getOrDefault("Action")
  valid_21627170 = validateParameter(valid_21627170, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627170 != nil:
    section.add "Action", valid_21627170
  var valid_21627171 = query.getOrDefault("Version")
  valid_21627171 = validateParameter(valid_21627171, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627171 != nil:
    section.add "Version", valid_21627171
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627172 = header.getOrDefault("X-Amz-Date")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Date", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Security-Token", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-Algorithm", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-Signature")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Signature", valid_21627176
  var valid_21627177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627177 = validateParameter(valid_21627177, JString, required = false,
                                   default = nil)
  if valid_21627177 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627177
  var valid_21627178 = header.getOrDefault("X-Amz-Credential")
  valid_21627178 = validateParameter(valid_21627178, JString, required = false,
                                   default = nil)
  if valid_21627178 != nil:
    section.add "X-Amz-Credential", valid_21627178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627179: Call_GetListTagsForResource_21627165;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_21627179.validator(path, query, header, formData, body, _)
  let scheme = call_21627179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627179.makeUrl(scheme.get, call_21627179.host, call_21627179.base,
                               call_21627179.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627179, uri, valid, _)

proc call*(call_21627180: Call_GetListTagsForResource_21627165;
          ResourceName: string; Filters: JsonNode = nil;
          Action: string = "ListTagsForResource"; Version: string = "2014-10-31"): Recallable =
  ## getListTagsForResource
  ## Lists all tags on an Amazon DocumentDB resource.
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627181 = newJObject()
  if Filters != nil:
    query_21627181.add "Filters", Filters
  add(query_21627181, "ResourceName", newJString(ResourceName))
  add(query_21627181, "Action", newJString(Action))
  add(query_21627181, "Version", newJString(Version))
  result = call_21627180.call(nil, query_21627181, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_21627165(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_21627166, base: "/",
    makeUrl: url_GetListTagsForResource_21627167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_21627229 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBCluster_21627231(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBCluster_21627230(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627232 = query.getOrDefault("Action")
  valid_21627232 = validateParameter(valid_21627232, JString, required = true,
                                   default = newJString("ModifyDBCluster"))
  if valid_21627232 != nil:
    section.add "Action", valid_21627232
  var valid_21627233 = query.getOrDefault("Version")
  valid_21627233 = validateParameter(valid_21627233, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627233 != nil:
    section.add "Version", valid_21627233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627234 = header.getOrDefault("X-Amz-Date")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "X-Amz-Date", valid_21627234
  var valid_21627235 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627235 = validateParameter(valid_21627235, JString, required = false,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "X-Amz-Security-Token", valid_21627235
  var valid_21627236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627237 = validateParameter(valid_21627237, JString, required = false,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "X-Amz-Algorithm", valid_21627237
  var valid_21627238 = header.getOrDefault("X-Amz-Signature")
  valid_21627238 = validateParameter(valid_21627238, JString, required = false,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "X-Amz-Signature", valid_21627238
  var valid_21627239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627239 = validateParameter(valid_21627239, JString, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627239
  var valid_21627240 = header.getOrDefault("X-Amz-Credential")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "X-Amz-Credential", valid_21627240
  result.add "header", section
  ## parameters in `formData` object:
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   Port: JInt
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
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
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   DBClusterParameterGroupName: JString
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  section = newJObject()
  var valid_21627241 = formData.getOrDefault(
      "CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_21627241 = validateParameter(valid_21627241, JArray, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_21627241
  var valid_21627242 = formData.getOrDefault("ApplyImmediately")
  valid_21627242 = validateParameter(valid_21627242, JBool, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "ApplyImmediately", valid_21627242
  var valid_21627243 = formData.getOrDefault("Port")
  valid_21627243 = validateParameter(valid_21627243, JInt, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "Port", valid_21627243
  var valid_21627244 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21627244 = validateParameter(valid_21627244, JArray, required = false,
                                   default = nil)
  if valid_21627244 != nil:
    section.add "VpcSecurityGroupIds", valid_21627244
  var valid_21627245 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21627245 = validateParameter(valid_21627245, JInt, required = false,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "BackupRetentionPeriod", valid_21627245
  var valid_21627246 = formData.getOrDefault("MasterUserPassword")
  valid_21627246 = validateParameter(valid_21627246, JString, required = false,
                                   default = nil)
  if valid_21627246 != nil:
    section.add "MasterUserPassword", valid_21627246
  var valid_21627247 = formData.getOrDefault("DeletionProtection")
  valid_21627247 = validateParameter(valid_21627247, JBool, required = false,
                                   default = nil)
  if valid_21627247 != nil:
    section.add "DeletionProtection", valid_21627247
  var valid_21627248 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_21627248 = validateParameter(valid_21627248, JString, required = false,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "NewDBClusterIdentifier", valid_21627248
  var valid_21627249 = formData.getOrDefault(
      "CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_21627249 = validateParameter(valid_21627249, JArray, required = false,
                                   default = nil)
  if valid_21627249 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_21627249
  var valid_21627250 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_21627250 = validateParameter(valid_21627250, JString, required = false,
                                   default = nil)
  if valid_21627250 != nil:
    section.add "DBClusterParameterGroupName", valid_21627250
  var valid_21627251 = formData.getOrDefault("PreferredBackupWindow")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "PreferredBackupWindow", valid_21627251
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_21627252 = formData.getOrDefault("DBClusterIdentifier")
  valid_21627252 = validateParameter(valid_21627252, JString, required = true,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "DBClusterIdentifier", valid_21627252
  var valid_21627253 = formData.getOrDefault("EngineVersion")
  valid_21627253 = validateParameter(valid_21627253, JString, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "EngineVersion", valid_21627253
  var valid_21627254 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21627254 = validateParameter(valid_21627254, JString, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627254
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627255: Call_PostModifyDBCluster_21627229; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_21627255.validator(path, query, header, formData, body, _)
  let scheme = call_21627255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627255.makeUrl(scheme.get, call_21627255.host, call_21627255.base,
                               call_21627255.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627255, uri, valid, _)

proc call*(call_21627256: Call_PostModifyDBCluster_21627229;
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
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  ##   Port: int
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
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
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  var query_21627257 = newJObject()
  var formData_21627258 = newJObject()
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_21627258.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                         CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_21627258, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_21627258, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_21627258.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_21627258, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_21627258, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_21627258, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_21627258, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_21627258.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                         CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_21627257, "Action", newJString(Action))
  add(formData_21627258, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_21627258, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_21627258, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_21627258, "EngineVersion", newJString(EngineVersion))
  add(query_21627257, "Version", newJString(Version))
  add(formData_21627258, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_21627256.call(nil, query_21627257, nil, formData_21627258, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_21627229(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_21627230, base: "/",
    makeUrl: url_PostModifyDBCluster_21627231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_21627200 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBCluster_21627202(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBCluster_21627201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   MasterUserPassword: JString
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   CloudwatchLogsExportConfiguration.EnableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   CloudwatchLogsExportConfiguration.DisableLogTypes: JArray
  ##                                                    : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: JInt
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   NewDBClusterIdentifier: JString
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: JString (required)
  ##   EngineVersion: JString
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Port: JInt
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   PreferredBackupWindow: JString
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: JString (required)
  ##   ApplyImmediately: JBool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_21627203 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627203
  var valid_21627204 = query.getOrDefault("DBClusterParameterGroupName")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "DBClusterParameterGroupName", valid_21627204
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_21627205 = query.getOrDefault("DBClusterIdentifier")
  valid_21627205 = validateParameter(valid_21627205, JString, required = true,
                                   default = nil)
  if valid_21627205 != nil:
    section.add "DBClusterIdentifier", valid_21627205
  var valid_21627206 = query.getOrDefault("MasterUserPassword")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "MasterUserPassword", valid_21627206
  var valid_21627207 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_21627207 = validateParameter(valid_21627207, JArray, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_21627207
  var valid_21627208 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21627208 = validateParameter(valid_21627208, JArray, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "VpcSecurityGroupIds", valid_21627208
  var valid_21627209 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_21627209 = validateParameter(valid_21627209, JArray, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_21627209
  var valid_21627210 = query.getOrDefault("BackupRetentionPeriod")
  valid_21627210 = validateParameter(valid_21627210, JInt, required = false,
                                   default = nil)
  if valid_21627210 != nil:
    section.add "BackupRetentionPeriod", valid_21627210
  var valid_21627211 = query.getOrDefault("NewDBClusterIdentifier")
  valid_21627211 = validateParameter(valid_21627211, JString, required = false,
                                   default = nil)
  if valid_21627211 != nil:
    section.add "NewDBClusterIdentifier", valid_21627211
  var valid_21627212 = query.getOrDefault("DeletionProtection")
  valid_21627212 = validateParameter(valid_21627212, JBool, required = false,
                                   default = nil)
  if valid_21627212 != nil:
    section.add "DeletionProtection", valid_21627212
  var valid_21627213 = query.getOrDefault("Action")
  valid_21627213 = validateParameter(valid_21627213, JString, required = true,
                                   default = newJString("ModifyDBCluster"))
  if valid_21627213 != nil:
    section.add "Action", valid_21627213
  var valid_21627214 = query.getOrDefault("EngineVersion")
  valid_21627214 = validateParameter(valid_21627214, JString, required = false,
                                   default = nil)
  if valid_21627214 != nil:
    section.add "EngineVersion", valid_21627214
  var valid_21627215 = query.getOrDefault("Port")
  valid_21627215 = validateParameter(valid_21627215, JInt, required = false,
                                   default = nil)
  if valid_21627215 != nil:
    section.add "Port", valid_21627215
  var valid_21627216 = query.getOrDefault("PreferredBackupWindow")
  valid_21627216 = validateParameter(valid_21627216, JString, required = false,
                                   default = nil)
  if valid_21627216 != nil:
    section.add "PreferredBackupWindow", valid_21627216
  var valid_21627217 = query.getOrDefault("Version")
  valid_21627217 = validateParameter(valid_21627217, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627217 != nil:
    section.add "Version", valid_21627217
  var valid_21627218 = query.getOrDefault("ApplyImmediately")
  valid_21627218 = validateParameter(valid_21627218, JBool, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "ApplyImmediately", valid_21627218
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627219 = header.getOrDefault("X-Amz-Date")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Date", valid_21627219
  var valid_21627220 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627220 = validateParameter(valid_21627220, JString, required = false,
                                   default = nil)
  if valid_21627220 != nil:
    section.add "X-Amz-Security-Token", valid_21627220
  var valid_21627221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Algorithm", valid_21627222
  var valid_21627223 = header.getOrDefault("X-Amz-Signature")
  valid_21627223 = validateParameter(valid_21627223, JString, required = false,
                                   default = nil)
  if valid_21627223 != nil:
    section.add "X-Amz-Signature", valid_21627223
  var valid_21627224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627224 = validateParameter(valid_21627224, JString, required = false,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627224
  var valid_21627225 = header.getOrDefault("X-Amz-Credential")
  valid_21627225 = validateParameter(valid_21627225, JString, required = false,
                                   default = nil)
  if valid_21627225 != nil:
    section.add "X-Amz-Credential", valid_21627225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627226: Call_GetModifyDBCluster_21627200; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_21627226.validator(path, query, header, formData, body, _)
  let scheme = call_21627226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627226.makeUrl(scheme.get, call_21627226.host, call_21627226.base,
                               call_21627226.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627226, uri, valid, _)

proc call*(call_21627227: Call_GetModifyDBCluster_21627200;
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
  ## Modifies a setting for an Amazon DocumentDB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC).</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region, occurring on a random day of the week. </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Minimum 30-minute window.</p>
  ##   DBClusterParameterGroupName: string
  ##                              : The name of the cluster parameter group to use for the cluster.
  ##   DBClusterIdentifier: string (required)
  ##                      : <p>The cluster identifier for the cluster that is being modified. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   MasterUserPassword: string
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 100 characters.</p>
  ##   CloudwatchLogsExportConfigurationEnableLogTypes: JArray
  ##                                                  : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to enable.
  ##   VpcSecurityGroupIds: JArray
  ##                      : A list of virtual private cloud (VPC) security groups that the cluster will belong to.
  ##   CloudwatchLogsExportConfigurationDisableLogTypes: JArray
  ##                                                   : <p>The configuration setting for the log types to be enabled for export to Amazon CloudWatch Logs for a specific instance or cluster.</p> <p>The <code>EnableLogTypes</code> and <code>DisableLogTypes</code> arrays determine which logs are exported (or not exported) to CloudWatch Logs. The values within these arrays depend on the engine that is being used.</p>
  ## The list of log types to disable.
  ##   BackupRetentionPeriod: int
  ##                        : <p>The number of days for which automated backups are retained. You must specify a minimum value of 1.</p> <p>Default: 1</p> <p>Constraints:</p> <ul> <li> <p>Must be a value from 1 to 35.</p> </li> </ul>
  ##   NewDBClusterIdentifier: string
  ##                         : <p>The new cluster identifier for the cluster when renaming a cluster. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>my-cluster2</code> </p>
  ##   DeletionProtection: bool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   Action: string (required)
  ##   EngineVersion: string
  ##                : The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the <code>ApplyImmediately</code> parameter is set to <code>true</code>.
  ##   Port: int
  ##       : <p>The port number on which the cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The same port as the original cluster.</p>
  ##   PreferredBackupWindow: string
  ##                        : <p>The daily time range during which automated backups are created if automated backups are enabled, using the <code>BackupRetentionPeriod</code> parameter. </p> <p>The default is a 30-minute window selected at random from an 8-hour block of time for each AWS Region. </p> <p>Constraints:</p> <ul> <li> <p>Must be in the format <code>hh24:mi-hh24:mi</code>.</p> </li> <li> <p>Must be in Universal Coordinated Time (UTC).</p> </li> <li> <p>Must not conflict with the preferred maintenance window.</p> </li> <li> <p>Must be at least 30 minutes.</p> </li> </ul>
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##                   : <p>A value that specifies whether the changes in this request and any pending changes are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the cluster. If this parameter is set to <code>false</code>, changes to the cluster are applied during the next maintenance window.</p> <p>The <code>ApplyImmediately</code> parameter affects only the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values. If you set this parameter value to <code>false</code>, the changes to the <code>NewDBClusterIdentifier</code> and <code>MasterUserPassword</code> values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the <code>ApplyImmediately</code> parameter.</p> <p>Default: <code>false</code> </p>
  var query_21627228 = newJObject()
  add(query_21627228, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21627228, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_21627228, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21627228, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_21627228.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                      CloudwatchLogsExportConfigurationEnableLogTypes
  if VpcSecurityGroupIds != nil:
    query_21627228.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_21627228.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                      CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_21627228, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627228, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_21627228, "DeletionProtection", newJBool(DeletionProtection))
  add(query_21627228, "Action", newJString(Action))
  add(query_21627228, "EngineVersion", newJString(EngineVersion))
  add(query_21627228, "Port", newJInt(Port))
  add(query_21627228, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21627228, "Version", newJString(Version))
  add(query_21627228, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_21627227.call(nil, query_21627228, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_21627200(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_21627201,
    base: "/", makeUrl: url_GetModifyDBCluster_21627202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_21627276 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBClusterParameterGroup_21627278(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBClusterParameterGroup_21627277(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627279 = query.getOrDefault("Action")
  valid_21627279 = validateParameter(valid_21627279, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_21627279 != nil:
    section.add "Action", valid_21627279
  var valid_21627280 = query.getOrDefault("Version")
  valid_21627280 = validateParameter(valid_21627280, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627280 != nil:
    section.add "Version", valid_21627280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627281 = header.getOrDefault("X-Amz-Date")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "X-Amz-Date", valid_21627281
  var valid_21627282 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "X-Amz-Security-Token", valid_21627282
  var valid_21627283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627283 = validateParameter(valid_21627283, JString, required = false,
                                   default = nil)
  if valid_21627283 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627283
  var valid_21627284 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627284 = validateParameter(valid_21627284, JString, required = false,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "X-Amz-Algorithm", valid_21627284
  var valid_21627285 = header.getOrDefault("X-Amz-Signature")
  valid_21627285 = validateParameter(valid_21627285, JString, required = false,
                                   default = nil)
  if valid_21627285 != nil:
    section.add "X-Amz-Signature", valid_21627285
  var valid_21627286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627286 = validateParameter(valid_21627286, JString, required = false,
                                   default = nil)
  if valid_21627286 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627286
  var valid_21627287 = header.getOrDefault("X-Amz-Credential")
  valid_21627287 = validateParameter(valid_21627287, JString, required = false,
                                   default = nil)
  if valid_21627287 != nil:
    section.add "X-Amz-Credential", valid_21627287
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_21627288 = formData.getOrDefault("Parameters")
  valid_21627288 = validateParameter(valid_21627288, JArray, required = true,
                                   default = nil)
  if valid_21627288 != nil:
    section.add "Parameters", valid_21627288
  var valid_21627289 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_21627289 = validateParameter(valid_21627289, JString, required = true,
                                   default = nil)
  if valid_21627289 != nil:
    section.add "DBClusterParameterGroupName", valid_21627289
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627290: Call_PostModifyDBClusterParameterGroup_21627276;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_21627290.validator(path, query, header, formData, body, _)
  let scheme = call_21627290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627290.makeUrl(scheme.get, call_21627290.host, call_21627290.base,
                               call_21627290.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627290, uri, valid, _)

proc call*(call_21627291: Call_PostModifyDBClusterParameterGroup_21627276;
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
  var query_21627292 = newJObject()
  var formData_21627293 = newJObject()
  if Parameters != nil:
    formData_21627293.add "Parameters", Parameters
  add(query_21627292, "Action", newJString(Action))
  add(formData_21627293, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_21627292, "Version", newJString(Version))
  result = call_21627291.call(nil, query_21627292, nil, formData_21627293, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_21627276(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_21627277, base: "/",
    makeUrl: url_PostModifyDBClusterParameterGroup_21627278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_21627259 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBClusterParameterGroup_21627261(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBClusterParameterGroup_21627260(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627262 = query.getOrDefault("DBClusterParameterGroupName")
  valid_21627262 = validateParameter(valid_21627262, JString, required = true,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "DBClusterParameterGroupName", valid_21627262
  var valid_21627263 = query.getOrDefault("Parameters")
  valid_21627263 = validateParameter(valid_21627263, JArray, required = true,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "Parameters", valid_21627263
  var valid_21627264 = query.getOrDefault("Action")
  valid_21627264 = validateParameter(valid_21627264, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_21627264 != nil:
    section.add "Action", valid_21627264
  var valid_21627265 = query.getOrDefault("Version")
  valid_21627265 = validateParameter(valid_21627265, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627265 != nil:
    section.add "Version", valid_21627265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627266 = header.getOrDefault("X-Amz-Date")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "X-Amz-Date", valid_21627266
  var valid_21627267 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "X-Amz-Security-Token", valid_21627267
  var valid_21627268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627268 = validateParameter(valid_21627268, JString, required = false,
                                   default = nil)
  if valid_21627268 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627268
  var valid_21627269 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627269 = validateParameter(valid_21627269, JString, required = false,
                                   default = nil)
  if valid_21627269 != nil:
    section.add "X-Amz-Algorithm", valid_21627269
  var valid_21627270 = header.getOrDefault("X-Amz-Signature")
  valid_21627270 = validateParameter(valid_21627270, JString, required = false,
                                   default = nil)
  if valid_21627270 != nil:
    section.add "X-Amz-Signature", valid_21627270
  var valid_21627271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627271 = validateParameter(valid_21627271, JString, required = false,
                                   default = nil)
  if valid_21627271 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627271
  var valid_21627272 = header.getOrDefault("X-Amz-Credential")
  valid_21627272 = validateParameter(valid_21627272, JString, required = false,
                                   default = nil)
  if valid_21627272 != nil:
    section.add "X-Amz-Credential", valid_21627272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627273: Call_GetModifyDBClusterParameterGroup_21627259;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a cluster parameter group, you should wait at least 5 minutes before creating your first cluster that uses that cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new cluster. This step is especially important for parameters that are critical when creating the default database for a cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_21627273.validator(path, query, header, formData, body, _)
  let scheme = call_21627273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627273.makeUrl(scheme.get, call_21627273.host, call_21627273.base,
                               call_21627273.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627273, uri, valid, _)

proc call*(call_21627274: Call_GetModifyDBClusterParameterGroup_21627259;
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
  var query_21627275 = newJObject()
  add(query_21627275, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_21627275.add "Parameters", Parameters
  add(query_21627275, "Action", newJString(Action))
  add(query_21627275, "Version", newJString(Version))
  result = call_21627274.call(nil, query_21627275, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_21627259(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_21627260, base: "/",
    makeUrl: url_GetModifyDBClusterParameterGroup_21627261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_21627313 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBClusterSnapshotAttribute_21627315(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBClusterSnapshotAttribute_21627314(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627316 = query.getOrDefault("Action")
  valid_21627316 = validateParameter(valid_21627316, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_21627316 != nil:
    section.add "Action", valid_21627316
  var valid_21627317 = query.getOrDefault("Version")
  valid_21627317 = validateParameter(valid_21627317, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627317 != nil:
    section.add "Version", valid_21627317
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627318 = header.getOrDefault("X-Amz-Date")
  valid_21627318 = validateParameter(valid_21627318, JString, required = false,
                                   default = nil)
  if valid_21627318 != nil:
    section.add "X-Amz-Date", valid_21627318
  var valid_21627319 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627319 = validateParameter(valid_21627319, JString, required = false,
                                   default = nil)
  if valid_21627319 != nil:
    section.add "X-Amz-Security-Token", valid_21627319
  var valid_21627320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627320 = validateParameter(valid_21627320, JString, required = false,
                                   default = nil)
  if valid_21627320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627320
  var valid_21627321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627321 = validateParameter(valid_21627321, JString, required = false,
                                   default = nil)
  if valid_21627321 != nil:
    section.add "X-Amz-Algorithm", valid_21627321
  var valid_21627322 = header.getOrDefault("X-Amz-Signature")
  valid_21627322 = validateParameter(valid_21627322, JString, required = false,
                                   default = nil)
  if valid_21627322 != nil:
    section.add "X-Amz-Signature", valid_21627322
  var valid_21627323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627323
  var valid_21627324 = header.getOrDefault("X-Amz-Credential")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "X-Amz-Credential", valid_21627324
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_21627325 = formData.getOrDefault("AttributeName")
  valid_21627325 = validateParameter(valid_21627325, JString, required = true,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "AttributeName", valid_21627325
  var valid_21627326 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21627326 = validateParameter(valid_21627326, JString, required = true,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21627326
  var valid_21627327 = formData.getOrDefault("ValuesToRemove")
  valid_21627327 = validateParameter(valid_21627327, JArray, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "ValuesToRemove", valid_21627327
  var valid_21627328 = formData.getOrDefault("ValuesToAdd")
  valid_21627328 = validateParameter(valid_21627328, JArray, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "ValuesToAdd", valid_21627328
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627329: Call_PostModifyDBClusterSnapshotAttribute_21627313;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_21627329.validator(path, query, header, formData, body, _)
  let scheme = call_21627329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627329.makeUrl(scheme.get, call_21627329.host, call_21627329.base,
                               call_21627329.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627329, uri, valid, _)

proc call*(call_21627330: Call_PostModifyDBClusterSnapshotAttribute_21627313;
          AttributeName: string; DBClusterSnapshotIdentifier: string;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToRemove: JsonNode = nil; ValuesToAdd: JsonNode = nil;
          Version: string = "2014-10-31"): Recallable =
  ## postModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   AttributeName: string (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   Action: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Version: string (required)
  var query_21627331 = newJObject()
  var formData_21627332 = newJObject()
  add(formData_21627332, "AttributeName", newJString(AttributeName))
  add(formData_21627332, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_21627331, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_21627332.add "ValuesToRemove", ValuesToRemove
  if ValuesToAdd != nil:
    formData_21627332.add "ValuesToAdd", ValuesToAdd
  add(query_21627331, "Version", newJString(Version))
  result = call_21627330.call(nil, query_21627331, nil, formData_21627332, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_21627313(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_21627314, base: "/",
    makeUrl: url_PostModifyDBClusterSnapshotAttribute_21627315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_21627294 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBClusterSnapshotAttribute_21627296(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBClusterSnapshotAttribute_21627295(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AttributeName` field"
  var valid_21627297 = query.getOrDefault("AttributeName")
  valid_21627297 = validateParameter(valid_21627297, JString, required = true,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "AttributeName", valid_21627297
  var valid_21627298 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_21627298 = validateParameter(valid_21627298, JString, required = true,
                                   default = nil)
  if valid_21627298 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_21627298
  var valid_21627299 = query.getOrDefault("ValuesToAdd")
  valid_21627299 = validateParameter(valid_21627299, JArray, required = false,
                                   default = nil)
  if valid_21627299 != nil:
    section.add "ValuesToAdd", valid_21627299
  var valid_21627300 = query.getOrDefault("Action")
  valid_21627300 = validateParameter(valid_21627300, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_21627300 != nil:
    section.add "Action", valid_21627300
  var valid_21627301 = query.getOrDefault("ValuesToRemove")
  valid_21627301 = validateParameter(valid_21627301, JArray, required = false,
                                   default = nil)
  if valid_21627301 != nil:
    section.add "ValuesToRemove", valid_21627301
  var valid_21627302 = query.getOrDefault("Version")
  valid_21627302 = validateParameter(valid_21627302, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627302 != nil:
    section.add "Version", valid_21627302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627303 = header.getOrDefault("X-Amz-Date")
  valid_21627303 = validateParameter(valid_21627303, JString, required = false,
                                   default = nil)
  if valid_21627303 != nil:
    section.add "X-Amz-Date", valid_21627303
  var valid_21627304 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627304 = validateParameter(valid_21627304, JString, required = false,
                                   default = nil)
  if valid_21627304 != nil:
    section.add "X-Amz-Security-Token", valid_21627304
  var valid_21627305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627305
  var valid_21627306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "X-Amz-Algorithm", valid_21627306
  var valid_21627307 = header.getOrDefault("X-Amz-Signature")
  valid_21627307 = validateParameter(valid_21627307, JString, required = false,
                                   default = nil)
  if valid_21627307 != nil:
    section.add "X-Amz-Signature", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-Credential")
  valid_21627309 = validateParameter(valid_21627309, JString, required = false,
                                   default = nil)
  if valid_21627309 != nil:
    section.add "X-Amz-Credential", valid_21627309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627310: Call_GetModifyDBClusterSnapshotAttribute_21627294;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_21627310.validator(path, query, header, formData, body, _)
  let scheme = call_21627310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627310.makeUrl(scheme.get, call_21627310.host, call_21627310.base,
                               call_21627310.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627310, uri, valid, _)

proc call*(call_21627311: Call_GetModifyDBClusterSnapshotAttribute_21627294;
          AttributeName: string; DBClusterSnapshotIdentifier: string;
          ValuesToAdd: JsonNode = nil;
          Action: string = "ModifyDBClusterSnapshotAttribute";
          ValuesToRemove: JsonNode = nil; Version: string = "2014-10-31"): Recallable =
  ## getModifyDBClusterSnapshotAttribute
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual cluster snapshot. Use the value <code>all</code> to make the manual cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ##   AttributeName: string (required)
  ##                : <p>The name of the cluster snapshot attribute to modify.</p> <p>To manage authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this value to <code>restore</code>.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the cluster snapshot to modify the attributes for.
  ##   ValuesToAdd: JArray
  ##              : <p>A list of cluster snapshot attributes to add to the attribute specified by <code>AttributeName</code>.</p> <p>To authorize other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account IDs. To make the manual cluster snapshot restorable by any AWS account, set it to <code>all</code>. Do not add the <code>all</code> value for any manual cluster snapshots that contain private information that you don't want to be available to all AWS accounts.</p>
  ##   Action: string (required)
  ##   ValuesToRemove: JArray
  ##                 : <p>A list of cluster snapshot attributes to remove from the attribute specified by <code>AttributeName</code>.</p> <p>To remove authorization for other AWS accounts to copy or restore a manual cluster snapshot, set this list to include one or more AWS account identifiers. To remove authorization for any AWS account to copy or restore the cluster snapshot, set it to <code>all</code> . If you specify <code>all</code>, an AWS account whose account ID is explicitly added to the <code>restore</code> attribute can still copy or restore a manual cluster snapshot.</p>
  ##   Version: string (required)
  var query_21627312 = newJObject()
  add(query_21627312, "AttributeName", newJString(AttributeName))
  add(query_21627312, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if ValuesToAdd != nil:
    query_21627312.add "ValuesToAdd", ValuesToAdd
  add(query_21627312, "Action", newJString(Action))
  if ValuesToRemove != nil:
    query_21627312.add "ValuesToRemove", ValuesToRemove
  add(query_21627312, "Version", newJString(Version))
  result = call_21627311.call(nil, query_21627312, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_21627294(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_21627295, base: "/",
    makeUrl: url_GetModifyDBClusterSnapshotAttribute_21627296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_21627356 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBInstance_21627358(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_21627357(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627359 = query.getOrDefault("Action")
  valid_21627359 = validateParameter(valid_21627359, JString, required = true,
                                   default = newJString("ModifyDBInstance"))
  if valid_21627359 != nil:
    section.add "Action", valid_21627359
  var valid_21627360 = query.getOrDefault("Version")
  valid_21627360 = validateParameter(valid_21627360, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627360 != nil:
    section.add "Version", valid_21627360
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627361 = header.getOrDefault("X-Amz-Date")
  valid_21627361 = validateParameter(valid_21627361, JString, required = false,
                                   default = nil)
  if valid_21627361 != nil:
    section.add "X-Amz-Date", valid_21627361
  var valid_21627362 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627362 = validateParameter(valid_21627362, JString, required = false,
                                   default = nil)
  if valid_21627362 != nil:
    section.add "X-Amz-Security-Token", valid_21627362
  var valid_21627363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627363 = validateParameter(valid_21627363, JString, required = false,
                                   default = nil)
  if valid_21627363 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627363
  var valid_21627364 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627364 = validateParameter(valid_21627364, JString, required = false,
                                   default = nil)
  if valid_21627364 != nil:
    section.add "X-Amz-Algorithm", valid_21627364
  var valid_21627365 = header.getOrDefault("X-Amz-Signature")
  valid_21627365 = validateParameter(valid_21627365, JString, required = false,
                                   default = nil)
  if valid_21627365 != nil:
    section.add "X-Amz-Signature", valid_21627365
  var valid_21627366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627366 = validateParameter(valid_21627366, JString, required = false,
                                   default = nil)
  if valid_21627366 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627366
  var valid_21627367 = header.getOrDefault("X-Amz-Credential")
  valid_21627367 = validateParameter(valid_21627367, JString, required = false,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "X-Amz-Credential", valid_21627367
  result.add "header", section
  ## parameters in `formData` object:
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
  ##   DBInstanceClass: JString
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   AutoMinorVersionUpgrade: JBool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   PreferredMaintenanceWindow: JString
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  section = newJObject()
  var valid_21627368 = formData.getOrDefault("ApplyImmediately")
  valid_21627368 = validateParameter(valid_21627368, JBool, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "ApplyImmediately", valid_21627368
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627369 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627369 = validateParameter(valid_21627369, JString, required = true,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "DBInstanceIdentifier", valid_21627369
  var valid_21627370 = formData.getOrDefault("CACertificateIdentifier")
  valid_21627370 = validateParameter(valid_21627370, JString, required = false,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "CACertificateIdentifier", valid_21627370
  var valid_21627371 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "NewDBInstanceIdentifier", valid_21627371
  var valid_21627372 = formData.getOrDefault("PromotionTier")
  valid_21627372 = validateParameter(valid_21627372, JInt, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "PromotionTier", valid_21627372
  var valid_21627373 = formData.getOrDefault("DBInstanceClass")
  valid_21627373 = validateParameter(valid_21627373, JString, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "DBInstanceClass", valid_21627373
  var valid_21627374 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627374 = validateParameter(valid_21627374, JBool, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627374
  var valid_21627375 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21627375 = validateParameter(valid_21627375, JString, required = false,
                                   default = nil)
  if valid_21627375 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627375
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627376: Call_PostModifyDBInstance_21627356; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_21627376.validator(path, query, header, formData, body, _)
  let scheme = call_21627376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627376.makeUrl(scheme.get, call_21627376.host, call_21627376.base,
                               call_21627376.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627376, uri, valid, _)

proc call*(call_21627377: Call_PostModifyDBInstance_21627356;
          DBInstanceIdentifier: string; ApplyImmediately: bool = false;
          CACertificateIdentifier: string = "";
          NewDBInstanceIdentifier: string = ""; Action: string = "ModifyDBInstance";
          PromotionTier: int = 0; DBInstanceClass: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31";
          PreferredMaintenanceWindow: string = ""): Recallable =
  ## postModifyDBInstance
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
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
  ##   DBInstanceClass: string
  ##                  : <p>The new compute and memory capacity of the instance; for example, <code>db.r5.large</code>. Not all instance classes are available in all AWS Regions. </p> <p>If you modify the instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless <code>ApplyImmediately</code> is specified as <code>true</code> for this request. </p> <p>Default: Uses existing setting.</p>
  ##   AutoMinorVersionUpgrade: bool
  ##                          : Indicates that minor version upgrades are applied automatically to the instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case, and the change is asynchronously applied as soon as possible. An outage results if this parameter is set to <code>true</code> during the maintenance window, and a newer minor version is available, and Amazon DocumentDB has enabled automatic patching for that engine version. 
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  ##                             : <p>The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, changing this parameter causes a reboot of the instance. If you are moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure that pending changes are applied.</p> <p>Default: Uses existing setting.</p> <p>Format: <code>ddd:hh24:mi-ddd:hh24:mi</code> </p> <p>Valid days: Mon, Tue, Wed, Thu, Fri, Sat, Sun</p> <p>Constraints: Must be at least 30 minutes.</p>
  var query_21627378 = newJObject()
  var formData_21627379 = newJObject()
  add(formData_21627379, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_21627379, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627379, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(formData_21627379, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_21627378, "Action", newJString(Action))
  add(formData_21627379, "PromotionTier", newJInt(PromotionTier))
  add(formData_21627379, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21627379, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21627378, "Version", newJString(Version))
  add(formData_21627379, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_21627377.call(nil, query_21627378, nil, formData_21627379, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_21627356(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_21627357, base: "/",
    makeUrl: url_PostModifyDBInstance_21627358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_21627333 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBInstance_21627335(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_21627334(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627336 = query.getOrDefault("CACertificateIdentifier")
  valid_21627336 = validateParameter(valid_21627336, JString, required = false,
                                   default = nil)
  if valid_21627336 != nil:
    section.add "CACertificateIdentifier", valid_21627336
  var valid_21627337 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21627337 = validateParameter(valid_21627337, JString, required = false,
                                   default = nil)
  if valid_21627337 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627337
  var valid_21627338 = query.getOrDefault("PromotionTier")
  valid_21627338 = validateParameter(valid_21627338, JInt, required = false,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "PromotionTier", valid_21627338
  var valid_21627339 = query.getOrDefault("DBInstanceClass")
  valid_21627339 = validateParameter(valid_21627339, JString, required = false,
                                   default = nil)
  if valid_21627339 != nil:
    section.add "DBInstanceClass", valid_21627339
  var valid_21627340 = query.getOrDefault("Action")
  valid_21627340 = validateParameter(valid_21627340, JString, required = true,
                                   default = newJString("ModifyDBInstance"))
  if valid_21627340 != nil:
    section.add "Action", valid_21627340
  var valid_21627341 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "NewDBInstanceIdentifier", valid_21627341
  var valid_21627342 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627342 = validateParameter(valid_21627342, JBool, required = false,
                                   default = nil)
  if valid_21627342 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627342
  var valid_21627343 = query.getOrDefault("Version")
  valid_21627343 = validateParameter(valid_21627343, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627343 != nil:
    section.add "Version", valid_21627343
  var valid_21627344 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627344 = validateParameter(valid_21627344, JString, required = true,
                                   default = nil)
  if valid_21627344 != nil:
    section.add "DBInstanceIdentifier", valid_21627344
  var valid_21627345 = query.getOrDefault("ApplyImmediately")
  valid_21627345 = validateParameter(valid_21627345, JBool, required = false,
                                   default = nil)
  if valid_21627345 != nil:
    section.add "ApplyImmediately", valid_21627345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627346 = header.getOrDefault("X-Amz-Date")
  valid_21627346 = validateParameter(valid_21627346, JString, required = false,
                                   default = nil)
  if valid_21627346 != nil:
    section.add "X-Amz-Date", valid_21627346
  var valid_21627347 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627347 = validateParameter(valid_21627347, JString, required = false,
                                   default = nil)
  if valid_21627347 != nil:
    section.add "X-Amz-Security-Token", valid_21627347
  var valid_21627348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627348 = validateParameter(valid_21627348, JString, required = false,
                                   default = nil)
  if valid_21627348 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627348
  var valid_21627349 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627349 = validateParameter(valid_21627349, JString, required = false,
                                   default = nil)
  if valid_21627349 != nil:
    section.add "X-Amz-Algorithm", valid_21627349
  var valid_21627350 = header.getOrDefault("X-Amz-Signature")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "X-Amz-Signature", valid_21627350
  var valid_21627351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627351 = validateParameter(valid_21627351, JString, required = false,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627351
  var valid_21627352 = header.getOrDefault("X-Amz-Credential")
  valid_21627352 = validateParameter(valid_21627352, JString, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "X-Amz-Credential", valid_21627352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627353: Call_GetModifyDBInstance_21627333; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies settings for an instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_21627353.validator(path, query, header, formData, body, _)
  let scheme = call_21627353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627353.makeUrl(scheme.get, call_21627353.host, call_21627353.base,
                               call_21627353.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627353, uri, valid, _)

proc call*(call_21627354: Call_GetModifyDBInstance_21627333;
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
  var query_21627355 = newJObject()
  add(query_21627355, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(query_21627355, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21627355, "PromotionTier", newJInt(PromotionTier))
  add(query_21627355, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627355, "Action", newJString(Action))
  add(query_21627355, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_21627355, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21627355, "Version", newJString(Version))
  add(query_21627355, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627355, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_21627354.call(nil, query_21627355, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_21627333(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_21627334, base: "/",
    makeUrl: url_GetModifyDBInstance_21627335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_21627398 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBSubnetGroup_21627400(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_21627399(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627401 = query.getOrDefault("Action")
  valid_21627401 = validateParameter(valid_21627401, JString, required = true,
                                   default = newJString("ModifyDBSubnetGroup"))
  if valid_21627401 != nil:
    section.add "Action", valid_21627401
  var valid_21627402 = query.getOrDefault("Version")
  valid_21627402 = validateParameter(valid_21627402, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627402 != nil:
    section.add "Version", valid_21627402
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627403 = header.getOrDefault("X-Amz-Date")
  valid_21627403 = validateParameter(valid_21627403, JString, required = false,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "X-Amz-Date", valid_21627403
  var valid_21627404 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "X-Amz-Security-Token", valid_21627404
  var valid_21627405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627405 = validateParameter(valid_21627405, JString, required = false,
                                   default = nil)
  if valid_21627405 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627405
  var valid_21627406 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627406 = validateParameter(valid_21627406, JString, required = false,
                                   default = nil)
  if valid_21627406 != nil:
    section.add "X-Amz-Algorithm", valid_21627406
  var valid_21627407 = header.getOrDefault("X-Amz-Signature")
  valid_21627407 = validateParameter(valid_21627407, JString, required = false,
                                   default = nil)
  if valid_21627407 != nil:
    section.add "X-Amz-Signature", valid_21627407
  var valid_21627408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627408 = validateParameter(valid_21627408, JString, required = false,
                                   default = nil)
  if valid_21627408 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627408
  var valid_21627409 = header.getOrDefault("X-Amz-Credential")
  valid_21627409 = validateParameter(valid_21627409, JString, required = false,
                                   default = nil)
  if valid_21627409 != nil:
    section.add "X-Amz-Credential", valid_21627409
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the subnet group.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21627410 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627410 = validateParameter(valid_21627410, JString, required = true,
                                   default = nil)
  if valid_21627410 != nil:
    section.add "DBSubnetGroupName", valid_21627410
  var valid_21627411 = formData.getOrDefault("SubnetIds")
  valid_21627411 = validateParameter(valid_21627411, JArray, required = true,
                                   default = nil)
  if valid_21627411 != nil:
    section.add "SubnetIds", valid_21627411
  var valid_21627412 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_21627412 = validateParameter(valid_21627412, JString, required = false,
                                   default = nil)
  if valid_21627412 != nil:
    section.add "DBSubnetGroupDescription", valid_21627412
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627413: Call_PostModifyDBSubnetGroup_21627398;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_21627413.validator(path, query, header, formData, body, _)
  let scheme = call_21627413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627413.makeUrl(scheme.get, call_21627413.host, call_21627413.base,
                               call_21627413.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627413, uri, valid, _)

proc call*(call_21627414: Call_PostModifyDBSubnetGroup_21627398;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-10-31"): Recallable =
  ## postModifyDBSubnetGroup
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name for the subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the subnet group.
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##                           : The description for the subnet group.
  ##   Version: string (required)
  var query_21627415 = newJObject()
  var formData_21627416 = newJObject()
  add(formData_21627416, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_21627416.add "SubnetIds", SubnetIds
  add(query_21627415, "Action", newJString(Action))
  add(formData_21627416, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21627415, "Version", newJString(Version))
  result = call_21627414.call(nil, query_21627415, nil, formData_21627416, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_21627398(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_21627399, base: "/",
    makeUrl: url_PostModifyDBSubnetGroup_21627400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_21627380 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBSubnetGroup_21627382(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_21627381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627383 = query.getOrDefault("Action")
  valid_21627383 = validateParameter(valid_21627383, JString, required = true,
                                   default = newJString("ModifyDBSubnetGroup"))
  if valid_21627383 != nil:
    section.add "Action", valid_21627383
  var valid_21627384 = query.getOrDefault("DBSubnetGroupName")
  valid_21627384 = validateParameter(valid_21627384, JString, required = true,
                                   default = nil)
  if valid_21627384 != nil:
    section.add "DBSubnetGroupName", valid_21627384
  var valid_21627385 = query.getOrDefault("SubnetIds")
  valid_21627385 = validateParameter(valid_21627385, JArray, required = true,
                                   default = nil)
  if valid_21627385 != nil:
    section.add "SubnetIds", valid_21627385
  var valid_21627386 = query.getOrDefault("DBSubnetGroupDescription")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "DBSubnetGroupDescription", valid_21627386
  var valid_21627387 = query.getOrDefault("Version")
  valid_21627387 = validateParameter(valid_21627387, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627387 != nil:
    section.add "Version", valid_21627387
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627388 = header.getOrDefault("X-Amz-Date")
  valid_21627388 = validateParameter(valid_21627388, JString, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "X-Amz-Date", valid_21627388
  var valid_21627389 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-Security-Token", valid_21627389
  var valid_21627390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627390 = validateParameter(valid_21627390, JString, required = false,
                                   default = nil)
  if valid_21627390 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627390
  var valid_21627391 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627391 = validateParameter(valid_21627391, JString, required = false,
                                   default = nil)
  if valid_21627391 != nil:
    section.add "X-Amz-Algorithm", valid_21627391
  var valid_21627392 = header.getOrDefault("X-Amz-Signature")
  valid_21627392 = validateParameter(valid_21627392, JString, required = false,
                                   default = nil)
  if valid_21627392 != nil:
    section.add "X-Amz-Signature", valid_21627392
  var valid_21627393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627393 = validateParameter(valid_21627393, JString, required = false,
                                   default = nil)
  if valid_21627393 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627393
  var valid_21627394 = header.getOrDefault("X-Amz-Credential")
  valid_21627394 = validateParameter(valid_21627394, JString, required = false,
                                   default = nil)
  if valid_21627394 != nil:
    section.add "X-Amz-Credential", valid_21627394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627395: Call_GetModifyDBSubnetGroup_21627380;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies an existing subnet group. subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_21627395.validator(path, query, header, formData, body, _)
  let scheme = call_21627395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627395.makeUrl(scheme.get, call_21627395.host, call_21627395.base,
                               call_21627395.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627395, uri, valid, _)

proc call*(call_21627396: Call_GetModifyDBSubnetGroup_21627380;
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
  var query_21627397 = newJObject()
  add(query_21627397, "Action", newJString(Action))
  add(query_21627397, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_21627397.add "SubnetIds", SubnetIds
  add(query_21627397, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21627397, "Version", newJString(Version))
  result = call_21627396.call(nil, query_21627397, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_21627380(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_21627381, base: "/",
    makeUrl: url_GetModifyDBSubnetGroup_21627382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_21627434 = ref object of OpenApiRestCall_21625418
proc url_PostRebootDBInstance_21627436(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_21627435(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627437 = query.getOrDefault("Action")
  valid_21627437 = validateParameter(valid_21627437, JString, required = true,
                                   default = newJString("RebootDBInstance"))
  if valid_21627437 != nil:
    section.add "Action", valid_21627437
  var valid_21627438 = query.getOrDefault("Version")
  valid_21627438 = validateParameter(valid_21627438, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627438 != nil:
    section.add "Version", valid_21627438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627439 = header.getOrDefault("X-Amz-Date")
  valid_21627439 = validateParameter(valid_21627439, JString, required = false,
                                   default = nil)
  if valid_21627439 != nil:
    section.add "X-Amz-Date", valid_21627439
  var valid_21627440 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627440 = validateParameter(valid_21627440, JString, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "X-Amz-Security-Token", valid_21627440
  var valid_21627441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627441 = validateParameter(valid_21627441, JString, required = false,
                                   default = nil)
  if valid_21627441 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627441
  var valid_21627442 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627442 = validateParameter(valid_21627442, JString, required = false,
                                   default = nil)
  if valid_21627442 != nil:
    section.add "X-Amz-Algorithm", valid_21627442
  var valid_21627443 = header.getOrDefault("X-Amz-Signature")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Signature", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-Credential")
  valid_21627445 = validateParameter(valid_21627445, JString, required = false,
                                   default = nil)
  if valid_21627445 != nil:
    section.add "X-Amz-Credential", valid_21627445
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627446 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627446 = validateParameter(valid_21627446, JString, required = true,
                                   default = nil)
  if valid_21627446 != nil:
    section.add "DBInstanceIdentifier", valid_21627446
  var valid_21627447 = formData.getOrDefault("ForceFailover")
  valid_21627447 = validateParameter(valid_21627447, JBool, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "ForceFailover", valid_21627447
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627448: Call_PostRebootDBInstance_21627434; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_21627448.validator(path, query, header, formData, body, _)
  let scheme = call_21627448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627448.makeUrl(scheme.get, call_21627448.host, call_21627448.base,
                               call_21627448.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627448, uri, valid, _)

proc call*(call_21627449: Call_PostRebootDBInstance_21627434;
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
  var query_21627450 = newJObject()
  var formData_21627451 = newJObject()
  add(formData_21627451, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627450, "Action", newJString(Action))
  add(formData_21627451, "ForceFailover", newJBool(ForceFailover))
  add(query_21627450, "Version", newJString(Version))
  result = call_21627449.call(nil, query_21627450, nil, formData_21627451, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_21627434(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_21627435, base: "/",
    makeUrl: url_PostRebootDBInstance_21627436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_21627417 = ref object of OpenApiRestCall_21625418
proc url_GetRebootDBInstance_21627419(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_21627418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627420 = query.getOrDefault("Action")
  valid_21627420 = validateParameter(valid_21627420, JString, required = true,
                                   default = newJString("RebootDBInstance"))
  if valid_21627420 != nil:
    section.add "Action", valid_21627420
  var valid_21627421 = query.getOrDefault("ForceFailover")
  valid_21627421 = validateParameter(valid_21627421, JBool, required = false,
                                   default = nil)
  if valid_21627421 != nil:
    section.add "ForceFailover", valid_21627421
  var valid_21627422 = query.getOrDefault("Version")
  valid_21627422 = validateParameter(valid_21627422, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627422 != nil:
    section.add "Version", valid_21627422
  var valid_21627423 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627423 = validateParameter(valid_21627423, JString, required = true,
                                   default = nil)
  if valid_21627423 != nil:
    section.add "DBInstanceIdentifier", valid_21627423
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627424 = header.getOrDefault("X-Amz-Date")
  valid_21627424 = validateParameter(valid_21627424, JString, required = false,
                                   default = nil)
  if valid_21627424 != nil:
    section.add "X-Amz-Date", valid_21627424
  var valid_21627425 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627425 = validateParameter(valid_21627425, JString, required = false,
                                   default = nil)
  if valid_21627425 != nil:
    section.add "X-Amz-Security-Token", valid_21627425
  var valid_21627426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627426 = validateParameter(valid_21627426, JString, required = false,
                                   default = nil)
  if valid_21627426 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627426
  var valid_21627427 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627427 = validateParameter(valid_21627427, JString, required = false,
                                   default = nil)
  if valid_21627427 != nil:
    section.add "X-Amz-Algorithm", valid_21627427
  var valid_21627428 = header.getOrDefault("X-Amz-Signature")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "X-Amz-Signature", valid_21627428
  var valid_21627429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627429 = validateParameter(valid_21627429, JString, required = false,
                                   default = nil)
  if valid_21627429 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627429
  var valid_21627430 = header.getOrDefault("X-Amz-Credential")
  valid_21627430 = validateParameter(valid_21627430, JString, required = false,
                                   default = nil)
  if valid_21627430 != nil:
    section.add "X-Amz-Credential", valid_21627430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627431: Call_GetRebootDBInstance_21627417; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>You might need to reboot your instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the cluster parameter group that is associated with the instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting an instance restarts the database engine service. Rebooting an instance results in a momentary outage, during which the instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_21627431.validator(path, query, header, formData, body, _)
  let scheme = call_21627431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627431.makeUrl(scheme.get, call_21627431.host, call_21627431.base,
                               call_21627431.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627431, uri, valid, _)

proc call*(call_21627432: Call_GetRebootDBInstance_21627417;
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
  var query_21627433 = newJObject()
  add(query_21627433, "Action", newJString(Action))
  add(query_21627433, "ForceFailover", newJBool(ForceFailover))
  add(query_21627433, "Version", newJString(Version))
  add(query_21627433, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21627432.call(nil, query_21627433, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_21627417(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_21627418, base: "/",
    makeUrl: url_GetRebootDBInstance_21627419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_21627469 = ref object of OpenApiRestCall_21625418
proc url_PostRemoveTagsFromResource_21627471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_21627470(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627472 = query.getOrDefault("Action")
  valid_21627472 = validateParameter(valid_21627472, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_21627472 != nil:
    section.add "Action", valid_21627472
  var valid_21627473 = query.getOrDefault("Version")
  valid_21627473 = validateParameter(valid_21627473, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627473 != nil:
    section.add "Version", valid_21627473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627474 = header.getOrDefault("X-Amz-Date")
  valid_21627474 = validateParameter(valid_21627474, JString, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "X-Amz-Date", valid_21627474
  var valid_21627475 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627475 = validateParameter(valid_21627475, JString, required = false,
                                   default = nil)
  if valid_21627475 != nil:
    section.add "X-Amz-Security-Token", valid_21627475
  var valid_21627476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627476 = validateParameter(valid_21627476, JString, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627476
  var valid_21627477 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627477 = validateParameter(valid_21627477, JString, required = false,
                                   default = nil)
  if valid_21627477 != nil:
    section.add "X-Amz-Algorithm", valid_21627477
  var valid_21627478 = header.getOrDefault("X-Amz-Signature")
  valid_21627478 = validateParameter(valid_21627478, JString, required = false,
                                   default = nil)
  if valid_21627478 != nil:
    section.add "X-Amz-Signature", valid_21627478
  var valid_21627479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627479 = validateParameter(valid_21627479, JString, required = false,
                                   default = nil)
  if valid_21627479 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627479
  var valid_21627480 = header.getOrDefault("X-Amz-Credential")
  valid_21627480 = validateParameter(valid_21627480, JString, required = false,
                                   default = nil)
  if valid_21627480 != nil:
    section.add "X-Amz-Credential", valid_21627480
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_21627481 = formData.getOrDefault("TagKeys")
  valid_21627481 = validateParameter(valid_21627481, JArray, required = true,
                                   default = nil)
  if valid_21627481 != nil:
    section.add "TagKeys", valid_21627481
  var valid_21627482 = formData.getOrDefault("ResourceName")
  valid_21627482 = validateParameter(valid_21627482, JString, required = true,
                                   default = nil)
  if valid_21627482 != nil:
    section.add "ResourceName", valid_21627482
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627483: Call_PostRemoveTagsFromResource_21627469;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_21627483.validator(path, query, header, formData, body, _)
  let scheme = call_21627483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627483.makeUrl(scheme.get, call_21627483.host, call_21627483.base,
                               call_21627483.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627483, uri, valid, _)

proc call*(call_21627484: Call_PostRemoveTagsFromResource_21627469;
          TagKeys: JsonNode; ResourceName: string;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-10-31"): Recallable =
  ## postRemoveTagsFromResource
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: string (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  ##   Version: string (required)
  var query_21627485 = newJObject()
  var formData_21627486 = newJObject()
  add(query_21627485, "Action", newJString(Action))
  if TagKeys != nil:
    formData_21627486.add "TagKeys", TagKeys
  add(formData_21627486, "ResourceName", newJString(ResourceName))
  add(query_21627485, "Version", newJString(Version))
  result = call_21627484.call(nil, query_21627485, nil, formData_21627486, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_21627469(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_21627470, base: "/",
    makeUrl: url_PostRemoveTagsFromResource_21627471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_21627452 = ref object of OpenApiRestCall_21625418
proc url_GetRemoveTagsFromResource_21627454(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_21627453(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627455 = query.getOrDefault("ResourceName")
  valid_21627455 = validateParameter(valid_21627455, JString, required = true,
                                   default = nil)
  if valid_21627455 != nil:
    section.add "ResourceName", valid_21627455
  var valid_21627456 = query.getOrDefault("Action")
  valid_21627456 = validateParameter(valid_21627456, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_21627456 != nil:
    section.add "Action", valid_21627456
  var valid_21627457 = query.getOrDefault("TagKeys")
  valid_21627457 = validateParameter(valid_21627457, JArray, required = true,
                                   default = nil)
  if valid_21627457 != nil:
    section.add "TagKeys", valid_21627457
  var valid_21627458 = query.getOrDefault("Version")
  valid_21627458 = validateParameter(valid_21627458, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627458 != nil:
    section.add "Version", valid_21627458
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627459 = header.getOrDefault("X-Amz-Date")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "X-Amz-Date", valid_21627459
  var valid_21627460 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627460 = validateParameter(valid_21627460, JString, required = false,
                                   default = nil)
  if valid_21627460 != nil:
    section.add "X-Amz-Security-Token", valid_21627460
  var valid_21627461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627461 = validateParameter(valid_21627461, JString, required = false,
                                   default = nil)
  if valid_21627461 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627461
  var valid_21627462 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Algorithm", valid_21627462
  var valid_21627463 = header.getOrDefault("X-Amz-Signature")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "X-Amz-Signature", valid_21627463
  var valid_21627464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627464 = validateParameter(valid_21627464, JString, required = false,
                                   default = nil)
  if valid_21627464 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627464
  var valid_21627465 = header.getOrDefault("X-Amz-Credential")
  valid_21627465 = validateParameter(valid_21627465, JString, required = false,
                                   default = nil)
  if valid_21627465 != nil:
    section.add "X-Amz-Credential", valid_21627465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627466: Call_GetRemoveTagsFromResource_21627452;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_21627466.validator(path, query, header, formData, body, _)
  let scheme = call_21627466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627466.makeUrl(scheme.get, call_21627466.host, call_21627466.base,
                               call_21627466.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627466, uri, valid, _)

proc call*(call_21627467: Call_GetRemoveTagsFromResource_21627452;
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
  var query_21627468 = newJObject()
  add(query_21627468, "ResourceName", newJString(ResourceName))
  add(query_21627468, "Action", newJString(Action))
  if TagKeys != nil:
    query_21627468.add "TagKeys", TagKeys
  add(query_21627468, "Version", newJString(Version))
  result = call_21627467.call(nil, query_21627468, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_21627452(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_21627453, base: "/",
    makeUrl: url_GetRemoveTagsFromResource_21627454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_21627505 = ref object of OpenApiRestCall_21625418
proc url_PostResetDBClusterParameterGroup_21627507(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBClusterParameterGroup_21627506(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627508 = query.getOrDefault("Action")
  valid_21627508 = validateParameter(valid_21627508, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_21627508 != nil:
    section.add "Action", valid_21627508
  var valid_21627509 = query.getOrDefault("Version")
  valid_21627509 = validateParameter(valid_21627509, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627509 != nil:
    section.add "Version", valid_21627509
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627510 = header.getOrDefault("X-Amz-Date")
  valid_21627510 = validateParameter(valid_21627510, JString, required = false,
                                   default = nil)
  if valid_21627510 != nil:
    section.add "X-Amz-Date", valid_21627510
  var valid_21627511 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627511 = validateParameter(valid_21627511, JString, required = false,
                                   default = nil)
  if valid_21627511 != nil:
    section.add "X-Amz-Security-Token", valid_21627511
  var valid_21627512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627512 = validateParameter(valid_21627512, JString, required = false,
                                   default = nil)
  if valid_21627512 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627512
  var valid_21627513 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627513 = validateParameter(valid_21627513, JString, required = false,
                                   default = nil)
  if valid_21627513 != nil:
    section.add "X-Amz-Algorithm", valid_21627513
  var valid_21627514 = header.getOrDefault("X-Amz-Signature")
  valid_21627514 = validateParameter(valid_21627514, JString, required = false,
                                   default = nil)
  if valid_21627514 != nil:
    section.add "X-Amz-Signature", valid_21627514
  var valid_21627515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627515 = validateParameter(valid_21627515, JString, required = false,
                                   default = nil)
  if valid_21627515 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627515
  var valid_21627516 = header.getOrDefault("X-Amz-Credential")
  valid_21627516 = validateParameter(valid_21627516, JString, required = false,
                                   default = nil)
  if valid_21627516 != nil:
    section.add "X-Amz-Credential", valid_21627516
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  section = newJObject()
  var valid_21627517 = formData.getOrDefault("Parameters")
  valid_21627517 = validateParameter(valid_21627517, JArray, required = false,
                                   default = nil)
  if valid_21627517 != nil:
    section.add "Parameters", valid_21627517
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_21627518 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_21627518 = validateParameter(valid_21627518, JString, required = true,
                                   default = nil)
  if valid_21627518 != nil:
    section.add "DBClusterParameterGroupName", valid_21627518
  var valid_21627519 = formData.getOrDefault("ResetAllParameters")
  valid_21627519 = validateParameter(valid_21627519, JBool, required = false,
                                   default = nil)
  if valid_21627519 != nil:
    section.add "ResetAllParameters", valid_21627519
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627520: Call_PostResetDBClusterParameterGroup_21627505;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_21627520.validator(path, query, header, formData, body, _)
  let scheme = call_21627520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627520.makeUrl(scheme.get, call_21627520.host, call_21627520.base,
                               call_21627520.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627520, uri, valid, _)

proc call*(call_21627521: Call_PostResetDBClusterParameterGroup_21627505;
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
  var query_21627522 = newJObject()
  var formData_21627523 = newJObject()
  if Parameters != nil:
    formData_21627523.add "Parameters", Parameters
  add(query_21627522, "Action", newJString(Action))
  add(formData_21627523, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_21627523, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_21627522, "Version", newJString(Version))
  result = call_21627521.call(nil, query_21627522, nil, formData_21627523, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_21627505(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_21627506, base: "/",
    makeUrl: url_PostResetDBClusterParameterGroup_21627507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_21627487 = ref object of OpenApiRestCall_21625418
proc url_GetResetDBClusterParameterGroup_21627489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBClusterParameterGroup_21627488(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627490 = query.getOrDefault("DBClusterParameterGroupName")
  valid_21627490 = validateParameter(valid_21627490, JString, required = true,
                                   default = nil)
  if valid_21627490 != nil:
    section.add "DBClusterParameterGroupName", valid_21627490
  var valid_21627491 = query.getOrDefault("Parameters")
  valid_21627491 = validateParameter(valid_21627491, JArray, required = false,
                                   default = nil)
  if valid_21627491 != nil:
    section.add "Parameters", valid_21627491
  var valid_21627492 = query.getOrDefault("Action")
  valid_21627492 = validateParameter(valid_21627492, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_21627492 != nil:
    section.add "Action", valid_21627492
  var valid_21627493 = query.getOrDefault("ResetAllParameters")
  valid_21627493 = validateParameter(valid_21627493, JBool, required = false,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "ResetAllParameters", valid_21627493
  var valid_21627494 = query.getOrDefault("Version")
  valid_21627494 = validateParameter(valid_21627494, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627494 != nil:
    section.add "Version", valid_21627494
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627495 = header.getOrDefault("X-Amz-Date")
  valid_21627495 = validateParameter(valid_21627495, JString, required = false,
                                   default = nil)
  if valid_21627495 != nil:
    section.add "X-Amz-Date", valid_21627495
  var valid_21627496 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627496 = validateParameter(valid_21627496, JString, required = false,
                                   default = nil)
  if valid_21627496 != nil:
    section.add "X-Amz-Security-Token", valid_21627496
  var valid_21627497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627497 = validateParameter(valid_21627497, JString, required = false,
                                   default = nil)
  if valid_21627497 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627497
  var valid_21627498 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627498 = validateParameter(valid_21627498, JString, required = false,
                                   default = nil)
  if valid_21627498 != nil:
    section.add "X-Amz-Algorithm", valid_21627498
  var valid_21627499 = header.getOrDefault("X-Amz-Signature")
  valid_21627499 = validateParameter(valid_21627499, JString, required = false,
                                   default = nil)
  if valid_21627499 != nil:
    section.add "X-Amz-Signature", valid_21627499
  var valid_21627500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627500 = validateParameter(valid_21627500, JString, required = false,
                                   default = nil)
  if valid_21627500 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627500
  var valid_21627501 = header.getOrDefault("X-Amz-Credential")
  valid_21627501 = validateParameter(valid_21627501, JString, required = false,
                                   default = nil)
  if valid_21627501 != nil:
    section.add "X-Amz-Credential", valid_21627501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627502: Call_GetResetDBClusterParameterGroup_21627487;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Modifies the parameters of a cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_21627502.validator(path, query, header, formData, body, _)
  let scheme = call_21627502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627502.makeUrl(scheme.get, call_21627502.host, call_21627502.base,
                               call_21627502.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627502, uri, valid, _)

proc call*(call_21627503: Call_GetResetDBClusterParameterGroup_21627487;
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
  var query_21627504 = newJObject()
  add(query_21627504, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_21627504.add "Parameters", Parameters
  add(query_21627504, "Action", newJString(Action))
  add(query_21627504, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_21627504, "Version", newJString(Version))
  result = call_21627503.call(nil, query_21627504, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_21627487(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_21627488, base: "/",
    makeUrl: url_GetResetDBClusterParameterGroup_21627489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_21627551 = ref object of OpenApiRestCall_21625418
proc url_PostRestoreDBClusterFromSnapshot_21627553(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBClusterFromSnapshot_21627552(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627554 = query.getOrDefault("Action")
  valid_21627554 = validateParameter(valid_21627554, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_21627554 != nil:
    section.add "Action", valid_21627554
  var valid_21627555 = query.getOrDefault("Version")
  valid_21627555 = validateParameter(valid_21627555, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627555 != nil:
    section.add "Version", valid_21627555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627556 = header.getOrDefault("X-Amz-Date")
  valid_21627556 = validateParameter(valid_21627556, JString, required = false,
                                   default = nil)
  if valid_21627556 != nil:
    section.add "X-Amz-Date", valid_21627556
  var valid_21627557 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627557 = validateParameter(valid_21627557, JString, required = false,
                                   default = nil)
  if valid_21627557 != nil:
    section.add "X-Amz-Security-Token", valid_21627557
  var valid_21627558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627558 = validateParameter(valid_21627558, JString, required = false,
                                   default = nil)
  if valid_21627558 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627558
  var valid_21627559 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627559 = validateParameter(valid_21627559, JString, required = false,
                                   default = nil)
  if valid_21627559 != nil:
    section.add "X-Amz-Algorithm", valid_21627559
  var valid_21627560 = header.getOrDefault("X-Amz-Signature")
  valid_21627560 = validateParameter(valid_21627560, JString, required = false,
                                   default = nil)
  if valid_21627560 != nil:
    section.add "X-Amz-Signature", valid_21627560
  var valid_21627561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627561 = validateParameter(valid_21627561, JString, required = false,
                                   default = nil)
  if valid_21627561 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627561
  var valid_21627562 = header.getOrDefault("X-Amz-Credential")
  valid_21627562 = validateParameter(valid_21627562, JString, required = false,
                                   default = nil)
  if valid_21627562 != nil:
    section.add "X-Amz-Credential", valid_21627562
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
  var valid_21627563 = formData.getOrDefault("Port")
  valid_21627563 = validateParameter(valid_21627563, JInt, required = false,
                                   default = nil)
  if valid_21627563 != nil:
    section.add "Port", valid_21627563
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_21627564 = formData.getOrDefault("Engine")
  valid_21627564 = validateParameter(valid_21627564, JString, required = true,
                                   default = nil)
  if valid_21627564 != nil:
    section.add "Engine", valid_21627564
  var valid_21627565 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21627565 = validateParameter(valid_21627565, JArray, required = false,
                                   default = nil)
  if valid_21627565 != nil:
    section.add "VpcSecurityGroupIds", valid_21627565
  var valid_21627566 = formData.getOrDefault("Tags")
  valid_21627566 = validateParameter(valid_21627566, JArray, required = false,
                                   default = nil)
  if valid_21627566 != nil:
    section.add "Tags", valid_21627566
  var valid_21627567 = formData.getOrDefault("DeletionProtection")
  valid_21627567 = validateParameter(valid_21627567, JBool, required = false,
                                   default = nil)
  if valid_21627567 != nil:
    section.add "DeletionProtection", valid_21627567
  var valid_21627568 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627568 = validateParameter(valid_21627568, JString, required = false,
                                   default = nil)
  if valid_21627568 != nil:
    section.add "DBSubnetGroupName", valid_21627568
  var valid_21627569 = formData.getOrDefault("AvailabilityZones")
  valid_21627569 = validateParameter(valid_21627569, JArray, required = false,
                                   default = nil)
  if valid_21627569 != nil:
    section.add "AvailabilityZones", valid_21627569
  var valid_21627570 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_21627570 = validateParameter(valid_21627570, JArray, required = false,
                                   default = nil)
  if valid_21627570 != nil:
    section.add "EnableCloudwatchLogsExports", valid_21627570
  var valid_21627571 = formData.getOrDefault("KmsKeyId")
  valid_21627571 = validateParameter(valid_21627571, JString, required = false,
                                   default = nil)
  if valid_21627571 != nil:
    section.add "KmsKeyId", valid_21627571
  var valid_21627572 = formData.getOrDefault("SnapshotIdentifier")
  valid_21627572 = validateParameter(valid_21627572, JString, required = true,
                                   default = nil)
  if valid_21627572 != nil:
    section.add "SnapshotIdentifier", valid_21627572
  var valid_21627573 = formData.getOrDefault("DBClusterIdentifier")
  valid_21627573 = validateParameter(valid_21627573, JString, required = true,
                                   default = nil)
  if valid_21627573 != nil:
    section.add "DBClusterIdentifier", valid_21627573
  var valid_21627574 = formData.getOrDefault("EngineVersion")
  valid_21627574 = validateParameter(valid_21627574, JString, required = false,
                                   default = nil)
  if valid_21627574 != nil:
    section.add "EngineVersion", valid_21627574
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627575: Call_PostRestoreDBClusterFromSnapshot_21627551;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  let valid = call_21627575.validator(path, query, header, formData, body, _)
  let scheme = call_21627575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627575.makeUrl(scheme.get, call_21627575.host, call_21627575.base,
                               call_21627575.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627575, uri, valid, _)

proc call*(call_21627576: Call_PostRestoreDBClusterFromSnapshot_21627551;
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
  var query_21627577 = newJObject()
  var formData_21627578 = newJObject()
  add(formData_21627578, "Port", newJInt(Port))
  add(formData_21627578, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_21627578.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if Tags != nil:
    formData_21627578.add "Tags", Tags
  add(formData_21627578, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_21627578, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21627577, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_21627578.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    formData_21627578.add "EnableCloudwatchLogsExports",
                         EnableCloudwatchLogsExports
  add(formData_21627578, "KmsKeyId", newJString(KmsKeyId))
  add(formData_21627578, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(formData_21627578, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_21627578, "EngineVersion", newJString(EngineVersion))
  add(query_21627577, "Version", newJString(Version))
  result = call_21627576.call(nil, query_21627577, nil, formData_21627578, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_21627551(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_21627552, base: "/",
    makeUrl: url_PostRestoreDBClusterFromSnapshot_21627553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_21627524 = ref object of OpenApiRestCall_21625418
proc url_GetRestoreDBClusterFromSnapshot_21627526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBClusterFromSnapshot_21627525(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
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
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   EngineVersion: JString
  ##                : The version of the database engine to use for the new cluster.
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   SnapshotIdentifier: JString (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_21627527 = query.getOrDefault("Engine")
  valid_21627527 = validateParameter(valid_21627527, JString, required = true,
                                   default = nil)
  if valid_21627527 != nil:
    section.add "Engine", valid_21627527
  var valid_21627528 = query.getOrDefault("AvailabilityZones")
  valid_21627528 = validateParameter(valid_21627528, JArray, required = false,
                                   default = nil)
  if valid_21627528 != nil:
    section.add "AvailabilityZones", valid_21627528
  var valid_21627529 = query.getOrDefault("DBClusterIdentifier")
  valid_21627529 = validateParameter(valid_21627529, JString, required = true,
                                   default = nil)
  if valid_21627529 != nil:
    section.add "DBClusterIdentifier", valid_21627529
  var valid_21627530 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21627530 = validateParameter(valid_21627530, JArray, required = false,
                                   default = nil)
  if valid_21627530 != nil:
    section.add "VpcSecurityGroupIds", valid_21627530
  var valid_21627531 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_21627531 = validateParameter(valid_21627531, JArray, required = false,
                                   default = nil)
  if valid_21627531 != nil:
    section.add "EnableCloudwatchLogsExports", valid_21627531
  var valid_21627532 = query.getOrDefault("Tags")
  valid_21627532 = validateParameter(valid_21627532, JArray, required = false,
                                   default = nil)
  if valid_21627532 != nil:
    section.add "Tags", valid_21627532
  var valid_21627533 = query.getOrDefault("DeletionProtection")
  valid_21627533 = validateParameter(valid_21627533, JBool, required = false,
                                   default = nil)
  if valid_21627533 != nil:
    section.add "DeletionProtection", valid_21627533
  var valid_21627534 = query.getOrDefault("Action")
  valid_21627534 = validateParameter(valid_21627534, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_21627534 != nil:
    section.add "Action", valid_21627534
  var valid_21627535 = query.getOrDefault("DBSubnetGroupName")
  valid_21627535 = validateParameter(valid_21627535, JString, required = false,
                                   default = nil)
  if valid_21627535 != nil:
    section.add "DBSubnetGroupName", valid_21627535
  var valid_21627536 = query.getOrDefault("KmsKeyId")
  valid_21627536 = validateParameter(valid_21627536, JString, required = false,
                                   default = nil)
  if valid_21627536 != nil:
    section.add "KmsKeyId", valid_21627536
  var valid_21627537 = query.getOrDefault("EngineVersion")
  valid_21627537 = validateParameter(valid_21627537, JString, required = false,
                                   default = nil)
  if valid_21627537 != nil:
    section.add "EngineVersion", valid_21627537
  var valid_21627538 = query.getOrDefault("Port")
  valid_21627538 = validateParameter(valid_21627538, JInt, required = false,
                                   default = nil)
  if valid_21627538 != nil:
    section.add "Port", valid_21627538
  var valid_21627539 = query.getOrDefault("SnapshotIdentifier")
  valid_21627539 = validateParameter(valid_21627539, JString, required = true,
                                   default = nil)
  if valid_21627539 != nil:
    section.add "SnapshotIdentifier", valid_21627539
  var valid_21627540 = query.getOrDefault("Version")
  valid_21627540 = validateParameter(valid_21627540, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627540 != nil:
    section.add "Version", valid_21627540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627541 = header.getOrDefault("X-Amz-Date")
  valid_21627541 = validateParameter(valid_21627541, JString, required = false,
                                   default = nil)
  if valid_21627541 != nil:
    section.add "X-Amz-Date", valid_21627541
  var valid_21627542 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627542 = validateParameter(valid_21627542, JString, required = false,
                                   default = nil)
  if valid_21627542 != nil:
    section.add "X-Amz-Security-Token", valid_21627542
  var valid_21627543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627543 = validateParameter(valid_21627543, JString, required = false,
                                   default = nil)
  if valid_21627543 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627543
  var valid_21627544 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627544 = validateParameter(valid_21627544, JString, required = false,
                                   default = nil)
  if valid_21627544 != nil:
    section.add "X-Amz-Algorithm", valid_21627544
  var valid_21627545 = header.getOrDefault("X-Amz-Signature")
  valid_21627545 = validateParameter(valid_21627545, JString, required = false,
                                   default = nil)
  if valid_21627545 != nil:
    section.add "X-Amz-Signature", valid_21627545
  var valid_21627546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627546 = validateParameter(valid_21627546, JString, required = false,
                                   default = nil)
  if valid_21627546 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627546
  var valid_21627547 = header.getOrDefault("X-Amz-Credential")
  valid_21627547 = validateParameter(valid_21627547, JString, required = false,
                                   default = nil)
  if valid_21627547 != nil:
    section.add "X-Amz-Credential", valid_21627547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627548: Call_GetRestoreDBClusterFromSnapshot_21627524;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ## 
  let valid = call_21627548.validator(path, query, header, formData, body, _)
  let scheme = call_21627548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627548.makeUrl(scheme.get, call_21627548.host, call_21627548.base,
                               call_21627548.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627548, uri, valid, _)

proc call*(call_21627549: Call_GetRestoreDBClusterFromSnapshot_21627524;
          Engine: string; DBClusterIdentifier: string; SnapshotIdentifier: string;
          AvailabilityZones: JsonNode = nil; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false;
          Action: string = "RestoreDBClusterFromSnapshot";
          DBSubnetGroupName: string = ""; KmsKeyId: string = "";
          EngineVersion: string = ""; Port: int = 0; Version: string = "2014-10-31"): Recallable =
  ## getRestoreDBClusterFromSnapshot
  ## <p>Creates a new cluster from a snapshot or cluster snapshot.</p> <p>If a snapshot is specified, the target cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a cluster snapshot is specified, the target cluster is created from the source cluster restore point with the same configuration as the original source DB cluster, except that the new cluster is created with the default security group.</p>
  ##   Engine: string (required)
  ##         : <p>The database engine to use for the new cluster.</p> <p>Default: The same as source.</p> <p>Constraint: Must be compatible with the engine of the source.</p>
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
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : <p>The name of the subnet group to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from a DB snapshot or cluster snapshot.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the snapshot or cluster snapshot in <code>SnapshotIdentifier</code> is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the snapshot or the cluster snapshot.</p> </li> <li> <p>If the snapshot or the cluster snapshot in <code>SnapshotIdentifier</code> is not encrypted, then the restored DB cluster is not encrypted.</p> </li> </ul>
  ##   EngineVersion: string
  ##                : The version of the database engine to use for the new cluster.
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>.</p> <p>Default: The same port as the original cluster.</p>
  ##   SnapshotIdentifier: string (required)
  ##                     : <p>The identifier for the snapshot or cluster snapshot to restore from.</p> <p>You can use either the name or the Amazon Resource Name (ARN) to specify a cluster snapshot. However, you can use only the ARN to specify a snapshot.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing snapshot.</p> </li> </ul>
  ##   Version: string (required)
  var query_21627550 = newJObject()
  add(query_21627550, "Engine", newJString(Engine))
  if AvailabilityZones != nil:
    query_21627550.add "AvailabilityZones", AvailabilityZones
  add(query_21627550, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_21627550.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_21627550.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_21627550.add "Tags", Tags
  add(query_21627550, "DeletionProtection", newJBool(DeletionProtection))
  add(query_21627550, "Action", newJString(Action))
  add(query_21627550, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21627550, "KmsKeyId", newJString(KmsKeyId))
  add(query_21627550, "EngineVersion", newJString(EngineVersion))
  add(query_21627550, "Port", newJInt(Port))
  add(query_21627550, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(query_21627550, "Version", newJString(Version))
  result = call_21627549.call(nil, query_21627550, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_21627524(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_21627525, base: "/",
    makeUrl: url_GetRestoreDBClusterFromSnapshot_21627526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_21627605 = ref object of OpenApiRestCall_21625418
proc url_PostRestoreDBClusterToPointInTime_21627607(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBClusterToPointInTime_21627606(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627608 = query.getOrDefault("Action")
  valid_21627608 = validateParameter(valid_21627608, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_21627608 != nil:
    section.add "Action", valid_21627608
  var valid_21627609 = query.getOrDefault("Version")
  valid_21627609 = validateParameter(valid_21627609, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627609 != nil:
    section.add "Version", valid_21627609
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627610 = header.getOrDefault("X-Amz-Date")
  valid_21627610 = validateParameter(valid_21627610, JString, required = false,
                                   default = nil)
  if valid_21627610 != nil:
    section.add "X-Amz-Date", valid_21627610
  var valid_21627611 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627611 = validateParameter(valid_21627611, JString, required = false,
                                   default = nil)
  if valid_21627611 != nil:
    section.add "X-Amz-Security-Token", valid_21627611
  var valid_21627612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627612 = validateParameter(valid_21627612, JString, required = false,
                                   default = nil)
  if valid_21627612 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627612
  var valid_21627613 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627613 = validateParameter(valid_21627613, JString, required = false,
                                   default = nil)
  if valid_21627613 != nil:
    section.add "X-Amz-Algorithm", valid_21627613
  var valid_21627614 = header.getOrDefault("X-Amz-Signature")
  valid_21627614 = validateParameter(valid_21627614, JString, required = false,
                                   default = nil)
  if valid_21627614 != nil:
    section.add "X-Amz-Signature", valid_21627614
  var valid_21627615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627615 = validateParameter(valid_21627615, JString, required = false,
                                   default = nil)
  if valid_21627615 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627615
  var valid_21627616 = header.getOrDefault("X-Amz-Credential")
  valid_21627616 = validateParameter(valid_21627616, JString, required = false,
                                   default = nil)
  if valid_21627616 != nil:
    section.add "X-Amz-Credential", valid_21627616
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   UseLatestRestorableTime: JBool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
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
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterIdentifier` field"
  var valid_21627617 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_21627617 = validateParameter(valid_21627617, JString, required = true,
                                   default = nil)
  if valid_21627617 != nil:
    section.add "SourceDBClusterIdentifier", valid_21627617
  var valid_21627618 = formData.getOrDefault("UseLatestRestorableTime")
  valid_21627618 = validateParameter(valid_21627618, JBool, required = false,
                                   default = nil)
  if valid_21627618 != nil:
    section.add "UseLatestRestorableTime", valid_21627618
  var valid_21627619 = formData.getOrDefault("Port")
  valid_21627619 = validateParameter(valid_21627619, JInt, required = false,
                                   default = nil)
  if valid_21627619 != nil:
    section.add "Port", valid_21627619
  var valid_21627620 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21627620 = validateParameter(valid_21627620, JArray, required = false,
                                   default = nil)
  if valid_21627620 != nil:
    section.add "VpcSecurityGroupIds", valid_21627620
  var valid_21627621 = formData.getOrDefault("RestoreToTime")
  valid_21627621 = validateParameter(valid_21627621, JString, required = false,
                                   default = nil)
  if valid_21627621 != nil:
    section.add "RestoreToTime", valid_21627621
  var valid_21627622 = formData.getOrDefault("Tags")
  valid_21627622 = validateParameter(valid_21627622, JArray, required = false,
                                   default = nil)
  if valid_21627622 != nil:
    section.add "Tags", valid_21627622
  var valid_21627623 = formData.getOrDefault("DeletionProtection")
  valid_21627623 = validateParameter(valid_21627623, JBool, required = false,
                                   default = nil)
  if valid_21627623 != nil:
    section.add "DeletionProtection", valid_21627623
  var valid_21627624 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627624 = validateParameter(valid_21627624, JString, required = false,
                                   default = nil)
  if valid_21627624 != nil:
    section.add "DBSubnetGroupName", valid_21627624
  var valid_21627625 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_21627625 = validateParameter(valid_21627625, JArray, required = false,
                                   default = nil)
  if valid_21627625 != nil:
    section.add "EnableCloudwatchLogsExports", valid_21627625
  var valid_21627626 = formData.getOrDefault("KmsKeyId")
  valid_21627626 = validateParameter(valid_21627626, JString, required = false,
                                   default = nil)
  if valid_21627626 != nil:
    section.add "KmsKeyId", valid_21627626
  var valid_21627627 = formData.getOrDefault("DBClusterIdentifier")
  valid_21627627 = validateParameter(valid_21627627, JString, required = true,
                                   default = nil)
  if valid_21627627 != nil:
    section.add "DBClusterIdentifier", valid_21627627
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627628: Call_PostRestoreDBClusterToPointInTime_21627605;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ## 
  let valid = call_21627628.validator(path, query, header, formData, body, _)
  let scheme = call_21627628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627628.makeUrl(scheme.get, call_21627628.host, call_21627628.base,
                               call_21627628.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627628, uri, valid, _)

proc call*(call_21627629: Call_PostRestoreDBClusterToPointInTime_21627605;
          SourceDBClusterIdentifier: string; DBClusterIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; RestoreToTime: string = "";
          Tags: JsonNode = nil; DeletionProtection: bool = false;
          DBSubnetGroupName: string = "";
          Action: string = "RestoreDBClusterToPointInTime";
          EnableCloudwatchLogsExports: JsonNode = nil; KmsKeyId: string = "";
          Version: string = "2014-10-31"): Recallable =
  ## postRestoreDBClusterToPointInTime
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   UseLatestRestorableTime: bool
  ##                          : <p>A value that is set to <code>true</code> to restore the cluster to the latest restorable backup time, and <code>false</code> otherwise. </p> <p>Default: <code>false</code> </p> <p>Constraints: Cannot be specified if the <code>RestoreToTime</code> parameter is provided.</p>
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
  var query_21627630 = newJObject()
  var formData_21627631 = newJObject()
  add(formData_21627631, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_21627631, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_21627631, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_21627631.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_21627631, "RestoreToTime", newJString(RestoreToTime))
  if Tags != nil:
    formData_21627631.add "Tags", Tags
  add(formData_21627631, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_21627631, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21627630, "Action", newJString(Action))
  if EnableCloudwatchLogsExports != nil:
    formData_21627631.add "EnableCloudwatchLogsExports",
                         EnableCloudwatchLogsExports
  add(formData_21627631, "KmsKeyId", newJString(KmsKeyId))
  add(formData_21627631, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21627630, "Version", newJString(Version))
  result = call_21627629.call(nil, query_21627630, nil, formData_21627631, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_21627605(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_21627606, base: "/",
    makeUrl: url_PostRestoreDBClusterToPointInTime_21627607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_21627579 = ref object of OpenApiRestCall_21625418
proc url_GetRestoreDBClusterToPointInTime_21627581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBClusterToPointInTime_21627580(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: JString
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   Port: JInt
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   SourceDBClusterIdentifier: JString (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627582 = query.getOrDefault("RestoreToTime")
  valid_21627582 = validateParameter(valid_21627582, JString, required = false,
                                   default = nil)
  if valid_21627582 != nil:
    section.add "RestoreToTime", valid_21627582
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_21627583 = query.getOrDefault("DBClusterIdentifier")
  valid_21627583 = validateParameter(valid_21627583, JString, required = true,
                                   default = nil)
  if valid_21627583 != nil:
    section.add "DBClusterIdentifier", valid_21627583
  var valid_21627584 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21627584 = validateParameter(valid_21627584, JArray, required = false,
                                   default = nil)
  if valid_21627584 != nil:
    section.add "VpcSecurityGroupIds", valid_21627584
  var valid_21627585 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_21627585 = validateParameter(valid_21627585, JArray, required = false,
                                   default = nil)
  if valid_21627585 != nil:
    section.add "EnableCloudwatchLogsExports", valid_21627585
  var valid_21627586 = query.getOrDefault("Tags")
  valid_21627586 = validateParameter(valid_21627586, JArray, required = false,
                                   default = nil)
  if valid_21627586 != nil:
    section.add "Tags", valid_21627586
  var valid_21627587 = query.getOrDefault("DeletionProtection")
  valid_21627587 = validateParameter(valid_21627587, JBool, required = false,
                                   default = nil)
  if valid_21627587 != nil:
    section.add "DeletionProtection", valid_21627587
  var valid_21627588 = query.getOrDefault("UseLatestRestorableTime")
  valid_21627588 = validateParameter(valid_21627588, JBool, required = false,
                                   default = nil)
  if valid_21627588 != nil:
    section.add "UseLatestRestorableTime", valid_21627588
  var valid_21627589 = query.getOrDefault("Action")
  valid_21627589 = validateParameter(valid_21627589, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_21627589 != nil:
    section.add "Action", valid_21627589
  var valid_21627590 = query.getOrDefault("DBSubnetGroupName")
  valid_21627590 = validateParameter(valid_21627590, JString, required = false,
                                   default = nil)
  if valid_21627590 != nil:
    section.add "DBSubnetGroupName", valid_21627590
  var valid_21627591 = query.getOrDefault("KmsKeyId")
  valid_21627591 = validateParameter(valid_21627591, JString, required = false,
                                   default = nil)
  if valid_21627591 != nil:
    section.add "KmsKeyId", valid_21627591
  var valid_21627592 = query.getOrDefault("Port")
  valid_21627592 = validateParameter(valid_21627592, JInt, required = false,
                                   default = nil)
  if valid_21627592 != nil:
    section.add "Port", valid_21627592
  var valid_21627593 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_21627593 = validateParameter(valid_21627593, JString, required = true,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "SourceDBClusterIdentifier", valid_21627593
  var valid_21627594 = query.getOrDefault("Version")
  valid_21627594 = validateParameter(valid_21627594, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627594 != nil:
    section.add "Version", valid_21627594
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627595 = header.getOrDefault("X-Amz-Date")
  valid_21627595 = validateParameter(valid_21627595, JString, required = false,
                                   default = nil)
  if valid_21627595 != nil:
    section.add "X-Amz-Date", valid_21627595
  var valid_21627596 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627596 = validateParameter(valid_21627596, JString, required = false,
                                   default = nil)
  if valid_21627596 != nil:
    section.add "X-Amz-Security-Token", valid_21627596
  var valid_21627597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627597 = validateParameter(valid_21627597, JString, required = false,
                                   default = nil)
  if valid_21627597 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627597
  var valid_21627598 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627598 = validateParameter(valid_21627598, JString, required = false,
                                   default = nil)
  if valid_21627598 != nil:
    section.add "X-Amz-Algorithm", valid_21627598
  var valid_21627599 = header.getOrDefault("X-Amz-Signature")
  valid_21627599 = validateParameter(valid_21627599, JString, required = false,
                                   default = nil)
  if valid_21627599 != nil:
    section.add "X-Amz-Signature", valid_21627599
  var valid_21627600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627600 = validateParameter(valid_21627600, JString, required = false,
                                   default = nil)
  if valid_21627600 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627600
  var valid_21627601 = header.getOrDefault("X-Amz-Credential")
  valid_21627601 = validateParameter(valid_21627601, JString, required = false,
                                   default = nil)
  if valid_21627601 != nil:
    section.add "X-Amz-Credential", valid_21627601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627602: Call_GetRestoreDBClusterToPointInTime_21627579;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Restores a cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target cluster is created from the source cluster with the same configuration as the original cluster, except that the new cluster is created with the default security group. 
  ## 
  let valid = call_21627602.validator(path, query, header, formData, body, _)
  let scheme = call_21627602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627602.makeUrl(scheme.get, call_21627602.host, call_21627602.base,
                               call_21627602.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627602, uri, valid, _)

proc call*(call_21627603: Call_GetRestoreDBClusterToPointInTime_21627579;
          DBClusterIdentifier: string; SourceDBClusterIdentifier: string;
          RestoreToTime: string = ""; VpcSecurityGroupIds: JsonNode = nil;
          EnableCloudwatchLogsExports: JsonNode = nil; Tags: JsonNode = nil;
          DeletionProtection: bool = false; UseLatestRestorableTime: bool = false;
          Action: string = "RestoreDBClusterToPointInTime";
          DBSubnetGroupName: string = ""; KmsKeyId: string = ""; Port: int = 0;
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
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##                    : <p>The subnet group name to use for the new cluster.</p> <p>Constraints: If provided, must match the name of an existing <code>DBSubnetGroup</code>.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   KmsKeyId: string
  ##           : <p>The AWS KMS key identifier to use when restoring an encrypted cluster from an encrypted cluster.</p> <p>The AWS KMS key identifier is the Amazon Resource Name (ARN) for the AWS KMS encryption key. If you are restoring a cluster with the same AWS account that owns the AWS KMS encryption key used to encrypt the new cluster, then you can use the AWS KMS key alias instead of the ARN for the AWS KMS encryption key.</p> <p>You can restore to a new cluster and encrypt the new cluster with an AWS KMS key that is different from the AWS KMS key used to encrypt the source cluster. The new DB cluster is encrypted with the AWS KMS key identified by the <code>KmsKeyId</code> parameter.</p> <p>If you do not specify a value for the <code>KmsKeyId</code> parameter, then the following occurs:</p> <ul> <li> <p>If the cluster is encrypted, then the restored cluster is encrypted using the AWS KMS key that was used to encrypt the source cluster.</p> </li> <li> <p>If the cluster is not encrypted, then the restored cluster is not encrypted.</p> </li> </ul> <p>If <code>DBClusterIdentifier</code> refers to a cluster that is not encrypted, then the restore request is rejected.</p>
  ##   Port: int
  ##       : <p>The port number on which the new cluster accepts connections.</p> <p>Constraints: Must be a value from <code>1150</code> to <code>65535</code>. </p> <p>Default: The default port for the engine.</p>
  ##   SourceDBClusterIdentifier: string (required)
  ##                            : <p>The identifier of the source cluster from which to restore.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  ##   Version: string (required)
  var query_21627604 = newJObject()
  add(query_21627604, "RestoreToTime", newJString(RestoreToTime))
  add(query_21627604, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_21627604.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_21627604.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_21627604.add "Tags", Tags
  add(query_21627604, "DeletionProtection", newJBool(DeletionProtection))
  add(query_21627604, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_21627604, "Action", newJString(Action))
  add(query_21627604, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21627604, "KmsKeyId", newJString(KmsKeyId))
  add(query_21627604, "Port", newJInt(Port))
  add(query_21627604, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_21627604, "Version", newJString(Version))
  result = call_21627603.call(nil, query_21627604, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_21627579(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_21627580, base: "/",
    makeUrl: url_GetRestoreDBClusterToPointInTime_21627581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_21627648 = ref object of OpenApiRestCall_21625418
proc url_PostStartDBCluster_21627650(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostStartDBCluster_21627649(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627651 = query.getOrDefault("Action")
  valid_21627651 = validateParameter(valid_21627651, JString, required = true,
                                   default = newJString("StartDBCluster"))
  if valid_21627651 != nil:
    section.add "Action", valid_21627651
  var valid_21627652 = query.getOrDefault("Version")
  valid_21627652 = validateParameter(valid_21627652, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627652 != nil:
    section.add "Version", valid_21627652
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627653 = header.getOrDefault("X-Amz-Date")
  valid_21627653 = validateParameter(valid_21627653, JString, required = false,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "X-Amz-Date", valid_21627653
  var valid_21627654 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627654 = validateParameter(valid_21627654, JString, required = false,
                                   default = nil)
  if valid_21627654 != nil:
    section.add "X-Amz-Security-Token", valid_21627654
  var valid_21627655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627655 = validateParameter(valid_21627655, JString, required = false,
                                   default = nil)
  if valid_21627655 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627655
  var valid_21627656 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627656 = validateParameter(valid_21627656, JString, required = false,
                                   default = nil)
  if valid_21627656 != nil:
    section.add "X-Amz-Algorithm", valid_21627656
  var valid_21627657 = header.getOrDefault("X-Amz-Signature")
  valid_21627657 = validateParameter(valid_21627657, JString, required = false,
                                   default = nil)
  if valid_21627657 != nil:
    section.add "X-Amz-Signature", valid_21627657
  var valid_21627658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627658 = validateParameter(valid_21627658, JString, required = false,
                                   default = nil)
  if valid_21627658 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627658
  var valid_21627659 = header.getOrDefault("X-Amz-Credential")
  valid_21627659 = validateParameter(valid_21627659, JString, required = false,
                                   default = nil)
  if valid_21627659 != nil:
    section.add "X-Amz-Credential", valid_21627659
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_21627660 = formData.getOrDefault("DBClusterIdentifier")
  valid_21627660 = validateParameter(valid_21627660, JString, required = true,
                                   default = nil)
  if valid_21627660 != nil:
    section.add "DBClusterIdentifier", valid_21627660
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627661: Call_PostStartDBCluster_21627648; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_21627661.validator(path, query, header, formData, body, _)
  let scheme = call_21627661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627661.makeUrl(scheme.get, call_21627661.host, call_21627661.base,
                               call_21627661.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627661, uri, valid, _)

proc call*(call_21627662: Call_PostStartDBCluster_21627648;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_21627663 = newJObject()
  var formData_21627664 = newJObject()
  add(query_21627663, "Action", newJString(Action))
  add(formData_21627664, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21627663, "Version", newJString(Version))
  result = call_21627662.call(nil, query_21627663, nil, formData_21627664, nil)

var postStartDBCluster* = Call_PostStartDBCluster_21627648(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_21627649, base: "/",
    makeUrl: url_PostStartDBCluster_21627650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_21627632 = ref object of OpenApiRestCall_21625418
proc url_GetStartDBCluster_21627634(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStartDBCluster_21627633(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627635 = query.getOrDefault("DBClusterIdentifier")
  valid_21627635 = validateParameter(valid_21627635, JString, required = true,
                                   default = nil)
  if valid_21627635 != nil:
    section.add "DBClusterIdentifier", valid_21627635
  var valid_21627636 = query.getOrDefault("Action")
  valid_21627636 = validateParameter(valid_21627636, JString, required = true,
                                   default = newJString("StartDBCluster"))
  if valid_21627636 != nil:
    section.add "Action", valid_21627636
  var valid_21627637 = query.getOrDefault("Version")
  valid_21627637 = validateParameter(valid_21627637, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627637 != nil:
    section.add "Version", valid_21627637
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627638 = header.getOrDefault("X-Amz-Date")
  valid_21627638 = validateParameter(valid_21627638, JString, required = false,
                                   default = nil)
  if valid_21627638 != nil:
    section.add "X-Amz-Date", valid_21627638
  var valid_21627639 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627639 = validateParameter(valid_21627639, JString, required = false,
                                   default = nil)
  if valid_21627639 != nil:
    section.add "X-Amz-Security-Token", valid_21627639
  var valid_21627640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627640 = validateParameter(valid_21627640, JString, required = false,
                                   default = nil)
  if valid_21627640 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627640
  var valid_21627641 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627641 = validateParameter(valid_21627641, JString, required = false,
                                   default = nil)
  if valid_21627641 != nil:
    section.add "X-Amz-Algorithm", valid_21627641
  var valid_21627642 = header.getOrDefault("X-Amz-Signature")
  valid_21627642 = validateParameter(valid_21627642, JString, required = false,
                                   default = nil)
  if valid_21627642 != nil:
    section.add "X-Amz-Signature", valid_21627642
  var valid_21627643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627643 = validateParameter(valid_21627643, JString, required = false,
                                   default = nil)
  if valid_21627643 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627643
  var valid_21627644 = header.getOrDefault("X-Amz-Credential")
  valid_21627644 = validateParameter(valid_21627644, JString, required = false,
                                   default = nil)
  if valid_21627644 != nil:
    section.add "X-Amz-Credential", valid_21627644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627645: Call_GetStartDBCluster_21627632; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_21627645.validator(path, query, header, formData, body, _)
  let scheme = call_21627645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627645.makeUrl(scheme.get, call_21627645.host, call_21627645.base,
                               call_21627645.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627645, uri, valid, _)

proc call*(call_21627646: Call_GetStartDBCluster_21627632;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627647 = newJObject()
  add(query_21627647, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21627647, "Action", newJString(Action))
  add(query_21627647, "Version", newJString(Version))
  result = call_21627646.call(nil, query_21627647, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_21627632(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_21627633,
    base: "/", makeUrl: url_GetStartDBCluster_21627634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_21627681 = ref object of OpenApiRestCall_21625418
proc url_PostStopDBCluster_21627683(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostStopDBCluster_21627682(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627684 = query.getOrDefault("Action")
  valid_21627684 = validateParameter(valid_21627684, JString, required = true,
                                   default = newJString("StopDBCluster"))
  if valid_21627684 != nil:
    section.add "Action", valid_21627684
  var valid_21627685 = query.getOrDefault("Version")
  valid_21627685 = validateParameter(valid_21627685, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627685 != nil:
    section.add "Version", valid_21627685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627686 = header.getOrDefault("X-Amz-Date")
  valid_21627686 = validateParameter(valid_21627686, JString, required = false,
                                   default = nil)
  if valid_21627686 != nil:
    section.add "X-Amz-Date", valid_21627686
  var valid_21627687 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627687 = validateParameter(valid_21627687, JString, required = false,
                                   default = nil)
  if valid_21627687 != nil:
    section.add "X-Amz-Security-Token", valid_21627687
  var valid_21627688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627688 = validateParameter(valid_21627688, JString, required = false,
                                   default = nil)
  if valid_21627688 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627688
  var valid_21627689 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627689 = validateParameter(valid_21627689, JString, required = false,
                                   default = nil)
  if valid_21627689 != nil:
    section.add "X-Amz-Algorithm", valid_21627689
  var valid_21627690 = header.getOrDefault("X-Amz-Signature")
  valid_21627690 = validateParameter(valid_21627690, JString, required = false,
                                   default = nil)
  if valid_21627690 != nil:
    section.add "X-Amz-Signature", valid_21627690
  var valid_21627691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627691 = validateParameter(valid_21627691, JString, required = false,
                                   default = nil)
  if valid_21627691 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627691
  var valid_21627692 = header.getOrDefault("X-Amz-Credential")
  valid_21627692 = validateParameter(valid_21627692, JString, required = false,
                                   default = nil)
  if valid_21627692 != nil:
    section.add "X-Amz-Credential", valid_21627692
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_21627693 = formData.getOrDefault("DBClusterIdentifier")
  valid_21627693 = validateParameter(valid_21627693, JString, required = true,
                                   default = nil)
  if valid_21627693 != nil:
    section.add "DBClusterIdentifier", valid_21627693
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627694: Call_PostStopDBCluster_21627681; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_21627694.validator(path, query, header, formData, body, _)
  let scheme = call_21627694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627694.makeUrl(scheme.get, call_21627694.host, call_21627694.base,
                               call_21627694.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627694, uri, valid, _)

proc call*(call_21627695: Call_PostStopDBCluster_21627681;
          DBClusterIdentifier: string; Action: string = "StopDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_21627696 = newJObject()
  var formData_21627697 = newJObject()
  add(query_21627696, "Action", newJString(Action))
  add(formData_21627697, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21627696, "Version", newJString(Version))
  result = call_21627695.call(nil, query_21627696, nil, formData_21627697, nil)

var postStopDBCluster* = Call_PostStopDBCluster_21627681(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_21627682,
    base: "/", makeUrl: url_PostStopDBCluster_21627683,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_21627665 = ref object of OpenApiRestCall_21625418
proc url_GetStopDBCluster_21627667(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetStopDBCluster_21627666(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627668 = query.getOrDefault("DBClusterIdentifier")
  valid_21627668 = validateParameter(valid_21627668, JString, required = true,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "DBClusterIdentifier", valid_21627668
  var valid_21627669 = query.getOrDefault("Action")
  valid_21627669 = validateParameter(valid_21627669, JString, required = true,
                                   default = newJString("StopDBCluster"))
  if valid_21627669 != nil:
    section.add "Action", valid_21627669
  var valid_21627670 = query.getOrDefault("Version")
  valid_21627670 = validateParameter(valid_21627670, JString, required = true,
                                   default = newJString("2014-10-31"))
  if valid_21627670 != nil:
    section.add "Version", valid_21627670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627671 = header.getOrDefault("X-Amz-Date")
  valid_21627671 = validateParameter(valid_21627671, JString, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "X-Amz-Date", valid_21627671
  var valid_21627672 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627672 = validateParameter(valid_21627672, JString, required = false,
                                   default = nil)
  if valid_21627672 != nil:
    section.add "X-Amz-Security-Token", valid_21627672
  var valid_21627673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627673 = validateParameter(valid_21627673, JString, required = false,
                                   default = nil)
  if valid_21627673 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627673
  var valid_21627674 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627674 = validateParameter(valid_21627674, JString, required = false,
                                   default = nil)
  if valid_21627674 != nil:
    section.add "X-Amz-Algorithm", valid_21627674
  var valid_21627675 = header.getOrDefault("X-Amz-Signature")
  valid_21627675 = validateParameter(valid_21627675, JString, required = false,
                                   default = nil)
  if valid_21627675 != nil:
    section.add "X-Amz-Signature", valid_21627675
  var valid_21627676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627676 = validateParameter(valid_21627676, JString, required = false,
                                   default = nil)
  if valid_21627676 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627676
  var valid_21627677 = header.getOrDefault("X-Amz-Credential")
  valid_21627677 = validateParameter(valid_21627677, JString, required = false,
                                   default = nil)
  if valid_21627677 != nil:
    section.add "X-Amz-Credential", valid_21627677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627678: Call_GetStopDBCluster_21627665; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_21627678.validator(path, query, header, formData, body, _)
  let scheme = call_21627678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627678.makeUrl(scheme.get, call_21627678.host, call_21627678.base,
                               call_21627678.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627678, uri, valid, _)

proc call*(call_21627679: Call_GetStopDBCluster_21627665;
          DBClusterIdentifier: string; Action: string = "StopDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627680 = newJObject()
  add(query_21627680, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_21627680, "Action", newJString(Action))
  add(query_21627680, "Version", newJString(Version))
  result = call_21627679.call(nil, query_21627680, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_21627665(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_21627666,
    base: "/", makeUrl: url_GetStopDBCluster_21627667,
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
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}
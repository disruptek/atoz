
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

  OpenApiRestCall_601373 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601373](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601373): Option[Scheme] {.used.} =
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
  Call_PostAddTagsToResource_601983 = ref object of OpenApiRestCall_601373
proc url_PostAddTagsToResource_601985(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTagsToResource_601984(path: JsonNode; query: JsonNode;
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
  var valid_601986 = query.getOrDefault("Action")
  valid_601986 = validateParameter(valid_601986, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_601986 != nil:
    section.add "Action", valid_601986
  var valid_601987 = query.getOrDefault("Version")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601987 != nil:
    section.add "Version", valid_601987
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601988 = header.getOrDefault("X-Amz-Signature")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Signature", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Content-Sha256", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Date")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Date", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Credential")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Credential", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Security-Token")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Security-Token", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Algorithm")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Algorithm", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-SignedHeaders", valid_601994
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_601995 = formData.getOrDefault("Tags")
  valid_601995 = validateParameter(valid_601995, JArray, required = true, default = nil)
  if valid_601995 != nil:
    section.add "Tags", valid_601995
  var valid_601996 = formData.getOrDefault("ResourceName")
  valid_601996 = validateParameter(valid_601996, JString, required = true,
                                 default = nil)
  if valid_601996 != nil:
    section.add "ResourceName", valid_601996
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601997: Call_PostAddTagsToResource_601983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_601997.validator(path, query, header, formData, body)
  let scheme = call_601997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601997.url(scheme.get, call_601997.host, call_601997.base,
                         call_601997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601997, url, valid)

proc call*(call_601998: Call_PostAddTagsToResource_601983; Tags: JsonNode;
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
  var query_601999 = newJObject()
  var formData_602000 = newJObject()
  add(query_601999, "Action", newJString(Action))
  if Tags != nil:
    formData_602000.add "Tags", Tags
  add(query_601999, "Version", newJString(Version))
  add(formData_602000, "ResourceName", newJString(ResourceName))
  result = call_601998.call(nil, query_601999, nil, formData_602000, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_601983(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_601984, base: "/",
    url: url_PostAddTagsToResource_601985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_601711 = ref object of OpenApiRestCall_601373
proc url_GetAddTagsToResource_601713(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddTagsToResource_601712(path: JsonNode; query: JsonNode;
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
  var valid_601825 = query.getOrDefault("Tags")
  valid_601825 = validateParameter(valid_601825, JArray, required = true, default = nil)
  if valid_601825 != nil:
    section.add "Tags", valid_601825
  var valid_601826 = query.getOrDefault("ResourceName")
  valid_601826 = validateParameter(valid_601826, JString, required = true,
                                 default = nil)
  if valid_601826 != nil:
    section.add "ResourceName", valid_601826
  var valid_601840 = query.getOrDefault("Action")
  valid_601840 = validateParameter(valid_601840, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_601840 != nil:
    section.add "Action", valid_601840
  var valid_601841 = query.getOrDefault("Version")
  valid_601841 = validateParameter(valid_601841, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_601841 != nil:
    section.add "Version", valid_601841
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601842 = header.getOrDefault("X-Amz-Signature")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Signature", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Content-Sha256", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Date")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Date", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Credential")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Credential", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Security-Token")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Security-Token", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Algorithm")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Algorithm", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-SignedHeaders", valid_601848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601871: Call_GetAddTagsToResource_601711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_601871.validator(path, query, header, formData, body)
  let scheme = call_601871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601871.url(scheme.get, call_601871.host, call_601871.base,
                         call_601871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601871, url, valid)

proc call*(call_601942: Call_GetAddTagsToResource_601711; Tags: JsonNode;
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
  var query_601943 = newJObject()
  if Tags != nil:
    query_601943.add "Tags", Tags
  add(query_601943, "ResourceName", newJString(ResourceName))
  add(query_601943, "Action", newJString(Action))
  add(query_601943, "Version", newJString(Version))
  result = call_601942.call(nil, query_601943, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_601711(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_601712, base: "/",
    url: url_GetAddTagsToResource_601713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_602019 = ref object of OpenApiRestCall_601373
proc url_PostApplyPendingMaintenanceAction_602021(protocol: Scheme; host: string;
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

proc validate_PostApplyPendingMaintenanceAction_602020(path: JsonNode;
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
  var valid_602022 = query.getOrDefault("Action")
  valid_602022 = validateParameter(valid_602022, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_602022 != nil:
    section.add "Action", valid_602022
  var valid_602023 = query.getOrDefault("Version")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602023 != nil:
    section.add "Version", valid_602023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602024 = header.getOrDefault("X-Amz-Signature")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Signature", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Content-Sha256", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Date")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Date", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Credential")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Credential", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Security-Token")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Security-Token", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Algorithm")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Algorithm", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-SignedHeaders", valid_602030
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
  var valid_602031 = formData.getOrDefault("ResourceIdentifier")
  valid_602031 = validateParameter(valid_602031, JString, required = true,
                                 default = nil)
  if valid_602031 != nil:
    section.add "ResourceIdentifier", valid_602031
  var valid_602032 = formData.getOrDefault("ApplyAction")
  valid_602032 = validateParameter(valid_602032, JString, required = true,
                                 default = nil)
  if valid_602032 != nil:
    section.add "ApplyAction", valid_602032
  var valid_602033 = formData.getOrDefault("OptInType")
  valid_602033 = validateParameter(valid_602033, JString, required = true,
                                 default = nil)
  if valid_602033 != nil:
    section.add "OptInType", valid_602033
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602034: Call_PostApplyPendingMaintenanceAction_602019;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_602034.validator(path, query, header, formData, body)
  let scheme = call_602034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602034.url(scheme.get, call_602034.host, call_602034.base,
                         call_602034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602034, url, valid)

proc call*(call_602035: Call_PostApplyPendingMaintenanceAction_602019;
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
  var query_602036 = newJObject()
  var formData_602037 = newJObject()
  add(formData_602037, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_602037, "ApplyAction", newJString(ApplyAction))
  add(query_602036, "Action", newJString(Action))
  add(formData_602037, "OptInType", newJString(OptInType))
  add(query_602036, "Version", newJString(Version))
  result = call_602035.call(nil, query_602036, nil, formData_602037, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_602019(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_602020, base: "/",
    url: url_PostApplyPendingMaintenanceAction_602021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_602001 = ref object of OpenApiRestCall_601373
proc url_GetApplyPendingMaintenanceAction_602003(protocol: Scheme; host: string;
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

proc validate_GetApplyPendingMaintenanceAction_602002(path: JsonNode;
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
  var valid_602004 = query.getOrDefault("ResourceIdentifier")
  valid_602004 = validateParameter(valid_602004, JString, required = true,
                                 default = nil)
  if valid_602004 != nil:
    section.add "ResourceIdentifier", valid_602004
  var valid_602005 = query.getOrDefault("ApplyAction")
  valid_602005 = validateParameter(valid_602005, JString, required = true,
                                 default = nil)
  if valid_602005 != nil:
    section.add "ApplyAction", valid_602005
  var valid_602006 = query.getOrDefault("Action")
  valid_602006 = validateParameter(valid_602006, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_602006 != nil:
    section.add "Action", valid_602006
  var valid_602007 = query.getOrDefault("OptInType")
  valid_602007 = validateParameter(valid_602007, JString, required = true,
                                 default = nil)
  if valid_602007 != nil:
    section.add "OptInType", valid_602007
  var valid_602008 = query.getOrDefault("Version")
  valid_602008 = validateParameter(valid_602008, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602008 != nil:
    section.add "Version", valid_602008
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602009 = header.getOrDefault("X-Amz-Signature")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Signature", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Content-Sha256", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Date")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Date", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Credential")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Credential", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Security-Token")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Security-Token", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Algorithm")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Algorithm", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-SignedHeaders", valid_602015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602016: Call_GetApplyPendingMaintenanceAction_602001;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_602016.validator(path, query, header, formData, body)
  let scheme = call_602016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602016.url(scheme.get, call_602016.host, call_602016.base,
                         call_602016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602016, url, valid)

proc call*(call_602017: Call_GetApplyPendingMaintenanceAction_602001;
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
  var query_602018 = newJObject()
  add(query_602018, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_602018, "ApplyAction", newJString(ApplyAction))
  add(query_602018, "Action", newJString(Action))
  add(query_602018, "OptInType", newJString(OptInType))
  add(query_602018, "Version", newJString(Version))
  result = call_602017.call(nil, query_602018, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_602001(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_602002, base: "/",
    url: url_GetApplyPendingMaintenanceAction_602003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_602057 = ref object of OpenApiRestCall_601373
proc url_PostCopyDBClusterParameterGroup_602059(protocol: Scheme; host: string;
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

proc validate_PostCopyDBClusterParameterGroup_602058(path: JsonNode;
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
  var valid_602060 = query.getOrDefault("Action")
  valid_602060 = validateParameter(valid_602060, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_602060 != nil:
    section.add "Action", valid_602060
  var valid_602061 = query.getOrDefault("Version")
  valid_602061 = validateParameter(valid_602061, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602061 != nil:
    section.add "Version", valid_602061
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602062 = header.getOrDefault("X-Amz-Signature")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Signature", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Content-Sha256", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Date")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Date", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Credential")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Credential", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Security-Token")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Security-Token", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Algorithm")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Algorithm", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-SignedHeaders", valid_602068
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
  var valid_602069 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_602069 = validateParameter(valid_602069, JString, required = true,
                                 default = nil)
  if valid_602069 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_602069
  var valid_602070 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_602070 = validateParameter(valid_602070, JString, required = true,
                                 default = nil)
  if valid_602070 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_602070
  var valid_602071 = formData.getOrDefault("Tags")
  valid_602071 = validateParameter(valid_602071, JArray, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "Tags", valid_602071
  var valid_602072 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_602072 = validateParameter(valid_602072, JString, required = true,
                                 default = nil)
  if valid_602072 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_602072
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_PostCopyDBClusterParameterGroup_602057;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602073, url, valid)

proc call*(call_602074: Call_PostCopyDBClusterParameterGroup_602057;
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
  var query_602075 = newJObject()
  var formData_602076 = newJObject()
  add(formData_602076, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(formData_602076, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_602075, "Action", newJString(Action))
  if Tags != nil:
    formData_602076.add "Tags", Tags
  add(query_602075, "Version", newJString(Version))
  add(formData_602076, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  result = call_602074.call(nil, query_602075, nil, formData_602076, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_602057(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_602058, base: "/",
    url: url_PostCopyDBClusterParameterGroup_602059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_602038 = ref object of OpenApiRestCall_601373
proc url_GetCopyDBClusterParameterGroup_602040(protocol: Scheme; host: string;
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

proc validate_GetCopyDBClusterParameterGroup_602039(path: JsonNode;
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
  var valid_602041 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_602041 = validateParameter(valid_602041, JString, required = true,
                                 default = nil)
  if valid_602041 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_602041
  var valid_602042 = query.getOrDefault("Tags")
  valid_602042 = validateParameter(valid_602042, JArray, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "Tags", valid_602042
  var valid_602043 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_602043 = validateParameter(valid_602043, JString, required = true,
                                 default = nil)
  if valid_602043 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_602043
  var valid_602044 = query.getOrDefault("Action")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_602044 != nil:
    section.add "Action", valid_602044
  var valid_602045 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_602045 = validateParameter(valid_602045, JString, required = true,
                                 default = nil)
  if valid_602045 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_602045
  var valid_602046 = query.getOrDefault("Version")
  valid_602046 = validateParameter(valid_602046, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602046 != nil:
    section.add "Version", valid_602046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602047 = header.getOrDefault("X-Amz-Signature")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Signature", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Content-Sha256", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Date")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Date", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Credential")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Credential", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Security-Token")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Security-Token", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Algorithm")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Algorithm", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-SignedHeaders", valid_602053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602054: Call_GetCopyDBClusterParameterGroup_602038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_602054.validator(path, query, header, formData, body)
  let scheme = call_602054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602054.url(scheme.get, call_602054.host, call_602054.base,
                         call_602054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602054, url, valid)

proc call*(call_602055: Call_GetCopyDBClusterParameterGroup_602038;
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
  var query_602056 = newJObject()
  add(query_602056, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    query_602056.add "Tags", Tags
  add(query_602056, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_602056, "Action", newJString(Action))
  add(query_602056, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(query_602056, "Version", newJString(Version))
  result = call_602055.call(nil, query_602056, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_602038(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_602039, base: "/",
    url: url_GetCopyDBClusterParameterGroup_602040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_602098 = ref object of OpenApiRestCall_601373
proc url_PostCopyDBClusterSnapshot_602100(protocol: Scheme; host: string;
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

proc validate_PostCopyDBClusterSnapshot_602099(path: JsonNode; query: JsonNode;
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
  var valid_602101 = query.getOrDefault("Action")
  valid_602101 = validateParameter(valid_602101, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_602101 != nil:
    section.add "Action", valid_602101
  var valid_602102 = query.getOrDefault("Version")
  valid_602102 = validateParameter(valid_602102, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602102 != nil:
    section.add "Version", valid_602102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602103 = header.getOrDefault("X-Amz-Signature")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Signature", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Content-Sha256", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Date")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Date", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Credential")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Credential", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Security-Token")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Security-Token", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Algorithm")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Algorithm", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-SignedHeaders", valid_602109
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
  var valid_602110 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_602110 = validateParameter(valid_602110, JString, required = true,
                                 default = nil)
  if valid_602110 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_602110
  var valid_602111 = formData.getOrDefault("KmsKeyId")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "KmsKeyId", valid_602111
  var valid_602112 = formData.getOrDefault("PreSignedUrl")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "PreSignedUrl", valid_602112
  var valid_602113 = formData.getOrDefault("CopyTags")
  valid_602113 = validateParameter(valid_602113, JBool, required = false, default = nil)
  if valid_602113 != nil:
    section.add "CopyTags", valid_602113
  var valid_602114 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_602114 = validateParameter(valid_602114, JString, required = true,
                                 default = nil)
  if valid_602114 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_602114
  var valid_602115 = formData.getOrDefault("Tags")
  valid_602115 = validateParameter(valid_602115, JArray, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "Tags", valid_602115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602116: Call_PostCopyDBClusterSnapshot_602098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_602116.validator(path, query, header, formData, body)
  let scheme = call_602116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602116.url(scheme.get, call_602116.host, call_602116.base,
                         call_602116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602116, url, valid)

proc call*(call_602117: Call_PostCopyDBClusterSnapshot_602098;
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
  var query_602118 = newJObject()
  var formData_602119 = newJObject()
  add(formData_602119, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_602119, "KmsKeyId", newJString(KmsKeyId))
  add(formData_602119, "PreSignedUrl", newJString(PreSignedUrl))
  add(formData_602119, "CopyTags", newJBool(CopyTags))
  add(formData_602119, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_602118, "Action", newJString(Action))
  if Tags != nil:
    formData_602119.add "Tags", Tags
  add(query_602118, "Version", newJString(Version))
  result = call_602117.call(nil, query_602118, nil, formData_602119, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_602098(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_602099, base: "/",
    url: url_PostCopyDBClusterSnapshot_602100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_602077 = ref object of OpenApiRestCall_601373
proc url_GetCopyDBClusterSnapshot_602079(protocol: Scheme; host: string;
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

proc validate_GetCopyDBClusterSnapshot_602078(path: JsonNode; query: JsonNode;
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
  var valid_602080 = query.getOrDefault("Tags")
  valid_602080 = validateParameter(valid_602080, JArray, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "Tags", valid_602080
  var valid_602081 = query.getOrDefault("KmsKeyId")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "KmsKeyId", valid_602081
  var valid_602082 = query.getOrDefault("PreSignedUrl")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "PreSignedUrl", valid_602082
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_602083 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_602083
  var valid_602084 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_602084 = validateParameter(valid_602084, JString, required = true,
                                 default = nil)
  if valid_602084 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_602084
  var valid_602085 = query.getOrDefault("Action")
  valid_602085 = validateParameter(valid_602085, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_602085 != nil:
    section.add "Action", valid_602085
  var valid_602086 = query.getOrDefault("CopyTags")
  valid_602086 = validateParameter(valid_602086, JBool, required = false, default = nil)
  if valid_602086 != nil:
    section.add "CopyTags", valid_602086
  var valid_602087 = query.getOrDefault("Version")
  valid_602087 = validateParameter(valid_602087, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602087 != nil:
    section.add "Version", valid_602087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602088 = header.getOrDefault("X-Amz-Signature")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Signature", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Content-Sha256", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Date")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Date", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Credential")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Credential", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Security-Token")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Security-Token", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Algorithm")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Algorithm", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-SignedHeaders", valid_602094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602095: Call_GetCopyDBClusterSnapshot_602077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_602095.validator(path, query, header, formData, body)
  let scheme = call_602095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602095.url(scheme.get, call_602095.host, call_602095.base,
                         call_602095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602095, url, valid)

proc call*(call_602096: Call_GetCopyDBClusterSnapshot_602077;
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
  var query_602097 = newJObject()
  if Tags != nil:
    query_602097.add "Tags", Tags
  add(query_602097, "KmsKeyId", newJString(KmsKeyId))
  add(query_602097, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_602097, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_602097, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_602097, "Action", newJString(Action))
  add(query_602097, "CopyTags", newJBool(CopyTags))
  add(query_602097, "Version", newJString(Version))
  result = call_602096.call(nil, query_602097, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_602077(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_602078, base: "/",
    url: url_GetCopyDBClusterSnapshot_602079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_602153 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBCluster_602155(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBCluster_602154(path: JsonNode; query: JsonNode;
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
  var valid_602156 = query.getOrDefault("Action")
  valid_602156 = validateParameter(valid_602156, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_602156 != nil:
    section.add "Action", valid_602156
  var valid_602157 = query.getOrDefault("Version")
  valid_602157 = validateParameter(valid_602157, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602157 != nil:
    section.add "Version", valid_602157
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602158 = header.getOrDefault("X-Amz-Signature")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Signature", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Content-Sha256", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Date")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Date", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Credential")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Credential", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Security-Token")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Security-Token", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Algorithm")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Algorithm", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-SignedHeaders", valid_602164
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
  var valid_602165 = formData.getOrDefault("Port")
  valid_602165 = validateParameter(valid_602165, JInt, required = false, default = nil)
  if valid_602165 != nil:
    section.add "Port", valid_602165
  var valid_602166 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "PreferredMaintenanceWindow", valid_602166
  var valid_602167 = formData.getOrDefault("PreferredBackupWindow")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "PreferredBackupWindow", valid_602167
  assert formData != nil, "formData argument is necessary due to required `MasterUserPassword` field"
  var valid_602168 = formData.getOrDefault("MasterUserPassword")
  valid_602168 = validateParameter(valid_602168, JString, required = true,
                                 default = nil)
  if valid_602168 != nil:
    section.add "MasterUserPassword", valid_602168
  var valid_602169 = formData.getOrDefault("MasterUsername")
  valid_602169 = validateParameter(valid_602169, JString, required = true,
                                 default = nil)
  if valid_602169 != nil:
    section.add "MasterUsername", valid_602169
  var valid_602170 = formData.getOrDefault("EngineVersion")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "EngineVersion", valid_602170
  var valid_602171 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602171 = validateParameter(valid_602171, JArray, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "VpcSecurityGroupIds", valid_602171
  var valid_602172 = formData.getOrDefault("AvailabilityZones")
  valid_602172 = validateParameter(valid_602172, JArray, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "AvailabilityZones", valid_602172
  var valid_602173 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602173 = validateParameter(valid_602173, JInt, required = false, default = nil)
  if valid_602173 != nil:
    section.add "BackupRetentionPeriod", valid_602173
  var valid_602174 = formData.getOrDefault("Engine")
  valid_602174 = validateParameter(valid_602174, JString, required = true,
                                 default = nil)
  if valid_602174 != nil:
    section.add "Engine", valid_602174
  var valid_602175 = formData.getOrDefault("KmsKeyId")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "KmsKeyId", valid_602175
  var valid_602176 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_602176 = validateParameter(valid_602176, JArray, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "EnableCloudwatchLogsExports", valid_602176
  var valid_602177 = formData.getOrDefault("Tags")
  valid_602177 = validateParameter(valid_602177, JArray, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "Tags", valid_602177
  var valid_602178 = formData.getOrDefault("DBSubnetGroupName")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "DBSubnetGroupName", valid_602178
  var valid_602179 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "DBClusterParameterGroupName", valid_602179
  var valid_602180 = formData.getOrDefault("StorageEncrypted")
  valid_602180 = validateParameter(valid_602180, JBool, required = false, default = nil)
  if valid_602180 != nil:
    section.add "StorageEncrypted", valid_602180
  var valid_602181 = formData.getOrDefault("DBClusterIdentifier")
  valid_602181 = validateParameter(valid_602181, JString, required = true,
                                 default = nil)
  if valid_602181 != nil:
    section.add "DBClusterIdentifier", valid_602181
  var valid_602182 = formData.getOrDefault("DeletionProtection")
  valid_602182 = validateParameter(valid_602182, JBool, required = false, default = nil)
  if valid_602182 != nil:
    section.add "DeletionProtection", valid_602182
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602183: Call_PostCreateDBCluster_602153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_602183.validator(path, query, header, formData, body)
  let scheme = call_602183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602183.url(scheme.get, call_602183.host, call_602183.base,
                         call_602183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602183, url, valid)

proc call*(call_602184: Call_PostCreateDBCluster_602153;
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
  var query_602185 = newJObject()
  var formData_602186 = newJObject()
  add(formData_602186, "Port", newJInt(Port))
  add(formData_602186, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_602186, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602186, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602186, "MasterUsername", newJString(MasterUsername))
  add(formData_602186, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_602186.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_602186.add "AvailabilityZones", AvailabilityZones
  add(formData_602186, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602186, "Engine", newJString(Engine))
  add(formData_602186, "KmsKeyId", newJString(KmsKeyId))
  if EnableCloudwatchLogsExports != nil:
    formData_602186.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_602185, "Action", newJString(Action))
  if Tags != nil:
    formData_602186.add "Tags", Tags
  add(formData_602186, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602186, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602185, "Version", newJString(Version))
  add(formData_602186, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_602186, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_602186, "DeletionProtection", newJBool(DeletionProtection))
  result = call_602184.call(nil, query_602185, nil, formData_602186, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_602153(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_602154, base: "/",
    url: url_PostCreateDBCluster_602155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_602120 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBCluster_602122(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBCluster_602121(path: JsonNode; query: JsonNode;
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
  var valid_602123 = query.getOrDefault("StorageEncrypted")
  valid_602123 = validateParameter(valid_602123, JBool, required = false, default = nil)
  if valid_602123 != nil:
    section.add "StorageEncrypted", valid_602123
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_602124 = query.getOrDefault("Engine")
  valid_602124 = validateParameter(valid_602124, JString, required = true,
                                 default = nil)
  if valid_602124 != nil:
    section.add "Engine", valid_602124
  var valid_602125 = query.getOrDefault("DeletionProtection")
  valid_602125 = validateParameter(valid_602125, JBool, required = false, default = nil)
  if valid_602125 != nil:
    section.add "DeletionProtection", valid_602125
  var valid_602126 = query.getOrDefault("Tags")
  valid_602126 = validateParameter(valid_602126, JArray, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "Tags", valid_602126
  var valid_602127 = query.getOrDefault("KmsKeyId")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "KmsKeyId", valid_602127
  var valid_602128 = query.getOrDefault("DBClusterIdentifier")
  valid_602128 = validateParameter(valid_602128, JString, required = true,
                                 default = nil)
  if valid_602128 != nil:
    section.add "DBClusterIdentifier", valid_602128
  var valid_602129 = query.getOrDefault("DBClusterParameterGroupName")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "DBClusterParameterGroupName", valid_602129
  var valid_602130 = query.getOrDefault("AvailabilityZones")
  valid_602130 = validateParameter(valid_602130, JArray, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "AvailabilityZones", valid_602130
  var valid_602131 = query.getOrDefault("MasterUsername")
  valid_602131 = validateParameter(valid_602131, JString, required = true,
                                 default = nil)
  if valid_602131 != nil:
    section.add "MasterUsername", valid_602131
  var valid_602132 = query.getOrDefault("BackupRetentionPeriod")
  valid_602132 = validateParameter(valid_602132, JInt, required = false, default = nil)
  if valid_602132 != nil:
    section.add "BackupRetentionPeriod", valid_602132
  var valid_602133 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_602133 = validateParameter(valid_602133, JArray, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "EnableCloudwatchLogsExports", valid_602133
  var valid_602134 = query.getOrDefault("EngineVersion")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "EngineVersion", valid_602134
  var valid_602135 = query.getOrDefault("Action")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_602135 != nil:
    section.add "Action", valid_602135
  var valid_602136 = query.getOrDefault("Port")
  valid_602136 = validateParameter(valid_602136, JInt, required = false, default = nil)
  if valid_602136 != nil:
    section.add "Port", valid_602136
  var valid_602137 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602137 = validateParameter(valid_602137, JArray, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "VpcSecurityGroupIds", valid_602137
  var valid_602138 = query.getOrDefault("MasterUserPassword")
  valid_602138 = validateParameter(valid_602138, JString, required = true,
                                 default = nil)
  if valid_602138 != nil:
    section.add "MasterUserPassword", valid_602138
  var valid_602139 = query.getOrDefault("DBSubnetGroupName")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "DBSubnetGroupName", valid_602139
  var valid_602140 = query.getOrDefault("PreferredBackupWindow")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "PreferredBackupWindow", valid_602140
  var valid_602141 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "PreferredMaintenanceWindow", valid_602141
  var valid_602142 = query.getOrDefault("Version")
  valid_602142 = validateParameter(valid_602142, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602142 != nil:
    section.add "Version", valid_602142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602143 = header.getOrDefault("X-Amz-Signature")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Signature", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Content-Sha256", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Date")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Date", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Credential")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Credential", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Security-Token")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Security-Token", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Algorithm")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Algorithm", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-SignedHeaders", valid_602149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602150: Call_GetCreateDBCluster_602120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_602150.validator(path, query, header, formData, body)
  let scheme = call_602150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602150.url(scheme.get, call_602150.host, call_602150.base,
                         call_602150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602150, url, valid)

proc call*(call_602151: Call_GetCreateDBCluster_602120; Engine: string;
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
  var query_602152 = newJObject()
  add(query_602152, "StorageEncrypted", newJBool(StorageEncrypted))
  add(query_602152, "Engine", newJString(Engine))
  add(query_602152, "DeletionProtection", newJBool(DeletionProtection))
  if Tags != nil:
    query_602152.add "Tags", Tags
  add(query_602152, "KmsKeyId", newJString(KmsKeyId))
  add(query_602152, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602152, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if AvailabilityZones != nil:
    query_602152.add "AvailabilityZones", AvailabilityZones
  add(query_602152, "MasterUsername", newJString(MasterUsername))
  add(query_602152, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if EnableCloudwatchLogsExports != nil:
    query_602152.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_602152, "EngineVersion", newJString(EngineVersion))
  add(query_602152, "Action", newJString(Action))
  add(query_602152, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_602152.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602152, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602152, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602152, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602152, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602152, "Version", newJString(Version))
  result = call_602151.call(nil, query_602152, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_602120(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_602121,
    base: "/", url: url_GetCreateDBCluster_602122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_602206 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBClusterParameterGroup_602208(protocol: Scheme; host: string;
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

proc validate_PostCreateDBClusterParameterGroup_602207(path: JsonNode;
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
  var valid_602209 = query.getOrDefault("Action")
  valid_602209 = validateParameter(valid_602209, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_602209 != nil:
    section.add "Action", valid_602209
  var valid_602210 = query.getOrDefault("Version")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602210 != nil:
    section.add "Version", valid_602210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602211 = header.getOrDefault("X-Amz-Signature")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Signature", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Content-Sha256", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Date")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Date", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Credential")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Credential", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Security-Token")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Security-Token", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Algorithm")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Algorithm", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-SignedHeaders", valid_602217
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
  var valid_602218 = formData.getOrDefault("Description")
  valid_602218 = validateParameter(valid_602218, JString, required = true,
                                 default = nil)
  if valid_602218 != nil:
    section.add "Description", valid_602218
  var valid_602219 = formData.getOrDefault("Tags")
  valid_602219 = validateParameter(valid_602219, JArray, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "Tags", valid_602219
  var valid_602220 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_602220 = validateParameter(valid_602220, JString, required = true,
                                 default = nil)
  if valid_602220 != nil:
    section.add "DBClusterParameterGroupName", valid_602220
  var valid_602221 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602221 = validateParameter(valid_602221, JString, required = true,
                                 default = nil)
  if valid_602221 != nil:
    section.add "DBParameterGroupFamily", valid_602221
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602222: Call_PostCreateDBClusterParameterGroup_602206;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_602222.validator(path, query, header, formData, body)
  let scheme = call_602222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602222.url(scheme.get, call_602222.host, call_602222.base,
                         call_602222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602222, url, valid)

proc call*(call_602223: Call_PostCreateDBClusterParameterGroup_602206;
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
  var query_602224 = newJObject()
  var formData_602225 = newJObject()
  add(formData_602225, "Description", newJString(Description))
  add(query_602224, "Action", newJString(Action))
  if Tags != nil:
    formData_602225.add "Tags", Tags
  add(formData_602225, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602224, "Version", newJString(Version))
  add(formData_602225, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_602223.call(nil, query_602224, nil, formData_602225, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_602206(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_602207, base: "/",
    url: url_PostCreateDBClusterParameterGroup_602208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_602187 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBClusterParameterGroup_602189(protocol: Scheme; host: string;
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

proc validate_GetCreateDBClusterParameterGroup_602188(path: JsonNode;
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
  var valid_602190 = query.getOrDefault("DBParameterGroupFamily")
  valid_602190 = validateParameter(valid_602190, JString, required = true,
                                 default = nil)
  if valid_602190 != nil:
    section.add "DBParameterGroupFamily", valid_602190
  var valid_602191 = query.getOrDefault("Tags")
  valid_602191 = validateParameter(valid_602191, JArray, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "Tags", valid_602191
  var valid_602192 = query.getOrDefault("DBClusterParameterGroupName")
  valid_602192 = validateParameter(valid_602192, JString, required = true,
                                 default = nil)
  if valid_602192 != nil:
    section.add "DBClusterParameterGroupName", valid_602192
  var valid_602193 = query.getOrDefault("Action")
  valid_602193 = validateParameter(valid_602193, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_602193 != nil:
    section.add "Action", valid_602193
  var valid_602194 = query.getOrDefault("Description")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = nil)
  if valid_602194 != nil:
    section.add "Description", valid_602194
  var valid_602195 = query.getOrDefault("Version")
  valid_602195 = validateParameter(valid_602195, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602195 != nil:
    section.add "Version", valid_602195
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602196 = header.getOrDefault("X-Amz-Signature")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Signature", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Content-Sha256", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Date")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Date", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Credential")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Credential", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Security-Token")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Security-Token", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Algorithm")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Algorithm", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-SignedHeaders", valid_602202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_GetCreateDBClusterParameterGroup_602187;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_GetCreateDBClusterParameterGroup_602187;
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
  var query_602205 = newJObject()
  add(query_602205, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_602205.add "Tags", Tags
  add(query_602205, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602205, "Action", newJString(Action))
  add(query_602205, "Description", newJString(Description))
  add(query_602205, "Version", newJString(Version))
  result = call_602204.call(nil, query_602205, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_602187(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_602188, base: "/",
    url: url_GetCreateDBClusterParameterGroup_602189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_602244 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBClusterSnapshot_602246(protocol: Scheme; host: string;
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

proc validate_PostCreateDBClusterSnapshot_602245(path: JsonNode; query: JsonNode;
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
  var valid_602247 = query.getOrDefault("Action")
  valid_602247 = validateParameter(valid_602247, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_602247 != nil:
    section.add "Action", valid_602247
  var valid_602248 = query.getOrDefault("Version")
  valid_602248 = validateParameter(valid_602248, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602248 != nil:
    section.add "Version", valid_602248
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602249 = header.getOrDefault("X-Amz-Signature")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Signature", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Content-Sha256", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Date")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Date", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Credential")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Credential", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Security-Token")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Security-Token", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Algorithm")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Algorithm", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-SignedHeaders", valid_602255
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
  var valid_602256 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602256 = validateParameter(valid_602256, JString, required = true,
                                 default = nil)
  if valid_602256 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602256
  var valid_602257 = formData.getOrDefault("Tags")
  valid_602257 = validateParameter(valid_602257, JArray, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "Tags", valid_602257
  var valid_602258 = formData.getOrDefault("DBClusterIdentifier")
  valid_602258 = validateParameter(valid_602258, JString, required = true,
                                 default = nil)
  if valid_602258 != nil:
    section.add "DBClusterIdentifier", valid_602258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602259: Call_PostCreateDBClusterSnapshot_602244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_602259.validator(path, query, header, formData, body)
  let scheme = call_602259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602259.url(scheme.get, call_602259.host, call_602259.base,
                         call_602259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602259, url, valid)

proc call*(call_602260: Call_PostCreateDBClusterSnapshot_602244;
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
  var query_602261 = newJObject()
  var formData_602262 = newJObject()
  add(formData_602262, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_602261, "Action", newJString(Action))
  if Tags != nil:
    formData_602262.add "Tags", Tags
  add(query_602261, "Version", newJString(Version))
  add(formData_602262, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_602260.call(nil, query_602261, nil, formData_602262, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_602244(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_602245, base: "/",
    url: url_PostCreateDBClusterSnapshot_602246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_602226 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBClusterSnapshot_602228(protocol: Scheme; host: string;
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

proc validate_GetCreateDBClusterSnapshot_602227(path: JsonNode; query: JsonNode;
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
  var valid_602229 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602229 = validateParameter(valid_602229, JString, required = true,
                                 default = nil)
  if valid_602229 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602229
  var valid_602230 = query.getOrDefault("Tags")
  valid_602230 = validateParameter(valid_602230, JArray, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "Tags", valid_602230
  var valid_602231 = query.getOrDefault("DBClusterIdentifier")
  valid_602231 = validateParameter(valid_602231, JString, required = true,
                                 default = nil)
  if valid_602231 != nil:
    section.add "DBClusterIdentifier", valid_602231
  var valid_602232 = query.getOrDefault("Action")
  valid_602232 = validateParameter(valid_602232, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_602232 != nil:
    section.add "Action", valid_602232
  var valid_602233 = query.getOrDefault("Version")
  valid_602233 = validateParameter(valid_602233, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602233 != nil:
    section.add "Version", valid_602233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602234 = header.getOrDefault("X-Amz-Signature")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Signature", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Content-Sha256", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Date")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Date", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Credential")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Credential", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Security-Token")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Security-Token", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Algorithm")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Algorithm", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-SignedHeaders", valid_602240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602241: Call_GetCreateDBClusterSnapshot_602226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_602241.validator(path, query, header, formData, body)
  let scheme = call_602241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602241.url(scheme.get, call_602241.host, call_602241.base,
                         call_602241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602241, url, valid)

proc call*(call_602242: Call_GetCreateDBClusterSnapshot_602226;
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
  var query_602243 = newJObject()
  add(query_602243, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_602243.add "Tags", Tags
  add(query_602243, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602243, "Action", newJString(Action))
  add(query_602243, "Version", newJString(Version))
  result = call_602242.call(nil, query_602243, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_602226(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_602227, base: "/",
    url: url_GetCreateDBClusterSnapshot_602228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_602287 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBInstance_602289(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_602288(path: JsonNode; query: JsonNode;
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
  var valid_602290 = query.getOrDefault("Action")
  valid_602290 = validateParameter(valid_602290, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_602290 != nil:
    section.add "Action", valid_602290
  var valid_602291 = query.getOrDefault("Version")
  valid_602291 = validateParameter(valid_602291, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602291 != nil:
    section.add "Version", valid_602291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602292 = header.getOrDefault("X-Amz-Signature")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Signature", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Content-Sha256", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Date")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Date", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Credential")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Credential", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Security-Token")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Security-Token", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Algorithm")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Algorithm", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-SignedHeaders", valid_602298
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
  var valid_602299 = formData.getOrDefault("PromotionTier")
  valid_602299 = validateParameter(valid_602299, JInt, required = false, default = nil)
  if valid_602299 != nil:
    section.add "PromotionTier", valid_602299
  var valid_602300 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "PreferredMaintenanceWindow", valid_602300
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_602301 = formData.getOrDefault("DBInstanceClass")
  valid_602301 = validateParameter(valid_602301, JString, required = true,
                                 default = nil)
  if valid_602301 != nil:
    section.add "DBInstanceClass", valid_602301
  var valid_602302 = formData.getOrDefault("AvailabilityZone")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "AvailabilityZone", valid_602302
  var valid_602303 = formData.getOrDefault("Engine")
  valid_602303 = validateParameter(valid_602303, JString, required = true,
                                 default = nil)
  if valid_602303 != nil:
    section.add "Engine", valid_602303
  var valid_602304 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602304 = validateParameter(valid_602304, JBool, required = false, default = nil)
  if valid_602304 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602304
  var valid_602305 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602305 = validateParameter(valid_602305, JString, required = true,
                                 default = nil)
  if valid_602305 != nil:
    section.add "DBInstanceIdentifier", valid_602305
  var valid_602306 = formData.getOrDefault("Tags")
  valid_602306 = validateParameter(valid_602306, JArray, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "Tags", valid_602306
  var valid_602307 = formData.getOrDefault("DBClusterIdentifier")
  valid_602307 = validateParameter(valid_602307, JString, required = true,
                                 default = nil)
  if valid_602307 != nil:
    section.add "DBClusterIdentifier", valid_602307
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602308: Call_PostCreateDBInstance_602287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_602308.validator(path, query, header, formData, body)
  let scheme = call_602308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602308.url(scheme.get, call_602308.host, call_602308.base,
                         call_602308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602308, url, valid)

proc call*(call_602309: Call_PostCreateDBInstance_602287; DBInstanceClass: string;
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
  var query_602310 = newJObject()
  var formData_602311 = newJObject()
  add(formData_602311, "PromotionTier", newJInt(PromotionTier))
  add(formData_602311, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_602311, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602311, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602311, "Engine", newJString(Engine))
  add(formData_602311, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602311, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602310, "Action", newJString(Action))
  if Tags != nil:
    formData_602311.add "Tags", Tags
  add(query_602310, "Version", newJString(Version))
  add(formData_602311, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_602309.call(nil, query_602310, nil, formData_602311, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_602287(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_602288, base: "/",
    url: url_PostCreateDBInstance_602289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_602263 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBInstance_602265(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_602264(path: JsonNode; query: JsonNode;
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
  var valid_602266 = query.getOrDefault("Engine")
  valid_602266 = validateParameter(valid_602266, JString, required = true,
                                 default = nil)
  if valid_602266 != nil:
    section.add "Engine", valid_602266
  var valid_602267 = query.getOrDefault("Tags")
  valid_602267 = validateParameter(valid_602267, JArray, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "Tags", valid_602267
  var valid_602268 = query.getOrDefault("DBClusterIdentifier")
  valid_602268 = validateParameter(valid_602268, JString, required = true,
                                 default = nil)
  if valid_602268 != nil:
    section.add "DBClusterIdentifier", valid_602268
  var valid_602269 = query.getOrDefault("DBInstanceIdentifier")
  valid_602269 = validateParameter(valid_602269, JString, required = true,
                                 default = nil)
  if valid_602269 != nil:
    section.add "DBInstanceIdentifier", valid_602269
  var valid_602270 = query.getOrDefault("PromotionTier")
  valid_602270 = validateParameter(valid_602270, JInt, required = false, default = nil)
  if valid_602270 != nil:
    section.add "PromotionTier", valid_602270
  var valid_602271 = query.getOrDefault("Action")
  valid_602271 = validateParameter(valid_602271, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_602271 != nil:
    section.add "Action", valid_602271
  var valid_602272 = query.getOrDefault("AvailabilityZone")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "AvailabilityZone", valid_602272
  var valid_602273 = query.getOrDefault("Version")
  valid_602273 = validateParameter(valid_602273, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602273 != nil:
    section.add "Version", valid_602273
  var valid_602274 = query.getOrDefault("DBInstanceClass")
  valid_602274 = validateParameter(valid_602274, JString, required = true,
                                 default = nil)
  if valid_602274 != nil:
    section.add "DBInstanceClass", valid_602274
  var valid_602275 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "PreferredMaintenanceWindow", valid_602275
  var valid_602276 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602276 = validateParameter(valid_602276, JBool, required = false, default = nil)
  if valid_602276 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602277 = header.getOrDefault("X-Amz-Signature")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Signature", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Content-Sha256", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Date")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Date", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Credential")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Credential", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Security-Token")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Security-Token", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Algorithm")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Algorithm", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-SignedHeaders", valid_602283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602284: Call_GetCreateDBInstance_602263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_602284.validator(path, query, header, formData, body)
  let scheme = call_602284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602284.url(scheme.get, call_602284.host, call_602284.base,
                         call_602284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602284, url, valid)

proc call*(call_602285: Call_GetCreateDBInstance_602263; Engine: string;
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
  var query_602286 = newJObject()
  add(query_602286, "Engine", newJString(Engine))
  if Tags != nil:
    query_602286.add "Tags", Tags
  add(query_602286, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602286, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602286, "PromotionTier", newJInt(PromotionTier))
  add(query_602286, "Action", newJString(Action))
  add(query_602286, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602286, "Version", newJString(Version))
  add(query_602286, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602286, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602286, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_602285.call(nil, query_602286, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_602263(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_602264, base: "/",
    url: url_GetCreateDBInstance_602265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_602331 = ref object of OpenApiRestCall_601373
proc url_PostCreateDBSubnetGroup_602333(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_602332(path: JsonNode; query: JsonNode;
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
  var valid_602334 = query.getOrDefault("Action")
  valid_602334 = validateParameter(valid_602334, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_602334 != nil:
    section.add "Action", valid_602334
  var valid_602335 = query.getOrDefault("Version")
  valid_602335 = validateParameter(valid_602335, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602335 != nil:
    section.add "Version", valid_602335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602336 = header.getOrDefault("X-Amz-Signature")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Signature", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Content-Sha256", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Date")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Date", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Credential")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Credential", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Security-Token")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Security-Token", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Algorithm")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Algorithm", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-SignedHeaders", valid_602342
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
  var valid_602343 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602343 = validateParameter(valid_602343, JString, required = true,
                                 default = nil)
  if valid_602343 != nil:
    section.add "DBSubnetGroupDescription", valid_602343
  var valid_602344 = formData.getOrDefault("Tags")
  valid_602344 = validateParameter(valid_602344, JArray, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "Tags", valid_602344
  var valid_602345 = formData.getOrDefault("DBSubnetGroupName")
  valid_602345 = validateParameter(valid_602345, JString, required = true,
                                 default = nil)
  if valid_602345 != nil:
    section.add "DBSubnetGroupName", valid_602345
  var valid_602346 = formData.getOrDefault("SubnetIds")
  valid_602346 = validateParameter(valid_602346, JArray, required = true, default = nil)
  if valid_602346 != nil:
    section.add "SubnetIds", valid_602346
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602347: Call_PostCreateDBSubnetGroup_602331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_602347.validator(path, query, header, formData, body)
  let scheme = call_602347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602347.url(scheme.get, call_602347.host, call_602347.base,
                         call_602347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602347, url, valid)

proc call*(call_602348: Call_PostCreateDBSubnetGroup_602331;
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
  var query_602349 = newJObject()
  var formData_602350 = newJObject()
  add(formData_602350, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602349, "Action", newJString(Action))
  if Tags != nil:
    formData_602350.add "Tags", Tags
  add(formData_602350, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602349, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_602350.add "SubnetIds", SubnetIds
  result = call_602348.call(nil, query_602349, nil, formData_602350, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_602331(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_602332, base: "/",
    url: url_PostCreateDBSubnetGroup_602333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_602312 = ref object of OpenApiRestCall_601373
proc url_GetCreateDBSubnetGroup_602314(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_602313(path: JsonNode; query: JsonNode;
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
  var valid_602315 = query.getOrDefault("Tags")
  valid_602315 = validateParameter(valid_602315, JArray, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "Tags", valid_602315
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_602316 = query.getOrDefault("SubnetIds")
  valid_602316 = validateParameter(valid_602316, JArray, required = true, default = nil)
  if valid_602316 != nil:
    section.add "SubnetIds", valid_602316
  var valid_602317 = query.getOrDefault("Action")
  valid_602317 = validateParameter(valid_602317, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_602317 != nil:
    section.add "Action", valid_602317
  var valid_602318 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602318 = validateParameter(valid_602318, JString, required = true,
                                 default = nil)
  if valid_602318 != nil:
    section.add "DBSubnetGroupDescription", valid_602318
  var valid_602319 = query.getOrDefault("DBSubnetGroupName")
  valid_602319 = validateParameter(valid_602319, JString, required = true,
                                 default = nil)
  if valid_602319 != nil:
    section.add "DBSubnetGroupName", valid_602319
  var valid_602320 = query.getOrDefault("Version")
  valid_602320 = validateParameter(valid_602320, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602320 != nil:
    section.add "Version", valid_602320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602321 = header.getOrDefault("X-Amz-Signature")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Signature", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Content-Sha256", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Date")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Date", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Credential")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Credential", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Security-Token")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Security-Token", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Algorithm")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Algorithm", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-SignedHeaders", valid_602327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602328: Call_GetCreateDBSubnetGroup_602312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_602328.validator(path, query, header, formData, body)
  let scheme = call_602328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602328.url(scheme.get, call_602328.host, call_602328.base,
                         call_602328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602328, url, valid)

proc call*(call_602329: Call_GetCreateDBSubnetGroup_602312; SubnetIds: JsonNode;
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
  var query_602330 = newJObject()
  if Tags != nil:
    query_602330.add "Tags", Tags
  if SubnetIds != nil:
    query_602330.add "SubnetIds", SubnetIds
  add(query_602330, "Action", newJString(Action))
  add(query_602330, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602330, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602330, "Version", newJString(Version))
  result = call_602329.call(nil, query_602330, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_602312(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_602313, base: "/",
    url: url_GetCreateDBSubnetGroup_602314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_602369 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBCluster_602371(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBCluster_602370(path: JsonNode; query: JsonNode;
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
  var valid_602372 = query.getOrDefault("Action")
  valid_602372 = validateParameter(valid_602372, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_602372 != nil:
    section.add "Action", valid_602372
  var valid_602373 = query.getOrDefault("Version")
  valid_602373 = validateParameter(valid_602373, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602373 != nil:
    section.add "Version", valid_602373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602374 = header.getOrDefault("X-Amz-Signature")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Signature", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Content-Sha256", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Date")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Date", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Credential")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Credential", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Security-Token")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Security-Token", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Algorithm")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Algorithm", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-SignedHeaders", valid_602380
  result.add "header", section
  ## parameters in `formData` object:
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  section = newJObject()
  var valid_602381 = formData.getOrDefault("SkipFinalSnapshot")
  valid_602381 = validateParameter(valid_602381, JBool, required = false, default = nil)
  if valid_602381 != nil:
    section.add "SkipFinalSnapshot", valid_602381
  var valid_602382 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_602382
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_602383 = formData.getOrDefault("DBClusterIdentifier")
  valid_602383 = validateParameter(valid_602383, JString, required = true,
                                 default = nil)
  if valid_602383 != nil:
    section.add "DBClusterIdentifier", valid_602383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602384: Call_PostDeleteDBCluster_602369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_602384.validator(path, query, header, formData, body)
  let scheme = call_602384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602384.url(scheme.get, call_602384.host, call_602384.base,
                         call_602384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602384, url, valid)

proc call*(call_602385: Call_PostDeleteDBCluster_602369;
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
  var query_602386 = newJObject()
  var formData_602387 = newJObject()
  add(query_602386, "Action", newJString(Action))
  add(formData_602387, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_602387, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_602386, "Version", newJString(Version))
  add(formData_602387, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_602385.call(nil, query_602386, nil, formData_602387, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_602369(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_602370, base: "/",
    url: url_PostDeleteDBCluster_602371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_602351 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBCluster_602353(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBCluster_602352(path: JsonNode; query: JsonNode;
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
  var valid_602354 = query.getOrDefault("DBClusterIdentifier")
  valid_602354 = validateParameter(valid_602354, JString, required = true,
                                 default = nil)
  if valid_602354 != nil:
    section.add "DBClusterIdentifier", valid_602354
  var valid_602355 = query.getOrDefault("SkipFinalSnapshot")
  valid_602355 = validateParameter(valid_602355, JBool, required = false, default = nil)
  if valid_602355 != nil:
    section.add "SkipFinalSnapshot", valid_602355
  var valid_602356 = query.getOrDefault("Action")
  valid_602356 = validateParameter(valid_602356, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_602356 != nil:
    section.add "Action", valid_602356
  var valid_602357 = query.getOrDefault("Version")
  valid_602357 = validateParameter(valid_602357, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602357 != nil:
    section.add "Version", valid_602357
  var valid_602358 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_602358
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602359 = header.getOrDefault("X-Amz-Signature")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Signature", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Content-Sha256", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Date")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Date", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Credential")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Credential", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Security-Token")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Security-Token", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Algorithm")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Algorithm", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-SignedHeaders", valid_602365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602366: Call_GetDeleteDBCluster_602351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_602366.validator(path, query, header, formData, body)
  let scheme = call_602366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602366.url(scheme.get, call_602366.host, call_602366.base,
                         call_602366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602366, url, valid)

proc call*(call_602367: Call_GetDeleteDBCluster_602351;
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
  var query_602368 = newJObject()
  add(query_602368, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602368, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_602368, "Action", newJString(Action))
  add(query_602368, "Version", newJString(Version))
  add(query_602368, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_602367.call(nil, query_602368, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_602351(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_602352,
    base: "/", url: url_GetDeleteDBCluster_602353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_602404 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBClusterParameterGroup_602406(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBClusterParameterGroup_602405(path: JsonNode;
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
  var valid_602407 = query.getOrDefault("Action")
  valid_602407 = validateParameter(valid_602407, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_602407 != nil:
    section.add "Action", valid_602407
  var valid_602408 = query.getOrDefault("Version")
  valid_602408 = validateParameter(valid_602408, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602408 != nil:
    section.add "Version", valid_602408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602409 = header.getOrDefault("X-Amz-Signature")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Signature", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Content-Sha256", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Date")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Date", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Credential")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Credential", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Security-Token")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Security-Token", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Algorithm")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Algorithm", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-SignedHeaders", valid_602415
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_602416 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_602416 = validateParameter(valid_602416, JString, required = true,
                                 default = nil)
  if valid_602416 != nil:
    section.add "DBClusterParameterGroupName", valid_602416
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602417: Call_PostDeleteDBClusterParameterGroup_602404;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_602417.validator(path, query, header, formData, body)
  let scheme = call_602417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602417.url(scheme.get, call_602417.host, call_602417.base,
                         call_602417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602417, url, valid)

proc call*(call_602418: Call_PostDeleteDBClusterParameterGroup_602404;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_602419 = newJObject()
  var formData_602420 = newJObject()
  add(query_602419, "Action", newJString(Action))
  add(formData_602420, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602419, "Version", newJString(Version))
  result = call_602418.call(nil, query_602419, nil, formData_602420, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_602404(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_602405, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_602406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_602388 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBClusterParameterGroup_602390(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBClusterParameterGroup_602389(path: JsonNode;
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
  var valid_602391 = query.getOrDefault("DBClusterParameterGroupName")
  valid_602391 = validateParameter(valid_602391, JString, required = true,
                                 default = nil)
  if valid_602391 != nil:
    section.add "DBClusterParameterGroupName", valid_602391
  var valid_602392 = query.getOrDefault("Action")
  valid_602392 = validateParameter(valid_602392, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_602392 != nil:
    section.add "Action", valid_602392
  var valid_602393 = query.getOrDefault("Version")
  valid_602393 = validateParameter(valid_602393, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602393 != nil:
    section.add "Version", valid_602393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602394 = header.getOrDefault("X-Amz-Signature")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Signature", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Content-Sha256", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Date")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Date", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Credential")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Credential", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Security-Token")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Security-Token", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Algorithm")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Algorithm", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-SignedHeaders", valid_602400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602401: Call_GetDeleteDBClusterParameterGroup_602388;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_602401.validator(path, query, header, formData, body)
  let scheme = call_602401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602401.url(scheme.get, call_602401.host, call_602401.base,
                         call_602401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602401, url, valid)

proc call*(call_602402: Call_GetDeleteDBClusterParameterGroup_602388;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602403 = newJObject()
  add(query_602403, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602403, "Action", newJString(Action))
  add(query_602403, "Version", newJString(Version))
  result = call_602402.call(nil, query_602403, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_602388(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_602389, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_602390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_602437 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBClusterSnapshot_602439(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBClusterSnapshot_602438(path: JsonNode; query: JsonNode;
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
  var valid_602440 = query.getOrDefault("Action")
  valid_602440 = validateParameter(valid_602440, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_602440 != nil:
    section.add "Action", valid_602440
  var valid_602441 = query.getOrDefault("Version")
  valid_602441 = validateParameter(valid_602441, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602441 != nil:
    section.add "Version", valid_602441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602442 = header.getOrDefault("X-Amz-Signature")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Signature", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Content-Sha256", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Date")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Date", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Credential")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Credential", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Security-Token")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Security-Token", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Algorithm")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Algorithm", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-SignedHeaders", valid_602448
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_602449 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602449 = validateParameter(valid_602449, JString, required = true,
                                 default = nil)
  if valid_602449 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602449
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602450: Call_PostDeleteDBClusterSnapshot_602437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_602450.validator(path, query, header, formData, body)
  let scheme = call_602450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602450.url(scheme.get, call_602450.host, call_602450.base,
                         call_602450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602450, url, valid)

proc call*(call_602451: Call_PostDeleteDBClusterSnapshot_602437;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602452 = newJObject()
  var formData_602453 = newJObject()
  add(formData_602453, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_602452, "Action", newJString(Action))
  add(query_602452, "Version", newJString(Version))
  result = call_602451.call(nil, query_602452, nil, formData_602453, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_602437(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_602438, base: "/",
    url: url_PostDeleteDBClusterSnapshot_602439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_602421 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBClusterSnapshot_602423(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBClusterSnapshot_602422(path: JsonNode; query: JsonNode;
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
  var valid_602424 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602424 = validateParameter(valid_602424, JString, required = true,
                                 default = nil)
  if valid_602424 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602424
  var valid_602425 = query.getOrDefault("Action")
  valid_602425 = validateParameter(valid_602425, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_602425 != nil:
    section.add "Action", valid_602425
  var valid_602426 = query.getOrDefault("Version")
  valid_602426 = validateParameter(valid_602426, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602426 != nil:
    section.add "Version", valid_602426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602427 = header.getOrDefault("X-Amz-Signature")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Signature", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Content-Sha256", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Date")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Date", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Credential")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Credential", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Security-Token")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Security-Token", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Algorithm")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Algorithm", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-SignedHeaders", valid_602433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602434: Call_GetDeleteDBClusterSnapshot_602421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_602434.validator(path, query, header, formData, body)
  let scheme = call_602434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602434.url(scheme.get, call_602434.host, call_602434.base,
                         call_602434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602434, url, valid)

proc call*(call_602435: Call_GetDeleteDBClusterSnapshot_602421;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602436 = newJObject()
  add(query_602436, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_602436, "Action", newJString(Action))
  add(query_602436, "Version", newJString(Version))
  result = call_602435.call(nil, query_602436, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_602421(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_602422, base: "/",
    url: url_GetDeleteDBClusterSnapshot_602423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_602470 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBInstance_602472(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_602471(path: JsonNode; query: JsonNode;
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
  var valid_602473 = query.getOrDefault("Action")
  valid_602473 = validateParameter(valid_602473, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_602473 != nil:
    section.add "Action", valid_602473
  var valid_602474 = query.getOrDefault("Version")
  valid_602474 = validateParameter(valid_602474, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602474 != nil:
    section.add "Version", valid_602474
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602475 = header.getOrDefault("X-Amz-Signature")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Signature", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Content-Sha256", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Date")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Date", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Credential")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Credential", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Security-Token")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Security-Token", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Algorithm")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Algorithm", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-SignedHeaders", valid_602481
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602482 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602482 = validateParameter(valid_602482, JString, required = true,
                                 default = nil)
  if valid_602482 != nil:
    section.add "DBInstanceIdentifier", valid_602482
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602483: Call_PostDeleteDBInstance_602470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_602483.validator(path, query, header, formData, body)
  let scheme = call_602483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602483.url(scheme.get, call_602483.host, call_602483.base,
                         call_602483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602483, url, valid)

proc call*(call_602484: Call_PostDeleteDBInstance_602470;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602485 = newJObject()
  var formData_602486 = newJObject()
  add(formData_602486, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602485, "Action", newJString(Action))
  add(query_602485, "Version", newJString(Version))
  result = call_602484.call(nil, query_602485, nil, formData_602486, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_602470(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_602471, base: "/",
    url: url_PostDeleteDBInstance_602472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_602454 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBInstance_602456(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_602455(path: JsonNode; query: JsonNode;
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
  var valid_602457 = query.getOrDefault("DBInstanceIdentifier")
  valid_602457 = validateParameter(valid_602457, JString, required = true,
                                 default = nil)
  if valid_602457 != nil:
    section.add "DBInstanceIdentifier", valid_602457
  var valid_602458 = query.getOrDefault("Action")
  valid_602458 = validateParameter(valid_602458, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_602458 != nil:
    section.add "Action", valid_602458
  var valid_602459 = query.getOrDefault("Version")
  valid_602459 = validateParameter(valid_602459, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602459 != nil:
    section.add "Version", valid_602459
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602460 = header.getOrDefault("X-Amz-Signature")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Signature", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Content-Sha256", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Date")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Date", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Credential")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Credential", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Security-Token")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Security-Token", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Algorithm")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Algorithm", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-SignedHeaders", valid_602466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602467: Call_GetDeleteDBInstance_602454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_602467.validator(path, query, header, formData, body)
  let scheme = call_602467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602467.url(scheme.get, call_602467.host, call_602467.base,
                         call_602467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602467, url, valid)

proc call*(call_602468: Call_GetDeleteDBInstance_602454;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602469 = newJObject()
  add(query_602469, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602469, "Action", newJString(Action))
  add(query_602469, "Version", newJString(Version))
  result = call_602468.call(nil, query_602469, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_602454(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_602455, base: "/",
    url: url_GetDeleteDBInstance_602456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_602503 = ref object of OpenApiRestCall_601373
proc url_PostDeleteDBSubnetGroup_602505(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_602504(path: JsonNode; query: JsonNode;
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
  var valid_602506 = query.getOrDefault("Action")
  valid_602506 = validateParameter(valid_602506, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_602506 != nil:
    section.add "Action", valid_602506
  var valid_602507 = query.getOrDefault("Version")
  valid_602507 = validateParameter(valid_602507, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602507 != nil:
    section.add "Version", valid_602507
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602508 = header.getOrDefault("X-Amz-Signature")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Signature", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Content-Sha256", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Date")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Date", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Credential")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Credential", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Security-Token")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Security-Token", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Algorithm")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Algorithm", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-SignedHeaders", valid_602514
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602515 = formData.getOrDefault("DBSubnetGroupName")
  valid_602515 = validateParameter(valid_602515, JString, required = true,
                                 default = nil)
  if valid_602515 != nil:
    section.add "DBSubnetGroupName", valid_602515
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602516: Call_PostDeleteDBSubnetGroup_602503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_602516.validator(path, query, header, formData, body)
  let scheme = call_602516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602516.url(scheme.get, call_602516.host, call_602516.base,
                         call_602516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602516, url, valid)

proc call*(call_602517: Call_PostDeleteDBSubnetGroup_602503;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_602518 = newJObject()
  var formData_602519 = newJObject()
  add(query_602518, "Action", newJString(Action))
  add(formData_602519, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602518, "Version", newJString(Version))
  result = call_602517.call(nil, query_602518, nil, formData_602519, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_602503(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_602504, base: "/",
    url: url_PostDeleteDBSubnetGroup_602505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_602487 = ref object of OpenApiRestCall_601373
proc url_GetDeleteDBSubnetGroup_602489(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_602488(path: JsonNode; query: JsonNode;
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
  var valid_602490 = query.getOrDefault("Action")
  valid_602490 = validateParameter(valid_602490, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_602490 != nil:
    section.add "Action", valid_602490
  var valid_602491 = query.getOrDefault("DBSubnetGroupName")
  valid_602491 = validateParameter(valid_602491, JString, required = true,
                                 default = nil)
  if valid_602491 != nil:
    section.add "DBSubnetGroupName", valid_602491
  var valid_602492 = query.getOrDefault("Version")
  valid_602492 = validateParameter(valid_602492, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602492 != nil:
    section.add "Version", valid_602492
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602493 = header.getOrDefault("X-Amz-Signature")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Signature", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Content-Sha256", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Date")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Date", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Credential")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Credential", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Security-Token")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Security-Token", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Algorithm")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Algorithm", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-SignedHeaders", valid_602499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602500: Call_GetDeleteDBSubnetGroup_602487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_602500.validator(path, query, header, formData, body)
  let scheme = call_602500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602500.url(scheme.get, call_602500.host, call_602500.base,
                         call_602500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602500, url, valid)

proc call*(call_602501: Call_GetDeleteDBSubnetGroup_602487;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_602502 = newJObject()
  add(query_602502, "Action", newJString(Action))
  add(query_602502, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602502, "Version", newJString(Version))
  result = call_602501.call(nil, query_602502, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_602487(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_602488, base: "/",
    url: url_GetDeleteDBSubnetGroup_602489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeCertificates_602539 = ref object of OpenApiRestCall_601373
proc url_PostDescribeCertificates_602541(protocol: Scheme; host: string;
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

proc validate_PostDescribeCertificates_602540(path: JsonNode; query: JsonNode;
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
  var valid_602542 = query.getOrDefault("Action")
  valid_602542 = validateParameter(valid_602542, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_602542 != nil:
    section.add "Action", valid_602542
  var valid_602543 = query.getOrDefault("Version")
  valid_602543 = validateParameter(valid_602543, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602543 != nil:
    section.add "Version", valid_602543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602544 = header.getOrDefault("X-Amz-Signature")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Signature", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Content-Sha256", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Date")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Date", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Credential")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Credential", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Security-Token")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Security-Token", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Algorithm")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Algorithm", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-SignedHeaders", valid_602550
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
  var valid_602551 = formData.getOrDefault("MaxRecords")
  valid_602551 = validateParameter(valid_602551, JInt, required = false, default = nil)
  if valid_602551 != nil:
    section.add "MaxRecords", valid_602551
  var valid_602552 = formData.getOrDefault("Marker")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "Marker", valid_602552
  var valid_602553 = formData.getOrDefault("CertificateIdentifier")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "CertificateIdentifier", valid_602553
  var valid_602554 = formData.getOrDefault("Filters")
  valid_602554 = validateParameter(valid_602554, JArray, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "Filters", valid_602554
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602555: Call_PostDescribeCertificates_602539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_602555.validator(path, query, header, formData, body)
  let scheme = call_602555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602555.url(scheme.get, call_602555.host, call_602555.base,
                         call_602555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602555, url, valid)

proc call*(call_602556: Call_PostDescribeCertificates_602539; MaxRecords: int = 0;
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
  var query_602557 = newJObject()
  var formData_602558 = newJObject()
  add(formData_602558, "MaxRecords", newJInt(MaxRecords))
  add(formData_602558, "Marker", newJString(Marker))
  add(formData_602558, "CertificateIdentifier", newJString(CertificateIdentifier))
  add(query_602557, "Action", newJString(Action))
  if Filters != nil:
    formData_602558.add "Filters", Filters
  add(query_602557, "Version", newJString(Version))
  result = call_602556.call(nil, query_602557, nil, formData_602558, nil)

var postDescribeCertificates* = Call_PostDescribeCertificates_602539(
    name: "postDescribeCertificates", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_PostDescribeCertificates_602540, base: "/",
    url: url_PostDescribeCertificates_602541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeCertificates_602520 = ref object of OpenApiRestCall_601373
proc url_GetDescribeCertificates_602522(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeCertificates_602521(path: JsonNode; query: JsonNode;
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
  var valid_602523 = query.getOrDefault("Marker")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "Marker", valid_602523
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602524 = query.getOrDefault("Action")
  valid_602524 = validateParameter(valid_602524, JString, required = true,
                                 default = newJString("DescribeCertificates"))
  if valid_602524 != nil:
    section.add "Action", valid_602524
  var valid_602525 = query.getOrDefault("Version")
  valid_602525 = validateParameter(valid_602525, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602525 != nil:
    section.add "Version", valid_602525
  var valid_602526 = query.getOrDefault("CertificateIdentifier")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "CertificateIdentifier", valid_602526
  var valid_602527 = query.getOrDefault("Filters")
  valid_602527 = validateParameter(valid_602527, JArray, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "Filters", valid_602527
  var valid_602528 = query.getOrDefault("MaxRecords")
  valid_602528 = validateParameter(valid_602528, JInt, required = false, default = nil)
  if valid_602528 != nil:
    section.add "MaxRecords", valid_602528
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602529 = header.getOrDefault("X-Amz-Signature")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Signature", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Content-Sha256", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-Date")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-Date", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Credential")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Credential", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Security-Token")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Security-Token", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Algorithm")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Algorithm", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-SignedHeaders", valid_602535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602536: Call_GetDescribeCertificates_602520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of certificate authority (CA) certificates provided by Amazon RDS for this AWS account.
  ## 
  let valid = call_602536.validator(path, query, header, formData, body)
  let scheme = call_602536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602536.url(scheme.get, call_602536.host, call_602536.base,
                         call_602536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602536, url, valid)

proc call*(call_602537: Call_GetDescribeCertificates_602520; Marker: string = "";
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
  var query_602538 = newJObject()
  add(query_602538, "Marker", newJString(Marker))
  add(query_602538, "Action", newJString(Action))
  add(query_602538, "Version", newJString(Version))
  add(query_602538, "CertificateIdentifier", newJString(CertificateIdentifier))
  if Filters != nil:
    query_602538.add "Filters", Filters
  add(query_602538, "MaxRecords", newJInt(MaxRecords))
  result = call_602537.call(nil, query_602538, nil, nil, nil)

var getDescribeCertificates* = Call_GetDescribeCertificates_602520(
    name: "getDescribeCertificates", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeCertificates",
    validator: validate_GetDescribeCertificates_602521, base: "/",
    url: url_GetDescribeCertificates_602522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_602578 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBClusterParameterGroups_602580(protocol: Scheme;
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

proc validate_PostDescribeDBClusterParameterGroups_602579(path: JsonNode;
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
  var valid_602581 = query.getOrDefault("Action")
  valid_602581 = validateParameter(valid_602581, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_602581 != nil:
    section.add "Action", valid_602581
  var valid_602582 = query.getOrDefault("Version")
  valid_602582 = validateParameter(valid_602582, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602582 != nil:
    section.add "Version", valid_602582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602583 = header.getOrDefault("X-Amz-Signature")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Signature", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Content-Sha256", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Date")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Date", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Credential")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Credential", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Security-Token")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Security-Token", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Algorithm")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Algorithm", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-SignedHeaders", valid_602589
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
  var valid_602590 = formData.getOrDefault("MaxRecords")
  valid_602590 = validateParameter(valid_602590, JInt, required = false, default = nil)
  if valid_602590 != nil:
    section.add "MaxRecords", valid_602590
  var valid_602591 = formData.getOrDefault("Marker")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "Marker", valid_602591
  var valid_602592 = formData.getOrDefault("Filters")
  valid_602592 = validateParameter(valid_602592, JArray, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "Filters", valid_602592
  var valid_602593 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "DBClusterParameterGroupName", valid_602593
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602594: Call_PostDescribeDBClusterParameterGroups_602578;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_602594.validator(path, query, header, formData, body)
  let scheme = call_602594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602594.url(scheme.get, call_602594.host, call_602594.base,
                         call_602594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602594, url, valid)

proc call*(call_602595: Call_PostDescribeDBClusterParameterGroups_602578;
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
  var query_602596 = newJObject()
  var formData_602597 = newJObject()
  add(formData_602597, "MaxRecords", newJInt(MaxRecords))
  add(formData_602597, "Marker", newJString(Marker))
  add(query_602596, "Action", newJString(Action))
  if Filters != nil:
    formData_602597.add "Filters", Filters
  add(formData_602597, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602596, "Version", newJString(Version))
  result = call_602595.call(nil, query_602596, nil, formData_602597, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_602578(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_602579, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_602580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_602559 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBClusterParameterGroups_602561(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBClusterParameterGroups_602560(path: JsonNode;
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
  var valid_602562 = query.getOrDefault("Marker")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "Marker", valid_602562
  var valid_602563 = query.getOrDefault("DBClusterParameterGroupName")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "DBClusterParameterGroupName", valid_602563
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602564 = query.getOrDefault("Action")
  valid_602564 = validateParameter(valid_602564, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_602564 != nil:
    section.add "Action", valid_602564
  var valid_602565 = query.getOrDefault("Version")
  valid_602565 = validateParameter(valid_602565, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602565 != nil:
    section.add "Version", valid_602565
  var valid_602566 = query.getOrDefault("Filters")
  valid_602566 = validateParameter(valid_602566, JArray, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "Filters", valid_602566
  var valid_602567 = query.getOrDefault("MaxRecords")
  valid_602567 = validateParameter(valid_602567, JInt, required = false, default = nil)
  if valid_602567 != nil:
    section.add "MaxRecords", valid_602567
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602568 = header.getOrDefault("X-Amz-Signature")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Signature", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-Content-Sha256", valid_602569
  var valid_602570 = header.getOrDefault("X-Amz-Date")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-Date", valid_602570
  var valid_602571 = header.getOrDefault("X-Amz-Credential")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-Credential", valid_602571
  var valid_602572 = header.getOrDefault("X-Amz-Security-Token")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Security-Token", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Algorithm")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Algorithm", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-SignedHeaders", valid_602574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602575: Call_GetDescribeDBClusterParameterGroups_602559;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_602575.validator(path, query, header, formData, body)
  let scheme = call_602575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602575.url(scheme.get, call_602575.host, call_602575.base,
                         call_602575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602575, url, valid)

proc call*(call_602576: Call_GetDescribeDBClusterParameterGroups_602559;
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
  var query_602577 = newJObject()
  add(query_602577, "Marker", newJString(Marker))
  add(query_602577, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602577, "Action", newJString(Action))
  add(query_602577, "Version", newJString(Version))
  if Filters != nil:
    query_602577.add "Filters", Filters
  add(query_602577, "MaxRecords", newJInt(MaxRecords))
  result = call_602576.call(nil, query_602577, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_602559(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_602560, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_602561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_602618 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBClusterParameters_602620(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBClusterParameters_602619(path: JsonNode;
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
  var valid_602621 = query.getOrDefault("Action")
  valid_602621 = validateParameter(valid_602621, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_602621 != nil:
    section.add "Action", valid_602621
  var valid_602622 = query.getOrDefault("Version")
  valid_602622 = validateParameter(valid_602622, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602622 != nil:
    section.add "Version", valid_602622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602623 = header.getOrDefault("X-Amz-Signature")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Signature", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Content-Sha256", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Date")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Date", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Credential")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Credential", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Security-Token")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Security-Token", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Algorithm")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Algorithm", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-SignedHeaders", valid_602629
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
  var valid_602630 = formData.getOrDefault("Source")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "Source", valid_602630
  var valid_602631 = formData.getOrDefault("MaxRecords")
  valid_602631 = validateParameter(valid_602631, JInt, required = false, default = nil)
  if valid_602631 != nil:
    section.add "MaxRecords", valid_602631
  var valid_602632 = formData.getOrDefault("Marker")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "Marker", valid_602632
  var valid_602633 = formData.getOrDefault("Filters")
  valid_602633 = validateParameter(valid_602633, JArray, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "Filters", valid_602633
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_602634 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_602634 = validateParameter(valid_602634, JString, required = true,
                                 default = nil)
  if valid_602634 != nil:
    section.add "DBClusterParameterGroupName", valid_602634
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602635: Call_PostDescribeDBClusterParameters_602618;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_602635.validator(path, query, header, formData, body)
  let scheme = call_602635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602635.url(scheme.get, call_602635.host, call_602635.base,
                         call_602635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602635, url, valid)

proc call*(call_602636: Call_PostDescribeDBClusterParameters_602618;
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
  var query_602637 = newJObject()
  var formData_602638 = newJObject()
  add(formData_602638, "Source", newJString(Source))
  add(formData_602638, "MaxRecords", newJInt(MaxRecords))
  add(formData_602638, "Marker", newJString(Marker))
  add(query_602637, "Action", newJString(Action))
  if Filters != nil:
    formData_602638.add "Filters", Filters
  add(formData_602638, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602637, "Version", newJString(Version))
  result = call_602636.call(nil, query_602637, nil, formData_602638, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_602618(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_602619, base: "/",
    url: url_PostDescribeDBClusterParameters_602620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_602598 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBClusterParameters_602600(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBClusterParameters_602599(path: JsonNode;
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
  var valid_602601 = query.getOrDefault("Marker")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "Marker", valid_602601
  var valid_602602 = query.getOrDefault("Source")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "Source", valid_602602
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_602603 = query.getOrDefault("DBClusterParameterGroupName")
  valid_602603 = validateParameter(valid_602603, JString, required = true,
                                 default = nil)
  if valid_602603 != nil:
    section.add "DBClusterParameterGroupName", valid_602603
  var valid_602604 = query.getOrDefault("Action")
  valid_602604 = validateParameter(valid_602604, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_602604 != nil:
    section.add "Action", valid_602604
  var valid_602605 = query.getOrDefault("Version")
  valid_602605 = validateParameter(valid_602605, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602605 != nil:
    section.add "Version", valid_602605
  var valid_602606 = query.getOrDefault("Filters")
  valid_602606 = validateParameter(valid_602606, JArray, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "Filters", valid_602606
  var valid_602607 = query.getOrDefault("MaxRecords")
  valid_602607 = validateParameter(valid_602607, JInt, required = false, default = nil)
  if valid_602607 != nil:
    section.add "MaxRecords", valid_602607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602608 = header.getOrDefault("X-Amz-Signature")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Signature", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Content-Sha256", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Date")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Date", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Credential")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Credential", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Security-Token")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Security-Token", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Algorithm")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Algorithm", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-SignedHeaders", valid_602614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602615: Call_GetDescribeDBClusterParameters_602598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_602615.validator(path, query, header, formData, body)
  let scheme = call_602615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602615.url(scheme.get, call_602615.host, call_602615.base,
                         call_602615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602615, url, valid)

proc call*(call_602616: Call_GetDescribeDBClusterParameters_602598;
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
  var query_602617 = newJObject()
  add(query_602617, "Marker", newJString(Marker))
  add(query_602617, "Source", newJString(Source))
  add(query_602617, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_602617, "Action", newJString(Action))
  add(query_602617, "Version", newJString(Version))
  if Filters != nil:
    query_602617.add "Filters", Filters
  add(query_602617, "MaxRecords", newJInt(MaxRecords))
  result = call_602616.call(nil, query_602617, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_602598(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_602599, base: "/",
    url: url_GetDescribeDBClusterParameters_602600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_602655 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBClusterSnapshotAttributes_602657(protocol: Scheme;
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

proc validate_PostDescribeDBClusterSnapshotAttributes_602656(path: JsonNode;
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
  var valid_602658 = query.getOrDefault("Action")
  valid_602658 = validateParameter(valid_602658, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_602658 != nil:
    section.add "Action", valid_602658
  var valid_602659 = query.getOrDefault("Version")
  valid_602659 = validateParameter(valid_602659, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602659 != nil:
    section.add "Version", valid_602659
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602660 = header.getOrDefault("X-Amz-Signature")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Signature", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Content-Sha256", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Date")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Date", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-Credential")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Credential", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Security-Token")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Security-Token", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Algorithm")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Algorithm", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-SignedHeaders", valid_602666
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_602667 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602667 = validateParameter(valid_602667, JString, required = true,
                                 default = nil)
  if valid_602667 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602667
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602668: Call_PostDescribeDBClusterSnapshotAttributes_602655;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_602668.validator(path, query, header, formData, body)
  let scheme = call_602668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602668.url(scheme.get, call_602668.host, call_602668.base,
                         call_602668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602668, url, valid)

proc call*(call_602669: Call_PostDescribeDBClusterSnapshotAttributes_602655;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602670 = newJObject()
  var formData_602671 = newJObject()
  add(formData_602671, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_602670, "Action", newJString(Action))
  add(query_602670, "Version", newJString(Version))
  result = call_602669.call(nil, query_602670, nil, formData_602671, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_602655(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_602656, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_602657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_602639 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBClusterSnapshotAttributes_602641(protocol: Scheme;
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

proc validate_GetDescribeDBClusterSnapshotAttributes_602640(path: JsonNode;
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
  var valid_602642 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602642 = validateParameter(valid_602642, JString, required = true,
                                 default = nil)
  if valid_602642 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602642
  var valid_602643 = query.getOrDefault("Action")
  valid_602643 = validateParameter(valid_602643, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_602643 != nil:
    section.add "Action", valid_602643
  var valid_602644 = query.getOrDefault("Version")
  valid_602644 = validateParameter(valid_602644, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602644 != nil:
    section.add "Version", valid_602644
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602645 = header.getOrDefault("X-Amz-Signature")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Signature", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Content-Sha256", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Date")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Date", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Credential")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Credential", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Security-Token")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Security-Token", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Algorithm")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Algorithm", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-SignedHeaders", valid_602651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602652: Call_GetDescribeDBClusterSnapshotAttributes_602639;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_602652.validator(path, query, header, formData, body)
  let scheme = call_602652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602652.url(scheme.get, call_602652.host, call_602652.base,
                         call_602652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602652, url, valid)

proc call*(call_602653: Call_GetDescribeDBClusterSnapshotAttributes_602639;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602654 = newJObject()
  add(query_602654, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_602654, "Action", newJString(Action))
  add(query_602654, "Version", newJString(Version))
  result = call_602653.call(nil, query_602654, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_602639(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_602640, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_602641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_602695 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBClusterSnapshots_602697(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBClusterSnapshots_602696(path: JsonNode;
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
  var valid_602698 = query.getOrDefault("Action")
  valid_602698 = validateParameter(valid_602698, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_602698 != nil:
    section.add "Action", valid_602698
  var valid_602699 = query.getOrDefault("Version")
  valid_602699 = validateParameter(valid_602699, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602699 != nil:
    section.add "Version", valid_602699
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602700 = header.getOrDefault("X-Amz-Signature")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Signature", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Content-Sha256", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-Date")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Date", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-Credential")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-Credential", valid_602703
  var valid_602704 = header.getOrDefault("X-Amz-Security-Token")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Security-Token", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-Algorithm")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-Algorithm", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-SignedHeaders", valid_602706
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
  var valid_602707 = formData.getOrDefault("SnapshotType")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "SnapshotType", valid_602707
  var valid_602708 = formData.getOrDefault("MaxRecords")
  valid_602708 = validateParameter(valid_602708, JInt, required = false, default = nil)
  if valid_602708 != nil:
    section.add "MaxRecords", valid_602708
  var valid_602709 = formData.getOrDefault("IncludePublic")
  valid_602709 = validateParameter(valid_602709, JBool, required = false, default = nil)
  if valid_602709 != nil:
    section.add "IncludePublic", valid_602709
  var valid_602710 = formData.getOrDefault("Marker")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "Marker", valid_602710
  var valid_602711 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602711
  var valid_602712 = formData.getOrDefault("IncludeShared")
  valid_602712 = validateParameter(valid_602712, JBool, required = false, default = nil)
  if valid_602712 != nil:
    section.add "IncludeShared", valid_602712
  var valid_602713 = formData.getOrDefault("Filters")
  valid_602713 = validateParameter(valid_602713, JArray, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "Filters", valid_602713
  var valid_602714 = formData.getOrDefault("DBClusterIdentifier")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "DBClusterIdentifier", valid_602714
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602715: Call_PostDescribeDBClusterSnapshots_602695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_602715.validator(path, query, header, formData, body)
  let scheme = call_602715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602715.url(scheme.get, call_602715.host, call_602715.base,
                         call_602715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602715, url, valid)

proc call*(call_602716: Call_PostDescribeDBClusterSnapshots_602695;
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
  var query_602717 = newJObject()
  var formData_602718 = newJObject()
  add(formData_602718, "SnapshotType", newJString(SnapshotType))
  add(formData_602718, "MaxRecords", newJInt(MaxRecords))
  add(formData_602718, "IncludePublic", newJBool(IncludePublic))
  add(formData_602718, "Marker", newJString(Marker))
  add(formData_602718, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_602718, "IncludeShared", newJBool(IncludeShared))
  add(query_602717, "Action", newJString(Action))
  if Filters != nil:
    formData_602718.add "Filters", Filters
  add(query_602717, "Version", newJString(Version))
  add(formData_602718, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_602716.call(nil, query_602717, nil, formData_602718, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_602695(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_602696, base: "/",
    url: url_PostDescribeDBClusterSnapshots_602697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_602672 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBClusterSnapshots_602674(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBClusterSnapshots_602673(path: JsonNode; query: JsonNode;
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
  var valid_602675 = query.getOrDefault("Marker")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "Marker", valid_602675
  var valid_602676 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_602676
  var valid_602677 = query.getOrDefault("DBClusterIdentifier")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "DBClusterIdentifier", valid_602677
  var valid_602678 = query.getOrDefault("SnapshotType")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "SnapshotType", valid_602678
  var valid_602679 = query.getOrDefault("IncludePublic")
  valid_602679 = validateParameter(valid_602679, JBool, required = false, default = nil)
  if valid_602679 != nil:
    section.add "IncludePublic", valid_602679
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602680 = query.getOrDefault("Action")
  valid_602680 = validateParameter(valid_602680, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_602680 != nil:
    section.add "Action", valid_602680
  var valid_602681 = query.getOrDefault("IncludeShared")
  valid_602681 = validateParameter(valid_602681, JBool, required = false, default = nil)
  if valid_602681 != nil:
    section.add "IncludeShared", valid_602681
  var valid_602682 = query.getOrDefault("Version")
  valid_602682 = validateParameter(valid_602682, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602682 != nil:
    section.add "Version", valid_602682
  var valid_602683 = query.getOrDefault("Filters")
  valid_602683 = validateParameter(valid_602683, JArray, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "Filters", valid_602683
  var valid_602684 = query.getOrDefault("MaxRecords")
  valid_602684 = validateParameter(valid_602684, JInt, required = false, default = nil)
  if valid_602684 != nil:
    section.add "MaxRecords", valid_602684
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602685 = header.getOrDefault("X-Amz-Signature")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Signature", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Content-Sha256", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-Date")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Date", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-Credential")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Credential", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Security-Token")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Security-Token", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Algorithm")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Algorithm", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-SignedHeaders", valid_602691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602692: Call_GetDescribeDBClusterSnapshots_602672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_602692.validator(path, query, header, formData, body)
  let scheme = call_602692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602692.url(scheme.get, call_602692.host, call_602692.base,
                         call_602692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602692, url, valid)

proc call*(call_602693: Call_GetDescribeDBClusterSnapshots_602672;
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
  var query_602694 = newJObject()
  add(query_602694, "Marker", newJString(Marker))
  add(query_602694, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_602694, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602694, "SnapshotType", newJString(SnapshotType))
  add(query_602694, "IncludePublic", newJBool(IncludePublic))
  add(query_602694, "Action", newJString(Action))
  add(query_602694, "IncludeShared", newJBool(IncludeShared))
  add(query_602694, "Version", newJString(Version))
  if Filters != nil:
    query_602694.add "Filters", Filters
  add(query_602694, "MaxRecords", newJInt(MaxRecords))
  result = call_602693.call(nil, query_602694, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_602672(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_602673, base: "/",
    url: url_GetDescribeDBClusterSnapshots_602674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_602738 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBClusters_602740(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBClusters_602739(path: JsonNode; query: JsonNode;
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
  var valid_602741 = query.getOrDefault("Action")
  valid_602741 = validateParameter(valid_602741, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_602741 != nil:
    section.add "Action", valid_602741
  var valid_602742 = query.getOrDefault("Version")
  valid_602742 = validateParameter(valid_602742, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602742 != nil:
    section.add "Version", valid_602742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602743 = header.getOrDefault("X-Amz-Signature")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-Signature", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Content-Sha256", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Date")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Date", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-Credential")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-Credential", valid_602746
  var valid_602747 = header.getOrDefault("X-Amz-Security-Token")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-Security-Token", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-Algorithm")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Algorithm", valid_602748
  var valid_602749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-SignedHeaders", valid_602749
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
  var valid_602750 = formData.getOrDefault("MaxRecords")
  valid_602750 = validateParameter(valid_602750, JInt, required = false, default = nil)
  if valid_602750 != nil:
    section.add "MaxRecords", valid_602750
  var valid_602751 = formData.getOrDefault("Marker")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "Marker", valid_602751
  var valid_602752 = formData.getOrDefault("Filters")
  valid_602752 = validateParameter(valid_602752, JArray, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "Filters", valid_602752
  var valid_602753 = formData.getOrDefault("DBClusterIdentifier")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "DBClusterIdentifier", valid_602753
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602754: Call_PostDescribeDBClusters_602738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_602754.validator(path, query, header, formData, body)
  let scheme = call_602754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602754.url(scheme.get, call_602754.host, call_602754.base,
                         call_602754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602754, url, valid)

proc call*(call_602755: Call_PostDescribeDBClusters_602738; MaxRecords: int = 0;
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
  var query_602756 = newJObject()
  var formData_602757 = newJObject()
  add(formData_602757, "MaxRecords", newJInt(MaxRecords))
  add(formData_602757, "Marker", newJString(Marker))
  add(query_602756, "Action", newJString(Action))
  if Filters != nil:
    formData_602757.add "Filters", Filters
  add(query_602756, "Version", newJString(Version))
  add(formData_602757, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_602755.call(nil, query_602756, nil, formData_602757, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_602738(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_602739, base: "/",
    url: url_PostDescribeDBClusters_602740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_602719 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBClusters_602721(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBClusters_602720(path: JsonNode; query: JsonNode;
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
  var valid_602722 = query.getOrDefault("Marker")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "Marker", valid_602722
  var valid_602723 = query.getOrDefault("DBClusterIdentifier")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "DBClusterIdentifier", valid_602723
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602724 = query.getOrDefault("Action")
  valid_602724 = validateParameter(valid_602724, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_602724 != nil:
    section.add "Action", valid_602724
  var valid_602725 = query.getOrDefault("Version")
  valid_602725 = validateParameter(valid_602725, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602725 != nil:
    section.add "Version", valid_602725
  var valid_602726 = query.getOrDefault("Filters")
  valid_602726 = validateParameter(valid_602726, JArray, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "Filters", valid_602726
  var valid_602727 = query.getOrDefault("MaxRecords")
  valid_602727 = validateParameter(valid_602727, JInt, required = false, default = nil)
  if valid_602727 != nil:
    section.add "MaxRecords", valid_602727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602728 = header.getOrDefault("X-Amz-Signature")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Signature", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Content-Sha256", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-Date")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-Date", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-Credential")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Credential", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-Security-Token")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-Security-Token", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-Algorithm")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Algorithm", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-SignedHeaders", valid_602734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602735: Call_GetDescribeDBClusters_602719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_602735.validator(path, query, header, formData, body)
  let scheme = call_602735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602735.url(scheme.get, call_602735.host, call_602735.base,
                         call_602735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602735, url, valid)

proc call*(call_602736: Call_GetDescribeDBClusters_602719; Marker: string = "";
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
  var query_602737 = newJObject()
  add(query_602737, "Marker", newJString(Marker))
  add(query_602737, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_602737, "Action", newJString(Action))
  add(query_602737, "Version", newJString(Version))
  if Filters != nil:
    query_602737.add "Filters", Filters
  add(query_602737, "MaxRecords", newJInt(MaxRecords))
  result = call_602736.call(nil, query_602737, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_602719(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_602720, base: "/",
    url: url_GetDescribeDBClusters_602721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_602782 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBEngineVersions_602784(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_602783(path: JsonNode; query: JsonNode;
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
  var valid_602785 = query.getOrDefault("Action")
  valid_602785 = validateParameter(valid_602785, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_602785 != nil:
    section.add "Action", valid_602785
  var valid_602786 = query.getOrDefault("Version")
  valid_602786 = validateParameter(valid_602786, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602786 != nil:
    section.add "Version", valid_602786
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602787 = header.getOrDefault("X-Amz-Signature")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Signature", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Content-Sha256", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-Date")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-Date", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Credential")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Credential", valid_602790
  var valid_602791 = header.getOrDefault("X-Amz-Security-Token")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "X-Amz-Security-Token", valid_602791
  var valid_602792 = header.getOrDefault("X-Amz-Algorithm")
  valid_602792 = validateParameter(valid_602792, JString, required = false,
                                 default = nil)
  if valid_602792 != nil:
    section.add "X-Amz-Algorithm", valid_602792
  var valid_602793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602793 = validateParameter(valid_602793, JString, required = false,
                                 default = nil)
  if valid_602793 != nil:
    section.add "X-Amz-SignedHeaders", valid_602793
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
  var valid_602794 = formData.getOrDefault("DefaultOnly")
  valid_602794 = validateParameter(valid_602794, JBool, required = false, default = nil)
  if valid_602794 != nil:
    section.add "DefaultOnly", valid_602794
  var valid_602795 = formData.getOrDefault("MaxRecords")
  valid_602795 = validateParameter(valid_602795, JInt, required = false, default = nil)
  if valid_602795 != nil:
    section.add "MaxRecords", valid_602795
  var valid_602796 = formData.getOrDefault("EngineVersion")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "EngineVersion", valid_602796
  var valid_602797 = formData.getOrDefault("Marker")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "Marker", valid_602797
  var valid_602798 = formData.getOrDefault("Engine")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "Engine", valid_602798
  var valid_602799 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_602799 = validateParameter(valid_602799, JBool, required = false, default = nil)
  if valid_602799 != nil:
    section.add "ListSupportedCharacterSets", valid_602799
  var valid_602800 = formData.getOrDefault("ListSupportedTimezones")
  valid_602800 = validateParameter(valid_602800, JBool, required = false, default = nil)
  if valid_602800 != nil:
    section.add "ListSupportedTimezones", valid_602800
  var valid_602801 = formData.getOrDefault("Filters")
  valid_602801 = validateParameter(valid_602801, JArray, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "Filters", valid_602801
  var valid_602802 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "DBParameterGroupFamily", valid_602802
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602803: Call_PostDescribeDBEngineVersions_602782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_602803.validator(path, query, header, formData, body)
  let scheme = call_602803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602803.url(scheme.get, call_602803.host, call_602803.base,
                         call_602803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602803, url, valid)

proc call*(call_602804: Call_PostDescribeDBEngineVersions_602782;
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
  var query_602805 = newJObject()
  var formData_602806 = newJObject()
  add(formData_602806, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_602806, "MaxRecords", newJInt(MaxRecords))
  add(formData_602806, "EngineVersion", newJString(EngineVersion))
  add(formData_602806, "Marker", newJString(Marker))
  add(formData_602806, "Engine", newJString(Engine))
  add(formData_602806, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_602805, "Action", newJString(Action))
  add(formData_602806, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  if Filters != nil:
    formData_602806.add "Filters", Filters
  add(query_602805, "Version", newJString(Version))
  add(formData_602806, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_602804.call(nil, query_602805, nil, formData_602806, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_602782(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_602783, base: "/",
    url: url_PostDescribeDBEngineVersions_602784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_602758 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBEngineVersions_602760(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_602759(path: JsonNode; query: JsonNode;
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
  var valid_602761 = query.getOrDefault("Marker")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "Marker", valid_602761
  var valid_602762 = query.getOrDefault("ListSupportedTimezones")
  valid_602762 = validateParameter(valid_602762, JBool, required = false, default = nil)
  if valid_602762 != nil:
    section.add "ListSupportedTimezones", valid_602762
  var valid_602763 = query.getOrDefault("DBParameterGroupFamily")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "DBParameterGroupFamily", valid_602763
  var valid_602764 = query.getOrDefault("Engine")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "Engine", valid_602764
  var valid_602765 = query.getOrDefault("EngineVersion")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "EngineVersion", valid_602765
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602766 = query.getOrDefault("Action")
  valid_602766 = validateParameter(valid_602766, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_602766 != nil:
    section.add "Action", valid_602766
  var valid_602767 = query.getOrDefault("ListSupportedCharacterSets")
  valid_602767 = validateParameter(valid_602767, JBool, required = false, default = nil)
  if valid_602767 != nil:
    section.add "ListSupportedCharacterSets", valid_602767
  var valid_602768 = query.getOrDefault("Version")
  valid_602768 = validateParameter(valid_602768, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602768 != nil:
    section.add "Version", valid_602768
  var valid_602769 = query.getOrDefault("Filters")
  valid_602769 = validateParameter(valid_602769, JArray, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "Filters", valid_602769
  var valid_602770 = query.getOrDefault("MaxRecords")
  valid_602770 = validateParameter(valid_602770, JInt, required = false, default = nil)
  if valid_602770 != nil:
    section.add "MaxRecords", valid_602770
  var valid_602771 = query.getOrDefault("DefaultOnly")
  valid_602771 = validateParameter(valid_602771, JBool, required = false, default = nil)
  if valid_602771 != nil:
    section.add "DefaultOnly", valid_602771
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602772 = header.getOrDefault("X-Amz-Signature")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Signature", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Content-Sha256", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Date")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Date", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-Credential")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Credential", valid_602775
  var valid_602776 = header.getOrDefault("X-Amz-Security-Token")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "X-Amz-Security-Token", valid_602776
  var valid_602777 = header.getOrDefault("X-Amz-Algorithm")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "X-Amz-Algorithm", valid_602777
  var valid_602778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "X-Amz-SignedHeaders", valid_602778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602779: Call_GetDescribeDBEngineVersions_602758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_602779.validator(path, query, header, formData, body)
  let scheme = call_602779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602779.url(scheme.get, call_602779.host, call_602779.base,
                         call_602779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602779, url, valid)

proc call*(call_602780: Call_GetDescribeDBEngineVersions_602758;
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
  var query_602781 = newJObject()
  add(query_602781, "Marker", newJString(Marker))
  add(query_602781, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_602781, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602781, "Engine", newJString(Engine))
  add(query_602781, "EngineVersion", newJString(EngineVersion))
  add(query_602781, "Action", newJString(Action))
  add(query_602781, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_602781, "Version", newJString(Version))
  if Filters != nil:
    query_602781.add "Filters", Filters
  add(query_602781, "MaxRecords", newJInt(MaxRecords))
  add(query_602781, "DefaultOnly", newJBool(DefaultOnly))
  result = call_602780.call(nil, query_602781, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_602758(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_602759, base: "/",
    url: url_GetDescribeDBEngineVersions_602760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_602826 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBInstances_602828(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_602827(path: JsonNode; query: JsonNode;
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
  var valid_602829 = query.getOrDefault("Action")
  valid_602829 = validateParameter(valid_602829, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_602829 != nil:
    section.add "Action", valid_602829
  var valid_602830 = query.getOrDefault("Version")
  valid_602830 = validateParameter(valid_602830, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602830 != nil:
    section.add "Version", valid_602830
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602831 = header.getOrDefault("X-Amz-Signature")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-Signature", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Content-Sha256", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Date")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Date", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-Credential")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Credential", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Security-Token")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Security-Token", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Algorithm")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Algorithm", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-SignedHeaders", valid_602837
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
  var valid_602838 = formData.getOrDefault("MaxRecords")
  valid_602838 = validateParameter(valid_602838, JInt, required = false, default = nil)
  if valid_602838 != nil:
    section.add "MaxRecords", valid_602838
  var valid_602839 = formData.getOrDefault("Marker")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "Marker", valid_602839
  var valid_602840 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "DBInstanceIdentifier", valid_602840
  var valid_602841 = formData.getOrDefault("Filters")
  valid_602841 = validateParameter(valid_602841, JArray, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "Filters", valid_602841
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602842: Call_PostDescribeDBInstances_602826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_602842.validator(path, query, header, formData, body)
  let scheme = call_602842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602842.url(scheme.get, call_602842.host, call_602842.base,
                         call_602842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602842, url, valid)

proc call*(call_602843: Call_PostDescribeDBInstances_602826; MaxRecords: int = 0;
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
  var query_602844 = newJObject()
  var formData_602845 = newJObject()
  add(formData_602845, "MaxRecords", newJInt(MaxRecords))
  add(formData_602845, "Marker", newJString(Marker))
  add(formData_602845, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602844, "Action", newJString(Action))
  if Filters != nil:
    formData_602845.add "Filters", Filters
  add(query_602844, "Version", newJString(Version))
  result = call_602843.call(nil, query_602844, nil, formData_602845, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_602826(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_602827, base: "/",
    url: url_PostDescribeDBInstances_602828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_602807 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBInstances_602809(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_602808(path: JsonNode; query: JsonNode;
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
  var valid_602810 = query.getOrDefault("Marker")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "Marker", valid_602810
  var valid_602811 = query.getOrDefault("DBInstanceIdentifier")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "DBInstanceIdentifier", valid_602811
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602812 = query.getOrDefault("Action")
  valid_602812 = validateParameter(valid_602812, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_602812 != nil:
    section.add "Action", valid_602812
  var valid_602813 = query.getOrDefault("Version")
  valid_602813 = validateParameter(valid_602813, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602813 != nil:
    section.add "Version", valid_602813
  var valid_602814 = query.getOrDefault("Filters")
  valid_602814 = validateParameter(valid_602814, JArray, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "Filters", valid_602814
  var valid_602815 = query.getOrDefault("MaxRecords")
  valid_602815 = validateParameter(valid_602815, JInt, required = false, default = nil)
  if valid_602815 != nil:
    section.add "MaxRecords", valid_602815
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602816 = header.getOrDefault("X-Amz-Signature")
  valid_602816 = validateParameter(valid_602816, JString, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "X-Amz-Signature", valid_602816
  var valid_602817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "X-Amz-Content-Sha256", valid_602817
  var valid_602818 = header.getOrDefault("X-Amz-Date")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Date", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Credential")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Credential", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Security-Token")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Security-Token", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Algorithm")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Algorithm", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-SignedHeaders", valid_602822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602823: Call_GetDescribeDBInstances_602807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_602823.validator(path, query, header, formData, body)
  let scheme = call_602823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602823.url(scheme.get, call_602823.host, call_602823.base,
                         call_602823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602823, url, valid)

proc call*(call_602824: Call_GetDescribeDBInstances_602807; Marker: string = "";
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
  var query_602825 = newJObject()
  add(query_602825, "Marker", newJString(Marker))
  add(query_602825, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602825, "Action", newJString(Action))
  add(query_602825, "Version", newJString(Version))
  if Filters != nil:
    query_602825.add "Filters", Filters
  add(query_602825, "MaxRecords", newJInt(MaxRecords))
  result = call_602824.call(nil, query_602825, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_602807(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_602808, base: "/",
    url: url_GetDescribeDBInstances_602809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_602865 = ref object of OpenApiRestCall_601373
proc url_PostDescribeDBSubnetGroups_602867(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_602866(path: JsonNode; query: JsonNode;
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
  var valid_602868 = query.getOrDefault("Action")
  valid_602868 = validateParameter(valid_602868, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602868 != nil:
    section.add "Action", valid_602868
  var valid_602869 = query.getOrDefault("Version")
  valid_602869 = validateParameter(valid_602869, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602869 != nil:
    section.add "Version", valid_602869
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602870 = header.getOrDefault("X-Amz-Signature")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "X-Amz-Signature", valid_602870
  var valid_602871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Content-Sha256", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Date")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Date", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Credential")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Credential", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Security-Token")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Security-Token", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Algorithm")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Algorithm", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-SignedHeaders", valid_602876
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
  var valid_602877 = formData.getOrDefault("MaxRecords")
  valid_602877 = validateParameter(valid_602877, JInt, required = false, default = nil)
  if valid_602877 != nil:
    section.add "MaxRecords", valid_602877
  var valid_602878 = formData.getOrDefault("Marker")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "Marker", valid_602878
  var valid_602879 = formData.getOrDefault("DBSubnetGroupName")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "DBSubnetGroupName", valid_602879
  var valid_602880 = formData.getOrDefault("Filters")
  valid_602880 = validateParameter(valid_602880, JArray, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "Filters", valid_602880
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602881: Call_PostDescribeDBSubnetGroups_602865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_602881.validator(path, query, header, formData, body)
  let scheme = call_602881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602881.url(scheme.get, call_602881.host, call_602881.base,
                         call_602881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602881, url, valid)

proc call*(call_602882: Call_PostDescribeDBSubnetGroups_602865;
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
  var query_602883 = newJObject()
  var formData_602884 = newJObject()
  add(formData_602884, "MaxRecords", newJInt(MaxRecords))
  add(formData_602884, "Marker", newJString(Marker))
  add(query_602883, "Action", newJString(Action))
  add(formData_602884, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_602884.add "Filters", Filters
  add(query_602883, "Version", newJString(Version))
  result = call_602882.call(nil, query_602883, nil, formData_602884, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_602865(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_602866, base: "/",
    url: url_PostDescribeDBSubnetGroups_602867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_602846 = ref object of OpenApiRestCall_601373
proc url_GetDescribeDBSubnetGroups_602848(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_602847(path: JsonNode; query: JsonNode;
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
  var valid_602849 = query.getOrDefault("Marker")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "Marker", valid_602849
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602850 = query.getOrDefault("Action")
  valid_602850 = validateParameter(valid_602850, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602850 != nil:
    section.add "Action", valid_602850
  var valid_602851 = query.getOrDefault("DBSubnetGroupName")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "DBSubnetGroupName", valid_602851
  var valid_602852 = query.getOrDefault("Version")
  valid_602852 = validateParameter(valid_602852, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602852 != nil:
    section.add "Version", valid_602852
  var valid_602853 = query.getOrDefault("Filters")
  valid_602853 = validateParameter(valid_602853, JArray, required = false,
                                 default = nil)
  if valid_602853 != nil:
    section.add "Filters", valid_602853
  var valid_602854 = query.getOrDefault("MaxRecords")
  valid_602854 = validateParameter(valid_602854, JInt, required = false, default = nil)
  if valid_602854 != nil:
    section.add "MaxRecords", valid_602854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602855 = header.getOrDefault("X-Amz-Signature")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "X-Amz-Signature", valid_602855
  var valid_602856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "X-Amz-Content-Sha256", valid_602856
  var valid_602857 = header.getOrDefault("X-Amz-Date")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Date", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-Credential")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Credential", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Security-Token")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Security-Token", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Algorithm")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Algorithm", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-SignedHeaders", valid_602861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602862: Call_GetDescribeDBSubnetGroups_602846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_602862.validator(path, query, header, formData, body)
  let scheme = call_602862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602862.url(scheme.get, call_602862.host, call_602862.base,
                         call_602862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602862, url, valid)

proc call*(call_602863: Call_GetDescribeDBSubnetGroups_602846; Marker: string = "";
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
  var query_602864 = newJObject()
  add(query_602864, "Marker", newJString(Marker))
  add(query_602864, "Action", newJString(Action))
  add(query_602864, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602864, "Version", newJString(Version))
  if Filters != nil:
    query_602864.add "Filters", Filters
  add(query_602864, "MaxRecords", newJInt(MaxRecords))
  result = call_602863.call(nil, query_602864, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_602846(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_602847, base: "/",
    url: url_GetDescribeDBSubnetGroups_602848,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_602904 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEngineDefaultClusterParameters_602906(protocol: Scheme;
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

proc validate_PostDescribeEngineDefaultClusterParameters_602905(path: JsonNode;
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
  var valid_602907 = query.getOrDefault("Action")
  valid_602907 = validateParameter(valid_602907, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_602907 != nil:
    section.add "Action", valid_602907
  var valid_602908 = query.getOrDefault("Version")
  valid_602908 = validateParameter(valid_602908, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602908 != nil:
    section.add "Version", valid_602908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602909 = header.getOrDefault("X-Amz-Signature")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Signature", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Content-Sha256", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Date")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Date", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Credential")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Credential", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-Security-Token")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Security-Token", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Algorithm")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Algorithm", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-SignedHeaders", valid_602915
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
  var valid_602916 = formData.getOrDefault("MaxRecords")
  valid_602916 = validateParameter(valid_602916, JInt, required = false, default = nil)
  if valid_602916 != nil:
    section.add "MaxRecords", valid_602916
  var valid_602917 = formData.getOrDefault("Marker")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "Marker", valid_602917
  var valid_602918 = formData.getOrDefault("Filters")
  valid_602918 = validateParameter(valid_602918, JArray, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "Filters", valid_602918
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602919 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602919 = validateParameter(valid_602919, JString, required = true,
                                 default = nil)
  if valid_602919 != nil:
    section.add "DBParameterGroupFamily", valid_602919
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602920: Call_PostDescribeEngineDefaultClusterParameters_602904;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_602920.validator(path, query, header, formData, body)
  let scheme = call_602920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602920.url(scheme.get, call_602920.host, call_602920.base,
                         call_602920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602920, url, valid)

proc call*(call_602921: Call_PostDescribeEngineDefaultClusterParameters_602904;
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
  var query_602922 = newJObject()
  var formData_602923 = newJObject()
  add(formData_602923, "MaxRecords", newJInt(MaxRecords))
  add(formData_602923, "Marker", newJString(Marker))
  add(query_602922, "Action", newJString(Action))
  if Filters != nil:
    formData_602923.add "Filters", Filters
  add(query_602922, "Version", newJString(Version))
  add(formData_602923, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_602921.call(nil, query_602922, nil, formData_602923, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_602904(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_602905,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_602906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_602885 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEngineDefaultClusterParameters_602887(protocol: Scheme;
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

proc validate_GetDescribeEngineDefaultClusterParameters_602886(path: JsonNode;
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
  var valid_602888 = query.getOrDefault("Marker")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "Marker", valid_602888
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602889 = query.getOrDefault("DBParameterGroupFamily")
  valid_602889 = validateParameter(valid_602889, JString, required = true,
                                 default = nil)
  if valid_602889 != nil:
    section.add "DBParameterGroupFamily", valid_602889
  var valid_602890 = query.getOrDefault("Action")
  valid_602890 = validateParameter(valid_602890, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_602890 != nil:
    section.add "Action", valid_602890
  var valid_602891 = query.getOrDefault("Version")
  valid_602891 = validateParameter(valid_602891, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602891 != nil:
    section.add "Version", valid_602891
  var valid_602892 = query.getOrDefault("Filters")
  valid_602892 = validateParameter(valid_602892, JArray, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "Filters", valid_602892
  var valid_602893 = query.getOrDefault("MaxRecords")
  valid_602893 = validateParameter(valid_602893, JInt, required = false, default = nil)
  if valid_602893 != nil:
    section.add "MaxRecords", valid_602893
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602894 = header.getOrDefault("X-Amz-Signature")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Signature", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Content-Sha256", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Date")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Date", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-Credential")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-Credential", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-Security-Token")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Security-Token", valid_602898
  var valid_602899 = header.getOrDefault("X-Amz-Algorithm")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-Algorithm", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-SignedHeaders", valid_602900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602901: Call_GetDescribeEngineDefaultClusterParameters_602885;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_602901.validator(path, query, header, formData, body)
  let scheme = call_602901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602901.url(scheme.get, call_602901.host, call_602901.base,
                         call_602901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602901, url, valid)

proc call*(call_602902: Call_GetDescribeEngineDefaultClusterParameters_602885;
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
  var query_602903 = newJObject()
  add(query_602903, "Marker", newJString(Marker))
  add(query_602903, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602903, "Action", newJString(Action))
  add(query_602903, "Version", newJString(Version))
  if Filters != nil:
    query_602903.add "Filters", Filters
  add(query_602903, "MaxRecords", newJInt(MaxRecords))
  result = call_602902.call(nil, query_602903, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_602885(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_602886,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_602887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_602941 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEventCategories_602943(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_602942(path: JsonNode; query: JsonNode;
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
  var valid_602944 = query.getOrDefault("Action")
  valid_602944 = validateParameter(valid_602944, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602944 != nil:
    section.add "Action", valid_602944
  var valid_602945 = query.getOrDefault("Version")
  valid_602945 = validateParameter(valid_602945, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602945 != nil:
    section.add "Version", valid_602945
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602946 = header.getOrDefault("X-Amz-Signature")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-Signature", valid_602946
  var valid_602947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Content-Sha256", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-Date")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Date", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-Credential")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Credential", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Security-Token")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Security-Token", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-Algorithm")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-Algorithm", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-SignedHeaders", valid_602952
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  section = newJObject()
  var valid_602953 = formData.getOrDefault("SourceType")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "SourceType", valid_602953
  var valid_602954 = formData.getOrDefault("Filters")
  valid_602954 = validateParameter(valid_602954, JArray, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "Filters", valid_602954
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602955: Call_PostDescribeEventCategories_602941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_602955.validator(path, query, header, formData, body)
  let scheme = call_602955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602955.url(scheme.get, call_602955.host, call_602955.base,
                         call_602955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602955, url, valid)

proc call*(call_602956: Call_PostDescribeEventCategories_602941;
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
  var query_602957 = newJObject()
  var formData_602958 = newJObject()
  add(formData_602958, "SourceType", newJString(SourceType))
  add(query_602957, "Action", newJString(Action))
  if Filters != nil:
    formData_602958.add "Filters", Filters
  add(query_602957, "Version", newJString(Version))
  result = call_602956.call(nil, query_602957, nil, formData_602958, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_602941(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_602942, base: "/",
    url: url_PostDescribeEventCategories_602943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_602924 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEventCategories_602926(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_602925(path: JsonNode; query: JsonNode;
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
  var valid_602927 = query.getOrDefault("SourceType")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "SourceType", valid_602927
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602928 = query.getOrDefault("Action")
  valid_602928 = validateParameter(valid_602928, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602928 != nil:
    section.add "Action", valid_602928
  var valid_602929 = query.getOrDefault("Version")
  valid_602929 = validateParameter(valid_602929, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602929 != nil:
    section.add "Version", valid_602929
  var valid_602930 = query.getOrDefault("Filters")
  valid_602930 = validateParameter(valid_602930, JArray, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "Filters", valid_602930
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602931 = header.getOrDefault("X-Amz-Signature")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-Signature", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Content-Sha256", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Date")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Date", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Credential")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Credential", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Security-Token")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Security-Token", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Algorithm")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Algorithm", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-SignedHeaders", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602938: Call_GetDescribeEventCategories_602924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_602938.validator(path, query, header, formData, body)
  let scheme = call_602938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602938.url(scheme.get, call_602938.host, call_602938.base,
                         call_602938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602938, url, valid)

proc call*(call_602939: Call_GetDescribeEventCategories_602924;
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
  var query_602940 = newJObject()
  add(query_602940, "SourceType", newJString(SourceType))
  add(query_602940, "Action", newJString(Action))
  add(query_602940, "Version", newJString(Version))
  if Filters != nil:
    query_602940.add "Filters", Filters
  result = call_602939.call(nil, query_602940, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_602924(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_602925, base: "/",
    url: url_GetDescribeEventCategories_602926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602983 = ref object of OpenApiRestCall_601373
proc url_PostDescribeEvents_602985(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_602984(path: JsonNode; query: JsonNode;
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
  var valid_602986 = query.getOrDefault("Action")
  valid_602986 = validateParameter(valid_602986, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602986 != nil:
    section.add "Action", valid_602986
  var valid_602987 = query.getOrDefault("Version")
  valid_602987 = validateParameter(valid_602987, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602987 != nil:
    section.add "Version", valid_602987
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602988 = header.getOrDefault("X-Amz-Signature")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "X-Amz-Signature", valid_602988
  var valid_602989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602989 = validateParameter(valid_602989, JString, required = false,
                                 default = nil)
  if valid_602989 != nil:
    section.add "X-Amz-Content-Sha256", valid_602989
  var valid_602990 = header.getOrDefault("X-Amz-Date")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-Date", valid_602990
  var valid_602991 = header.getOrDefault("X-Amz-Credential")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-Credential", valid_602991
  var valid_602992 = header.getOrDefault("X-Amz-Security-Token")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "X-Amz-Security-Token", valid_602992
  var valid_602993 = header.getOrDefault("X-Amz-Algorithm")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-Algorithm", valid_602993
  var valid_602994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "X-Amz-SignedHeaders", valid_602994
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
  var valid_602995 = formData.getOrDefault("MaxRecords")
  valid_602995 = validateParameter(valid_602995, JInt, required = false, default = nil)
  if valid_602995 != nil:
    section.add "MaxRecords", valid_602995
  var valid_602996 = formData.getOrDefault("Marker")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "Marker", valid_602996
  var valid_602997 = formData.getOrDefault("SourceIdentifier")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "SourceIdentifier", valid_602997
  var valid_602998 = formData.getOrDefault("SourceType")
  valid_602998 = validateParameter(valid_602998, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602998 != nil:
    section.add "SourceType", valid_602998
  var valid_602999 = formData.getOrDefault("Duration")
  valid_602999 = validateParameter(valid_602999, JInt, required = false, default = nil)
  if valid_602999 != nil:
    section.add "Duration", valid_602999
  var valid_603000 = formData.getOrDefault("EndTime")
  valid_603000 = validateParameter(valid_603000, JString, required = false,
                                 default = nil)
  if valid_603000 != nil:
    section.add "EndTime", valid_603000
  var valid_603001 = formData.getOrDefault("StartTime")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "StartTime", valid_603001
  var valid_603002 = formData.getOrDefault("EventCategories")
  valid_603002 = validateParameter(valid_603002, JArray, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "EventCategories", valid_603002
  var valid_603003 = formData.getOrDefault("Filters")
  valid_603003 = validateParameter(valid_603003, JArray, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "Filters", valid_603003
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603004: Call_PostDescribeEvents_602983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_603004.validator(path, query, header, formData, body)
  let scheme = call_603004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603004.url(scheme.get, call_603004.host, call_603004.base,
                         call_603004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603004, url, valid)

proc call*(call_603005: Call_PostDescribeEvents_602983; MaxRecords: int = 0;
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
  var query_603006 = newJObject()
  var formData_603007 = newJObject()
  add(formData_603007, "MaxRecords", newJInt(MaxRecords))
  add(formData_603007, "Marker", newJString(Marker))
  add(formData_603007, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_603007, "SourceType", newJString(SourceType))
  add(formData_603007, "Duration", newJInt(Duration))
  add(formData_603007, "EndTime", newJString(EndTime))
  add(formData_603007, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_603007.add "EventCategories", EventCategories
  add(query_603006, "Action", newJString(Action))
  if Filters != nil:
    formData_603007.add "Filters", Filters
  add(query_603006, "Version", newJString(Version))
  result = call_603005.call(nil, query_603006, nil, formData_603007, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602983(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602984, base: "/",
    url: url_PostDescribeEvents_602985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602959 = ref object of OpenApiRestCall_601373
proc url_GetDescribeEvents_602961(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_602960(path: JsonNode; query: JsonNode;
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
  var valid_602962 = query.getOrDefault("Marker")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "Marker", valid_602962
  var valid_602963 = query.getOrDefault("SourceType")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602963 != nil:
    section.add "SourceType", valid_602963
  var valid_602964 = query.getOrDefault("SourceIdentifier")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "SourceIdentifier", valid_602964
  var valid_602965 = query.getOrDefault("EventCategories")
  valid_602965 = validateParameter(valid_602965, JArray, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "EventCategories", valid_602965
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602966 = query.getOrDefault("Action")
  valid_602966 = validateParameter(valid_602966, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602966 != nil:
    section.add "Action", valid_602966
  var valid_602967 = query.getOrDefault("StartTime")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "StartTime", valid_602967
  var valid_602968 = query.getOrDefault("Duration")
  valid_602968 = validateParameter(valid_602968, JInt, required = false, default = nil)
  if valid_602968 != nil:
    section.add "Duration", valid_602968
  var valid_602969 = query.getOrDefault("EndTime")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "EndTime", valid_602969
  var valid_602970 = query.getOrDefault("Version")
  valid_602970 = validateParameter(valid_602970, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_602970 != nil:
    section.add "Version", valid_602970
  var valid_602971 = query.getOrDefault("Filters")
  valid_602971 = validateParameter(valid_602971, JArray, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "Filters", valid_602971
  var valid_602972 = query.getOrDefault("MaxRecords")
  valid_602972 = validateParameter(valid_602972, JInt, required = false, default = nil)
  if valid_602972 != nil:
    section.add "MaxRecords", valid_602972
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602973 = header.getOrDefault("X-Amz-Signature")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "X-Amz-Signature", valid_602973
  var valid_602974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "X-Amz-Content-Sha256", valid_602974
  var valid_602975 = header.getOrDefault("X-Amz-Date")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Date", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Credential")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Credential", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Security-Token")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Security-Token", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-Algorithm")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-Algorithm", valid_602978
  var valid_602979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "X-Amz-SignedHeaders", valid_602979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602980: Call_GetDescribeEvents_602959; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_602980.validator(path, query, header, formData, body)
  let scheme = call_602980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602980.url(scheme.get, call_602980.host, call_602980.base,
                         call_602980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602980, url, valid)

proc call*(call_602981: Call_GetDescribeEvents_602959; Marker: string = "";
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
  var query_602982 = newJObject()
  add(query_602982, "Marker", newJString(Marker))
  add(query_602982, "SourceType", newJString(SourceType))
  add(query_602982, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_602982.add "EventCategories", EventCategories
  add(query_602982, "Action", newJString(Action))
  add(query_602982, "StartTime", newJString(StartTime))
  add(query_602982, "Duration", newJInt(Duration))
  add(query_602982, "EndTime", newJString(EndTime))
  add(query_602982, "Version", newJString(Version))
  if Filters != nil:
    query_602982.add "Filters", Filters
  add(query_602982, "MaxRecords", newJInt(MaxRecords))
  result = call_602981.call(nil, query_602982, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602959(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602960,
    base: "/", url: url_GetDescribeEvents_602961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_603031 = ref object of OpenApiRestCall_601373
proc url_PostDescribeOrderableDBInstanceOptions_603033(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_603032(path: JsonNode;
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
  var valid_603034 = query.getOrDefault("Action")
  valid_603034 = validateParameter(valid_603034, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603034 != nil:
    section.add "Action", valid_603034
  var valid_603035 = query.getOrDefault("Version")
  valid_603035 = validateParameter(valid_603035, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603035 != nil:
    section.add "Version", valid_603035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603036 = header.getOrDefault("X-Amz-Signature")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Signature", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Content-Sha256", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-Date")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-Date", valid_603038
  var valid_603039 = header.getOrDefault("X-Amz-Credential")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Credential", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-Security-Token")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Security-Token", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Algorithm")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Algorithm", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-SignedHeaders", valid_603042
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
  var valid_603043 = formData.getOrDefault("DBInstanceClass")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "DBInstanceClass", valid_603043
  var valid_603044 = formData.getOrDefault("MaxRecords")
  valid_603044 = validateParameter(valid_603044, JInt, required = false, default = nil)
  if valid_603044 != nil:
    section.add "MaxRecords", valid_603044
  var valid_603045 = formData.getOrDefault("EngineVersion")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "EngineVersion", valid_603045
  var valid_603046 = formData.getOrDefault("Marker")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "Marker", valid_603046
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603047 = formData.getOrDefault("Engine")
  valid_603047 = validateParameter(valid_603047, JString, required = true,
                                 default = nil)
  if valid_603047 != nil:
    section.add "Engine", valid_603047
  var valid_603048 = formData.getOrDefault("Vpc")
  valid_603048 = validateParameter(valid_603048, JBool, required = false, default = nil)
  if valid_603048 != nil:
    section.add "Vpc", valid_603048
  var valid_603049 = formData.getOrDefault("LicenseModel")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "LicenseModel", valid_603049
  var valid_603050 = formData.getOrDefault("Filters")
  valid_603050 = validateParameter(valid_603050, JArray, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "Filters", valid_603050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603051: Call_PostDescribeOrderableDBInstanceOptions_603031;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603051, url, valid)

proc call*(call_603052: Call_PostDescribeOrderableDBInstanceOptions_603031;
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
  var query_603053 = newJObject()
  var formData_603054 = newJObject()
  add(formData_603054, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603054, "MaxRecords", newJInt(MaxRecords))
  add(formData_603054, "EngineVersion", newJString(EngineVersion))
  add(formData_603054, "Marker", newJString(Marker))
  add(formData_603054, "Engine", newJString(Engine))
  add(formData_603054, "Vpc", newJBool(Vpc))
  add(query_603053, "Action", newJString(Action))
  add(formData_603054, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_603054.add "Filters", Filters
  add(query_603053, "Version", newJString(Version))
  result = call_603052.call(nil, query_603053, nil, formData_603054, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_603031(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_603032, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_603033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_603008 = ref object of OpenApiRestCall_601373
proc url_GetDescribeOrderableDBInstanceOptions_603010(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_603009(path: JsonNode;
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
  var valid_603011 = query.getOrDefault("Marker")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "Marker", valid_603011
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_603012 = query.getOrDefault("Engine")
  valid_603012 = validateParameter(valid_603012, JString, required = true,
                                 default = nil)
  if valid_603012 != nil:
    section.add "Engine", valid_603012
  var valid_603013 = query.getOrDefault("LicenseModel")
  valid_603013 = validateParameter(valid_603013, JString, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "LicenseModel", valid_603013
  var valid_603014 = query.getOrDefault("Vpc")
  valid_603014 = validateParameter(valid_603014, JBool, required = false, default = nil)
  if valid_603014 != nil:
    section.add "Vpc", valid_603014
  var valid_603015 = query.getOrDefault("EngineVersion")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "EngineVersion", valid_603015
  var valid_603016 = query.getOrDefault("Action")
  valid_603016 = validateParameter(valid_603016, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_603016 != nil:
    section.add "Action", valid_603016
  var valid_603017 = query.getOrDefault("Version")
  valid_603017 = validateParameter(valid_603017, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603017 != nil:
    section.add "Version", valid_603017
  var valid_603018 = query.getOrDefault("DBInstanceClass")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "DBInstanceClass", valid_603018
  var valid_603019 = query.getOrDefault("Filters")
  valid_603019 = validateParameter(valid_603019, JArray, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "Filters", valid_603019
  var valid_603020 = query.getOrDefault("MaxRecords")
  valid_603020 = validateParameter(valid_603020, JInt, required = false, default = nil)
  if valid_603020 != nil:
    section.add "MaxRecords", valid_603020
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603021 = header.getOrDefault("X-Amz-Signature")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Signature", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-Content-Sha256", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-Date")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-Date", valid_603023
  var valid_603024 = header.getOrDefault("X-Amz-Credential")
  valid_603024 = validateParameter(valid_603024, JString, required = false,
                                 default = nil)
  if valid_603024 != nil:
    section.add "X-Amz-Credential", valid_603024
  var valid_603025 = header.getOrDefault("X-Amz-Security-Token")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Security-Token", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-Algorithm")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Algorithm", valid_603026
  var valid_603027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-SignedHeaders", valid_603027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603028: Call_GetDescribeOrderableDBInstanceOptions_603008;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_603028.validator(path, query, header, formData, body)
  let scheme = call_603028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603028.url(scheme.get, call_603028.host, call_603028.base,
                         call_603028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603028, url, valid)

proc call*(call_603029: Call_GetDescribeOrderableDBInstanceOptions_603008;
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
  var query_603030 = newJObject()
  add(query_603030, "Marker", newJString(Marker))
  add(query_603030, "Engine", newJString(Engine))
  add(query_603030, "LicenseModel", newJString(LicenseModel))
  add(query_603030, "Vpc", newJBool(Vpc))
  add(query_603030, "EngineVersion", newJString(EngineVersion))
  add(query_603030, "Action", newJString(Action))
  add(query_603030, "Version", newJString(Version))
  add(query_603030, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_603030.add "Filters", Filters
  add(query_603030, "MaxRecords", newJInt(MaxRecords))
  result = call_603029.call(nil, query_603030, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_603008(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_603009, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_603010,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_603074 = ref object of OpenApiRestCall_601373
proc url_PostDescribePendingMaintenanceActions_603076(protocol: Scheme;
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

proc validate_PostDescribePendingMaintenanceActions_603075(path: JsonNode;
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
  var valid_603077 = query.getOrDefault("Action")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_603077 != nil:
    section.add "Action", valid_603077
  var valid_603078 = query.getOrDefault("Version")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603078 != nil:
    section.add "Version", valid_603078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603079 = header.getOrDefault("X-Amz-Signature")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Signature", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Content-Sha256", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Date")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Date", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Security-Token")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Security-Token", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Algorithm")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Algorithm", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-SignedHeaders", valid_603085
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
  var valid_603086 = formData.getOrDefault("MaxRecords")
  valid_603086 = validateParameter(valid_603086, JInt, required = false, default = nil)
  if valid_603086 != nil:
    section.add "MaxRecords", valid_603086
  var valid_603087 = formData.getOrDefault("Marker")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "Marker", valid_603087
  var valid_603088 = formData.getOrDefault("ResourceIdentifier")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "ResourceIdentifier", valid_603088
  var valid_603089 = formData.getOrDefault("Filters")
  valid_603089 = validateParameter(valid_603089, JArray, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "Filters", valid_603089
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603090: Call_PostDescribePendingMaintenanceActions_603074;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_603090.validator(path, query, header, formData, body)
  let scheme = call_603090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603090.url(scheme.get, call_603090.host, call_603090.base,
                         call_603090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603090, url, valid)

proc call*(call_603091: Call_PostDescribePendingMaintenanceActions_603074;
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
  var query_603092 = newJObject()
  var formData_603093 = newJObject()
  add(formData_603093, "MaxRecords", newJInt(MaxRecords))
  add(formData_603093, "Marker", newJString(Marker))
  add(formData_603093, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_603092, "Action", newJString(Action))
  if Filters != nil:
    formData_603093.add "Filters", Filters
  add(query_603092, "Version", newJString(Version))
  result = call_603091.call(nil, query_603092, nil, formData_603093, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_603074(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_603075, base: "/",
    url: url_PostDescribePendingMaintenanceActions_603076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_603055 = ref object of OpenApiRestCall_601373
proc url_GetDescribePendingMaintenanceActions_603057(protocol: Scheme;
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

proc validate_GetDescribePendingMaintenanceActions_603056(path: JsonNode;
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
  var valid_603058 = query.getOrDefault("ResourceIdentifier")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "ResourceIdentifier", valid_603058
  var valid_603059 = query.getOrDefault("Marker")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "Marker", valid_603059
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603060 = query.getOrDefault("Action")
  valid_603060 = validateParameter(valid_603060, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_603060 != nil:
    section.add "Action", valid_603060
  var valid_603061 = query.getOrDefault("Version")
  valid_603061 = validateParameter(valid_603061, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603061 != nil:
    section.add "Version", valid_603061
  var valid_603062 = query.getOrDefault("Filters")
  valid_603062 = validateParameter(valid_603062, JArray, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "Filters", valid_603062
  var valid_603063 = query.getOrDefault("MaxRecords")
  valid_603063 = validateParameter(valid_603063, JInt, required = false, default = nil)
  if valid_603063 != nil:
    section.add "MaxRecords", valid_603063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603064 = header.getOrDefault("X-Amz-Signature")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Signature", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Content-Sha256", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Date")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Date", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Credential")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Credential", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Security-Token")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Security-Token", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Algorithm")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Algorithm", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-SignedHeaders", valid_603070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603071: Call_GetDescribePendingMaintenanceActions_603055;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_603071.validator(path, query, header, formData, body)
  let scheme = call_603071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603071.url(scheme.get, call_603071.host, call_603071.base,
                         call_603071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603071, url, valid)

proc call*(call_603072: Call_GetDescribePendingMaintenanceActions_603055;
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
  var query_603073 = newJObject()
  add(query_603073, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_603073, "Marker", newJString(Marker))
  add(query_603073, "Action", newJString(Action))
  add(query_603073, "Version", newJString(Version))
  if Filters != nil:
    query_603073.add "Filters", Filters
  add(query_603073, "MaxRecords", newJInt(MaxRecords))
  result = call_603072.call(nil, query_603073, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_603055(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_603056, base: "/",
    url: url_GetDescribePendingMaintenanceActions_603057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_603111 = ref object of OpenApiRestCall_601373
proc url_PostFailoverDBCluster_603113(protocol: Scheme; host: string; base: string;
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

proc validate_PostFailoverDBCluster_603112(path: JsonNode; query: JsonNode;
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
  var valid_603114 = query.getOrDefault("Action")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_603114 != nil:
    section.add "Action", valid_603114
  var valid_603115 = query.getOrDefault("Version")
  valid_603115 = validateParameter(valid_603115, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603115 != nil:
    section.add "Version", valid_603115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603116 = header.getOrDefault("X-Amz-Signature")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Signature", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Content-Sha256", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Date")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Date", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Credential")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Credential", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Security-Token")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Security-Token", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-SignedHeaders", valid_603122
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_603123 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603123
  var valid_603124 = formData.getOrDefault("DBClusterIdentifier")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "DBClusterIdentifier", valid_603124
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603125: Call_PostFailoverDBCluster_603111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_603125.validator(path, query, header, formData, body)
  let scheme = call_603125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603125.url(scheme.get, call_603125.host, call_603125.base,
                         call_603125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603125, url, valid)

proc call*(call_603126: Call_PostFailoverDBCluster_603111;
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
  var query_603127 = newJObject()
  var formData_603128 = newJObject()
  add(query_603127, "Action", newJString(Action))
  add(formData_603128, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603127, "Version", newJString(Version))
  add(formData_603128, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_603126.call(nil, query_603127, nil, formData_603128, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_603111(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_603112, base: "/",
    url: url_PostFailoverDBCluster_603113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_603094 = ref object of OpenApiRestCall_601373
proc url_GetFailoverDBCluster_603096(protocol: Scheme; host: string; base: string;
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

proc validate_GetFailoverDBCluster_603095(path: JsonNode; query: JsonNode;
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
  var valid_603097 = query.getOrDefault("DBClusterIdentifier")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "DBClusterIdentifier", valid_603097
  var valid_603098 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603098
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603099 = query.getOrDefault("Action")
  valid_603099 = validateParameter(valid_603099, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_603099 != nil:
    section.add "Action", valid_603099
  var valid_603100 = query.getOrDefault("Version")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603100 != nil:
    section.add "Version", valid_603100
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603101 = header.getOrDefault("X-Amz-Signature")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Signature", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Content-Sha256", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Date")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Date", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Credential")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Credential", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Security-Token")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Security-Token", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-SignedHeaders", valid_603107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603108: Call_GetFailoverDBCluster_603094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_603108.validator(path, query, header, formData, body)
  let scheme = call_603108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603108.url(scheme.get, call_603108.host, call_603108.base,
                         call_603108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603108, url, valid)

proc call*(call_603109: Call_GetFailoverDBCluster_603094;
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
  var query_603110 = newJObject()
  add(query_603110, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603110, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603110, "Action", newJString(Action))
  add(query_603110, "Version", newJString(Version))
  result = call_603109.call(nil, query_603110, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_603094(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_603095, base: "/",
    url: url_GetFailoverDBCluster_603096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_603146 = ref object of OpenApiRestCall_601373
proc url_PostListTagsForResource_603148(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_603147(path: JsonNode; query: JsonNode;
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
  var valid_603149 = query.getOrDefault("Action")
  valid_603149 = validateParameter(valid_603149, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603149 != nil:
    section.add "Action", valid_603149
  var valid_603150 = query.getOrDefault("Version")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603150 != nil:
    section.add "Version", valid_603150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603151 = header.getOrDefault("X-Amz-Signature")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Signature", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Content-Sha256", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Date")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Date", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Security-Token")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Security-Token", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Algorithm")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Algorithm", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-SignedHeaders", valid_603157
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_603158 = formData.getOrDefault("Filters")
  valid_603158 = validateParameter(valid_603158, JArray, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "Filters", valid_603158
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_603159 = formData.getOrDefault("ResourceName")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = nil)
  if valid_603159 != nil:
    section.add "ResourceName", valid_603159
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603160: Call_PostListTagsForResource_603146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_603160.validator(path, query, header, formData, body)
  let scheme = call_603160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603160.url(scheme.get, call_603160.host, call_603160.base,
                         call_603160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603160, url, valid)

proc call*(call_603161: Call_PostListTagsForResource_603146; ResourceName: string;
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
  var query_603162 = newJObject()
  var formData_603163 = newJObject()
  add(query_603162, "Action", newJString(Action))
  if Filters != nil:
    formData_603163.add "Filters", Filters
  add(query_603162, "Version", newJString(Version))
  add(formData_603163, "ResourceName", newJString(ResourceName))
  result = call_603161.call(nil, query_603162, nil, formData_603163, nil)

var postListTagsForResource* = Call_PostListTagsForResource_603146(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_603147, base: "/",
    url: url_PostListTagsForResource_603148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_603129 = ref object of OpenApiRestCall_601373
proc url_GetListTagsForResource_603131(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_603130(path: JsonNode; query: JsonNode;
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
  var valid_603132 = query.getOrDefault("ResourceName")
  valid_603132 = validateParameter(valid_603132, JString, required = true,
                                 default = nil)
  if valid_603132 != nil:
    section.add "ResourceName", valid_603132
  var valid_603133 = query.getOrDefault("Action")
  valid_603133 = validateParameter(valid_603133, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603133 != nil:
    section.add "Action", valid_603133
  var valid_603134 = query.getOrDefault("Version")
  valid_603134 = validateParameter(valid_603134, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603134 != nil:
    section.add "Version", valid_603134
  var valid_603135 = query.getOrDefault("Filters")
  valid_603135 = validateParameter(valid_603135, JArray, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "Filters", valid_603135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603136 = header.getOrDefault("X-Amz-Signature")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Signature", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Content-Sha256", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Date")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Date", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Security-Token")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Security-Token", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Algorithm")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Algorithm", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603143: Call_GetListTagsForResource_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_603143.validator(path, query, header, formData, body)
  let scheme = call_603143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603143.url(scheme.get, call_603143.host, call_603143.base,
                         call_603143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603143, url, valid)

proc call*(call_603144: Call_GetListTagsForResource_603129; ResourceName: string;
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
  var query_603145 = newJObject()
  add(query_603145, "ResourceName", newJString(ResourceName))
  add(query_603145, "Action", newJString(Action))
  add(query_603145, "Version", newJString(Version))
  if Filters != nil:
    query_603145.add "Filters", Filters
  result = call_603144.call(nil, query_603145, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_603129(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_603130, base: "/",
    url: url_GetListTagsForResource_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_603193 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBCluster_603195(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBCluster_603194(path: JsonNode; query: JsonNode;
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
  var valid_603196 = query.getOrDefault("Action")
  valid_603196 = validateParameter(valid_603196, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_603196 != nil:
    section.add "Action", valid_603196
  var valid_603197 = query.getOrDefault("Version")
  valid_603197 = validateParameter(valid_603197, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603197 != nil:
    section.add "Version", valid_603197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603198 = header.getOrDefault("X-Amz-Signature")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Signature", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Content-Sha256", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Date")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Date", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Credential")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Credential", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Security-Token")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Security-Token", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Algorithm")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Algorithm", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-SignedHeaders", valid_603204
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
  var valid_603205 = formData.getOrDefault("Port")
  valid_603205 = validateParameter(valid_603205, JInt, required = false, default = nil)
  if valid_603205 != nil:
    section.add "Port", valid_603205
  var valid_603206 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "PreferredMaintenanceWindow", valid_603206
  var valid_603207 = formData.getOrDefault("PreferredBackupWindow")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "PreferredBackupWindow", valid_603207
  var valid_603208 = formData.getOrDefault("MasterUserPassword")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "MasterUserPassword", valid_603208
  var valid_603209 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_603209 = validateParameter(valid_603209, JArray, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_603209
  var valid_603210 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_603210 = validateParameter(valid_603210, JArray, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_603210
  var valid_603211 = formData.getOrDefault("EngineVersion")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "EngineVersion", valid_603211
  var valid_603212 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603212 = validateParameter(valid_603212, JArray, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "VpcSecurityGroupIds", valid_603212
  var valid_603213 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603213 = validateParameter(valid_603213, JInt, required = false, default = nil)
  if valid_603213 != nil:
    section.add "BackupRetentionPeriod", valid_603213
  var valid_603214 = formData.getOrDefault("ApplyImmediately")
  valid_603214 = validateParameter(valid_603214, JBool, required = false, default = nil)
  if valid_603214 != nil:
    section.add "ApplyImmediately", valid_603214
  var valid_603215 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "DBClusterParameterGroupName", valid_603215
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_603216 = formData.getOrDefault("DBClusterIdentifier")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = nil)
  if valid_603216 != nil:
    section.add "DBClusterIdentifier", valid_603216
  var valid_603217 = formData.getOrDefault("DeletionProtection")
  valid_603217 = validateParameter(valid_603217, JBool, required = false, default = nil)
  if valid_603217 != nil:
    section.add "DeletionProtection", valid_603217
  var valid_603218 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "NewDBClusterIdentifier", valid_603218
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_PostModifyDBCluster_603193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603219, url, valid)

proc call*(call_603220: Call_PostModifyDBCluster_603193;
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
  var query_603221 = newJObject()
  var formData_603222 = newJObject()
  add(formData_603222, "Port", newJInt(Port))
  add(formData_603222, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_603222, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603222, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_603222.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_603222.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_603222, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_603222.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603222, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603222, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_603221, "Action", newJString(Action))
  add(formData_603222, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603221, "Version", newJString(Version))
  add(formData_603222, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_603222, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_603222, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  result = call_603220.call(nil, query_603221, nil, formData_603222, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_603193(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_603194, base: "/",
    url: url_PostModifyDBCluster_603195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_603164 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBCluster_603166(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBCluster_603165(path: JsonNode; query: JsonNode;
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
  var valid_603167 = query.getOrDefault("DeletionProtection")
  valid_603167 = validateParameter(valid_603167, JBool, required = false, default = nil)
  if valid_603167 != nil:
    section.add "DeletionProtection", valid_603167
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_603168 = query.getOrDefault("DBClusterIdentifier")
  valid_603168 = validateParameter(valid_603168, JString, required = true,
                                 default = nil)
  if valid_603168 != nil:
    section.add "DBClusterIdentifier", valid_603168
  var valid_603169 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "DBClusterParameterGroupName", valid_603169
  var valid_603170 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_603170 = validateParameter(valid_603170, JArray, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_603170
  var valid_603171 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_603171 = validateParameter(valid_603171, JArray, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_603171
  var valid_603172 = query.getOrDefault("BackupRetentionPeriod")
  valid_603172 = validateParameter(valid_603172, JInt, required = false, default = nil)
  if valid_603172 != nil:
    section.add "BackupRetentionPeriod", valid_603172
  var valid_603173 = query.getOrDefault("EngineVersion")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "EngineVersion", valid_603173
  var valid_603174 = query.getOrDefault("Action")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_603174 != nil:
    section.add "Action", valid_603174
  var valid_603175 = query.getOrDefault("ApplyImmediately")
  valid_603175 = validateParameter(valid_603175, JBool, required = false, default = nil)
  if valid_603175 != nil:
    section.add "ApplyImmediately", valid_603175
  var valid_603176 = query.getOrDefault("NewDBClusterIdentifier")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "NewDBClusterIdentifier", valid_603176
  var valid_603177 = query.getOrDefault("Port")
  valid_603177 = validateParameter(valid_603177, JInt, required = false, default = nil)
  if valid_603177 != nil:
    section.add "Port", valid_603177
  var valid_603178 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603178 = validateParameter(valid_603178, JArray, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "VpcSecurityGroupIds", valid_603178
  var valid_603179 = query.getOrDefault("MasterUserPassword")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "MasterUserPassword", valid_603179
  var valid_603180 = query.getOrDefault("Version")
  valid_603180 = validateParameter(valid_603180, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603180 != nil:
    section.add "Version", valid_603180
  var valid_603181 = query.getOrDefault("PreferredBackupWindow")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "PreferredBackupWindow", valid_603181
  var valid_603182 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "PreferredMaintenanceWindow", valid_603182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603183 = header.getOrDefault("X-Amz-Signature")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Signature", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Content-Sha256", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Date")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Date", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Credential")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Credential", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Algorithm")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Algorithm", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603190: Call_GetModifyDBCluster_603164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_603190.validator(path, query, header, formData, body)
  let scheme = call_603190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603190.url(scheme.get, call_603190.host, call_603190.base,
                         call_603190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603190, url, valid)

proc call*(call_603191: Call_GetModifyDBCluster_603164;
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
  var query_603192 = newJObject()
  add(query_603192, "DeletionProtection", newJBool(DeletionProtection))
  add(query_603192, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603192, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_603192.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_603192.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_603192, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603192, "EngineVersion", newJString(EngineVersion))
  add(query_603192, "Action", newJString(Action))
  add(query_603192, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_603192, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_603192, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_603192.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603192, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603192, "Version", newJString(Version))
  add(query_603192, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603192, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603191.call(nil, query_603192, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_603164(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_603165,
    base: "/", url: url_GetModifyDBCluster_603166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_603240 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBClusterParameterGroup_603242(protocol: Scheme; host: string;
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

proc validate_PostModifyDBClusterParameterGroup_603241(path: JsonNode;
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
  var valid_603243 = query.getOrDefault("Action")
  valid_603243 = validateParameter(valid_603243, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_603243 != nil:
    section.add "Action", valid_603243
  var valid_603244 = query.getOrDefault("Version")
  valid_603244 = validateParameter(valid_603244, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603244 != nil:
    section.add "Version", valid_603244
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Content-Sha256", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Date")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Date", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Credential")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Credential", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Security-Token")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Security-Token", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Algorithm")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Algorithm", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-SignedHeaders", valid_603251
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_603252 = formData.getOrDefault("Parameters")
  valid_603252 = validateParameter(valid_603252, JArray, required = true, default = nil)
  if valid_603252 != nil:
    section.add "Parameters", valid_603252
  var valid_603253 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "DBClusterParameterGroupName", valid_603253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603254: Call_PostModifyDBClusterParameterGroup_603240;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_603254.validator(path, query, header, formData, body)
  let scheme = call_603254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603254.url(scheme.get, call_603254.host, call_603254.base,
                         call_603254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603254, url, valid)

proc call*(call_603255: Call_PostModifyDBClusterParameterGroup_603240;
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
  var query_603256 = newJObject()
  var formData_603257 = newJObject()
  add(query_603256, "Action", newJString(Action))
  if Parameters != nil:
    formData_603257.add "Parameters", Parameters
  add(formData_603257, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603256, "Version", newJString(Version))
  result = call_603255.call(nil, query_603256, nil, formData_603257, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_603240(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_603241, base: "/",
    url: url_PostModifyDBClusterParameterGroup_603242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_603223 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBClusterParameterGroup_603225(protocol: Scheme; host: string;
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

proc validate_GetModifyDBClusterParameterGroup_603224(path: JsonNode;
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
  var valid_603226 = query.getOrDefault("Parameters")
  valid_603226 = validateParameter(valid_603226, JArray, required = true, default = nil)
  if valid_603226 != nil:
    section.add "Parameters", valid_603226
  var valid_603227 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603227 = validateParameter(valid_603227, JString, required = true,
                                 default = nil)
  if valid_603227 != nil:
    section.add "DBClusterParameterGroupName", valid_603227
  var valid_603228 = query.getOrDefault("Action")
  valid_603228 = validateParameter(valid_603228, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_603228 != nil:
    section.add "Action", valid_603228
  var valid_603229 = query.getOrDefault("Version")
  valid_603229 = validateParameter(valid_603229, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603229 != nil:
    section.add "Version", valid_603229
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Content-Sha256", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Date")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Date", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Credential")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Credential", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Security-Token")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Security-Token", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Algorithm")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Algorithm", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-SignedHeaders", valid_603236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603237: Call_GetModifyDBClusterParameterGroup_603223;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_603237.validator(path, query, header, formData, body)
  let scheme = call_603237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603237.url(scheme.get, call_603237.host, call_603237.base,
                         call_603237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603237, url, valid)

proc call*(call_603238: Call_GetModifyDBClusterParameterGroup_603223;
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
  var query_603239 = newJObject()
  if Parameters != nil:
    query_603239.add "Parameters", Parameters
  add(query_603239, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603239, "Action", newJString(Action))
  add(query_603239, "Version", newJString(Version))
  result = call_603238.call(nil, query_603239, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_603223(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_603224, base: "/",
    url: url_GetModifyDBClusterParameterGroup_603225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_603277 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBClusterSnapshotAttribute_603279(protocol: Scheme;
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

proc validate_PostModifyDBClusterSnapshotAttribute_603278(path: JsonNode;
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
  var valid_603280 = query.getOrDefault("Action")
  valid_603280 = validateParameter(valid_603280, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_603280 != nil:
    section.add "Action", valid_603280
  var valid_603281 = query.getOrDefault("Version")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603281 != nil:
    section.add "Version", valid_603281
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603282 = header.getOrDefault("X-Amz-Signature")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Signature", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Content-Sha256", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Date")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Date", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Credential")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Credential", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Algorithm")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Algorithm", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-SignedHeaders", valid_603288
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
  var valid_603289 = formData.getOrDefault("AttributeName")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = nil)
  if valid_603289 != nil:
    section.add "AttributeName", valid_603289
  var valid_603290 = formData.getOrDefault("ValuesToAdd")
  valid_603290 = validateParameter(valid_603290, JArray, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "ValuesToAdd", valid_603290
  var valid_603291 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603291 = validateParameter(valid_603291, JString, required = true,
                                 default = nil)
  if valid_603291 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603291
  var valid_603292 = formData.getOrDefault("ValuesToRemove")
  valid_603292 = validateParameter(valid_603292, JArray, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "ValuesToRemove", valid_603292
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603293: Call_PostModifyDBClusterSnapshotAttribute_603277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_603293.validator(path, query, header, formData, body)
  let scheme = call_603293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603293.url(scheme.get, call_603293.host, call_603293.base,
                         call_603293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603293, url, valid)

proc call*(call_603294: Call_PostModifyDBClusterSnapshotAttribute_603277;
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
  var query_603295 = newJObject()
  var formData_603296 = newJObject()
  add(formData_603296, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    formData_603296.add "ValuesToAdd", ValuesToAdd
  add(formData_603296, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603295, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_603296.add "ValuesToRemove", ValuesToRemove
  add(query_603295, "Version", newJString(Version))
  result = call_603294.call(nil, query_603295, nil, formData_603296, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_603277(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_603278, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_603279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_603258 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBClusterSnapshotAttribute_603260(protocol: Scheme; host: string;
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

proc validate_GetModifyDBClusterSnapshotAttribute_603259(path: JsonNode;
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
  var valid_603261 = query.getOrDefault("ValuesToRemove")
  valid_603261 = validateParameter(valid_603261, JArray, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "ValuesToRemove", valid_603261
  assert query != nil, "query argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_603262 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_603262 = validateParameter(valid_603262, JString, required = true,
                                 default = nil)
  if valid_603262 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_603262
  var valid_603263 = query.getOrDefault("Action")
  valid_603263 = validateParameter(valid_603263, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_603263 != nil:
    section.add "Action", valid_603263
  var valid_603264 = query.getOrDefault("AttributeName")
  valid_603264 = validateParameter(valid_603264, JString, required = true,
                                 default = nil)
  if valid_603264 != nil:
    section.add "AttributeName", valid_603264
  var valid_603265 = query.getOrDefault("ValuesToAdd")
  valid_603265 = validateParameter(valid_603265, JArray, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "ValuesToAdd", valid_603265
  var valid_603266 = query.getOrDefault("Version")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603266 != nil:
    section.add "Version", valid_603266
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603267 = header.getOrDefault("X-Amz-Signature")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Signature", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Content-Sha256", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Date")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Date", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Credential")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Credential", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Algorithm")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Algorithm", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-SignedHeaders", valid_603273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603274: Call_GetModifyDBClusterSnapshotAttribute_603258;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_603274.validator(path, query, header, formData, body)
  let scheme = call_603274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603274.url(scheme.get, call_603274.host, call_603274.base,
                         call_603274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603274, url, valid)

proc call*(call_603275: Call_GetModifyDBClusterSnapshotAttribute_603258;
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
  var query_603276 = newJObject()
  if ValuesToRemove != nil:
    query_603276.add "ValuesToRemove", ValuesToRemove
  add(query_603276, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_603276, "Action", newJString(Action))
  add(query_603276, "AttributeName", newJString(AttributeName))
  if ValuesToAdd != nil:
    query_603276.add "ValuesToAdd", ValuesToAdd
  add(query_603276, "Version", newJString(Version))
  result = call_603275.call(nil, query_603276, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_603258(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_603259, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_603260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_603320 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBInstance_603322(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_603321(path: JsonNode; query: JsonNode;
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
  var valid_603323 = query.getOrDefault("Action")
  valid_603323 = validateParameter(valid_603323, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603323 != nil:
    section.add "Action", valid_603323
  var valid_603324 = query.getOrDefault("Version")
  valid_603324 = validateParameter(valid_603324, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603324 != nil:
    section.add "Version", valid_603324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603325 = header.getOrDefault("X-Amz-Signature")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Signature", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Content-Sha256", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Date")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Date", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Credential")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Credential", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Security-Token")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Security-Token", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Algorithm")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Algorithm", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-SignedHeaders", valid_603331
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
  var valid_603332 = formData.getOrDefault("PromotionTier")
  valid_603332 = validateParameter(valid_603332, JInt, required = false, default = nil)
  if valid_603332 != nil:
    section.add "PromotionTier", valid_603332
  var valid_603333 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "PreferredMaintenanceWindow", valid_603333
  var valid_603334 = formData.getOrDefault("DBInstanceClass")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "DBInstanceClass", valid_603334
  var valid_603335 = formData.getOrDefault("CACertificateIdentifier")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "CACertificateIdentifier", valid_603335
  var valid_603336 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603336 = validateParameter(valid_603336, JBool, required = false, default = nil)
  if valid_603336 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603336
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603337 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603337 = validateParameter(valid_603337, JString, required = true,
                                 default = nil)
  if valid_603337 != nil:
    section.add "DBInstanceIdentifier", valid_603337
  var valid_603338 = formData.getOrDefault("ApplyImmediately")
  valid_603338 = validateParameter(valid_603338, JBool, required = false, default = nil)
  if valid_603338 != nil:
    section.add "ApplyImmediately", valid_603338
  var valid_603339 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "NewDBInstanceIdentifier", valid_603339
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603340: Call_PostModifyDBInstance_603320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_603340.validator(path, query, header, formData, body)
  let scheme = call_603340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603340.url(scheme.get, call_603340.host, call_603340.base,
                         call_603340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603340, url, valid)

proc call*(call_603341: Call_PostModifyDBInstance_603320;
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
  var query_603342 = newJObject()
  var formData_603343 = newJObject()
  add(formData_603343, "PromotionTier", newJInt(PromotionTier))
  add(formData_603343, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_603343, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603343, "CACertificateIdentifier",
      newJString(CACertificateIdentifier))
  add(formData_603343, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603343, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603343, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_603342, "Action", newJString(Action))
  add(formData_603343, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_603342, "Version", newJString(Version))
  result = call_603341.call(nil, query_603342, nil, formData_603343, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_603320(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_603321, base: "/",
    url: url_PostModifyDBInstance_603322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_603297 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBInstance_603299(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_603298(path: JsonNode; query: JsonNode;
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
  var valid_603300 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "NewDBInstanceIdentifier", valid_603300
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603301 = query.getOrDefault("DBInstanceIdentifier")
  valid_603301 = validateParameter(valid_603301, JString, required = true,
                                 default = nil)
  if valid_603301 != nil:
    section.add "DBInstanceIdentifier", valid_603301
  var valid_603302 = query.getOrDefault("PromotionTier")
  valid_603302 = validateParameter(valid_603302, JInt, required = false, default = nil)
  if valid_603302 != nil:
    section.add "PromotionTier", valid_603302
  var valid_603303 = query.getOrDefault("CACertificateIdentifier")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "CACertificateIdentifier", valid_603303
  var valid_603304 = query.getOrDefault("Action")
  valid_603304 = validateParameter(valid_603304, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_603304 != nil:
    section.add "Action", valid_603304
  var valid_603305 = query.getOrDefault("ApplyImmediately")
  valid_603305 = validateParameter(valid_603305, JBool, required = false, default = nil)
  if valid_603305 != nil:
    section.add "ApplyImmediately", valid_603305
  var valid_603306 = query.getOrDefault("Version")
  valid_603306 = validateParameter(valid_603306, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603306 != nil:
    section.add "Version", valid_603306
  var valid_603307 = query.getOrDefault("DBInstanceClass")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "DBInstanceClass", valid_603307
  var valid_603308 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "PreferredMaintenanceWindow", valid_603308
  var valid_603309 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603309 = validateParameter(valid_603309, JBool, required = false, default = nil)
  if valid_603309 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603310 = header.getOrDefault("X-Amz-Signature")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Signature", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Content-Sha256", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Date")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Date", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Credential")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Credential", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Security-Token")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Security-Token", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Algorithm")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Algorithm", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-SignedHeaders", valid_603316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603317: Call_GetModifyDBInstance_603297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_603317.validator(path, query, header, formData, body)
  let scheme = call_603317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603317.url(scheme.get, call_603317.host, call_603317.base,
                         call_603317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603317, url, valid)

proc call*(call_603318: Call_GetModifyDBInstance_603297;
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
  var query_603319 = newJObject()
  add(query_603319, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_603319, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603319, "PromotionTier", newJInt(PromotionTier))
  add(query_603319, "CACertificateIdentifier", newJString(CACertificateIdentifier))
  add(query_603319, "Action", newJString(Action))
  add(query_603319, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_603319, "Version", newJString(Version))
  add(query_603319, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603319, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603319, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  result = call_603318.call(nil, query_603319, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_603297(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_603298, base: "/",
    url: url_GetModifyDBInstance_603299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_603362 = ref object of OpenApiRestCall_601373
proc url_PostModifyDBSubnetGroup_603364(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_603363(path: JsonNode; query: JsonNode;
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
  var valid_603365 = query.getOrDefault("Action")
  valid_603365 = validateParameter(valid_603365, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603365 != nil:
    section.add "Action", valid_603365
  var valid_603366 = query.getOrDefault("Version")
  valid_603366 = validateParameter(valid_603366, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603366 != nil:
    section.add "Version", valid_603366
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603367 = header.getOrDefault("X-Amz-Signature")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Signature", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Content-Sha256", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Date")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Date", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Credential")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Credential", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Security-Token")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Security-Token", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Algorithm")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Algorithm", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-SignedHeaders", valid_603373
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##                           : The description for the DB subnet group.
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. </p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   SubnetIds: JArray (required)
  ##            : The Amazon EC2 subnet IDs for the DB subnet group.
  section = newJObject()
  var valid_603374 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "DBSubnetGroupDescription", valid_603374
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603375 = formData.getOrDefault("DBSubnetGroupName")
  valid_603375 = validateParameter(valid_603375, JString, required = true,
                                 default = nil)
  if valid_603375 != nil:
    section.add "DBSubnetGroupName", valid_603375
  var valid_603376 = formData.getOrDefault("SubnetIds")
  valid_603376 = validateParameter(valid_603376, JArray, required = true, default = nil)
  if valid_603376 != nil:
    section.add "SubnetIds", valid_603376
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603377: Call_PostModifyDBSubnetGroup_603362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_603377.validator(path, query, header, formData, body)
  let scheme = call_603377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603377.url(scheme.get, call_603377.host, call_603377.base,
                         call_603377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603377, url, valid)

proc call*(call_603378: Call_PostModifyDBSubnetGroup_603362;
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
  var query_603379 = newJObject()
  var formData_603380 = newJObject()
  add(formData_603380, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603379, "Action", newJString(Action))
  add(formData_603380, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603379, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_603380.add "SubnetIds", SubnetIds
  result = call_603378.call(nil, query_603379, nil, formData_603380, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_603362(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_603363, base: "/",
    url: url_PostModifyDBSubnetGroup_603364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_603344 = ref object of OpenApiRestCall_601373
proc url_GetModifyDBSubnetGroup_603346(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_603345(path: JsonNode; query: JsonNode;
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
  var valid_603347 = query.getOrDefault("SubnetIds")
  valid_603347 = validateParameter(valid_603347, JArray, required = true, default = nil)
  if valid_603347 != nil:
    section.add "SubnetIds", valid_603347
  var valid_603348 = query.getOrDefault("Action")
  valid_603348 = validateParameter(valid_603348, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_603348 != nil:
    section.add "Action", valid_603348
  var valid_603349 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "DBSubnetGroupDescription", valid_603349
  var valid_603350 = query.getOrDefault("DBSubnetGroupName")
  valid_603350 = validateParameter(valid_603350, JString, required = true,
                                 default = nil)
  if valid_603350 != nil:
    section.add "DBSubnetGroupName", valid_603350
  var valid_603351 = query.getOrDefault("Version")
  valid_603351 = validateParameter(valid_603351, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603351 != nil:
    section.add "Version", valid_603351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603352 = header.getOrDefault("X-Amz-Signature")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Signature", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Content-Sha256", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Date")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Date", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Credential")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Credential", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Security-Token")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Security-Token", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Algorithm")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Algorithm", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-SignedHeaders", valid_603358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603359: Call_GetModifyDBSubnetGroup_603344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_603359.validator(path, query, header, formData, body)
  let scheme = call_603359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603359.url(scheme.get, call_603359.host, call_603359.base,
                         call_603359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603359, url, valid)

proc call*(call_603360: Call_GetModifyDBSubnetGroup_603344; SubnetIds: JsonNode;
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
  var query_603361 = newJObject()
  if SubnetIds != nil:
    query_603361.add "SubnetIds", SubnetIds
  add(query_603361, "Action", newJString(Action))
  add(query_603361, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603361, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603361, "Version", newJString(Version))
  result = call_603360.call(nil, query_603361, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_603344(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_603345, base: "/",
    url: url_GetModifyDBSubnetGroup_603346, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_603398 = ref object of OpenApiRestCall_601373
proc url_PostRebootDBInstance_603400(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_603399(path: JsonNode; query: JsonNode;
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
  var valid_603401 = query.getOrDefault("Action")
  valid_603401 = validateParameter(valid_603401, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603401 != nil:
    section.add "Action", valid_603401
  var valid_603402 = query.getOrDefault("Version")
  valid_603402 = validateParameter(valid_603402, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603402 != nil:
    section.add "Version", valid_603402
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603403 = header.getOrDefault("X-Amz-Signature")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Signature", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Content-Sha256", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Credential")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Credential", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Security-Token")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Security-Token", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Algorithm")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Algorithm", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-SignedHeaders", valid_603409
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  section = newJObject()
  var valid_603410 = formData.getOrDefault("ForceFailover")
  valid_603410 = validateParameter(valid_603410, JBool, required = false, default = nil)
  if valid_603410 != nil:
    section.add "ForceFailover", valid_603410
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603411 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603411 = validateParameter(valid_603411, JString, required = true,
                                 default = nil)
  if valid_603411 != nil:
    section.add "DBInstanceIdentifier", valid_603411
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603412: Call_PostRebootDBInstance_603398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_603412.validator(path, query, header, formData, body)
  let scheme = call_603412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603412.url(scheme.get, call_603412.host, call_603412.base,
                         call_603412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603412, url, valid)

proc call*(call_603413: Call_PostRebootDBInstance_603398;
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
  var query_603414 = newJObject()
  var formData_603415 = newJObject()
  add(formData_603415, "ForceFailover", newJBool(ForceFailover))
  add(formData_603415, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603414, "Action", newJString(Action))
  add(query_603414, "Version", newJString(Version))
  result = call_603413.call(nil, query_603414, nil, formData_603415, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_603398(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_603399, base: "/",
    url: url_PostRebootDBInstance_603400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_603381 = ref object of OpenApiRestCall_601373
proc url_GetRebootDBInstance_603383(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_603382(path: JsonNode; query: JsonNode;
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
  var valid_603384 = query.getOrDefault("ForceFailover")
  valid_603384 = validateParameter(valid_603384, JBool, required = false, default = nil)
  if valid_603384 != nil:
    section.add "ForceFailover", valid_603384
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603385 = query.getOrDefault("DBInstanceIdentifier")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = nil)
  if valid_603385 != nil:
    section.add "DBInstanceIdentifier", valid_603385
  var valid_603386 = query.getOrDefault("Action")
  valid_603386 = validateParameter(valid_603386, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_603386 != nil:
    section.add "Action", valid_603386
  var valid_603387 = query.getOrDefault("Version")
  valid_603387 = validateParameter(valid_603387, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603387 != nil:
    section.add "Version", valid_603387
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603388 = header.getOrDefault("X-Amz-Signature")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Signature", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Content-Sha256", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Credential")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Credential", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Security-Token")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Security-Token", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Algorithm")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Algorithm", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-SignedHeaders", valid_603394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603395: Call_GetRebootDBInstance_603381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_603395.validator(path, query, header, formData, body)
  let scheme = call_603395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603395.url(scheme.get, call_603395.host, call_603395.base,
                         call_603395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603395, url, valid)

proc call*(call_603396: Call_GetRebootDBInstance_603381;
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
  var query_603397 = newJObject()
  add(query_603397, "ForceFailover", newJBool(ForceFailover))
  add(query_603397, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603397, "Action", newJString(Action))
  add(query_603397, "Version", newJString(Version))
  result = call_603396.call(nil, query_603397, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_603381(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_603382, base: "/",
    url: url_GetRebootDBInstance_603383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_603433 = ref object of OpenApiRestCall_601373
proc url_PostRemoveTagsFromResource_603435(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_603434(path: JsonNode; query: JsonNode;
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
  var valid_603436 = query.getOrDefault("Action")
  valid_603436 = validateParameter(valid_603436, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603436 != nil:
    section.add "Action", valid_603436
  var valid_603437 = query.getOrDefault("Version")
  valid_603437 = validateParameter(valid_603437, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603437 != nil:
    section.add "Version", valid_603437
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603438 = header.getOrDefault("X-Amz-Signature")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Signature", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Content-Sha256", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Date")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Date", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Credential")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Credential", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Security-Token")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Security-Token", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Algorithm")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Algorithm", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-SignedHeaders", valid_603444
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_603445 = formData.getOrDefault("TagKeys")
  valid_603445 = validateParameter(valid_603445, JArray, required = true, default = nil)
  if valid_603445 != nil:
    section.add "TagKeys", valid_603445
  var valid_603446 = formData.getOrDefault("ResourceName")
  valid_603446 = validateParameter(valid_603446, JString, required = true,
                                 default = nil)
  if valid_603446 != nil:
    section.add "ResourceName", valid_603446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603447: Call_PostRemoveTagsFromResource_603433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_603447.validator(path, query, header, formData, body)
  let scheme = call_603447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603447.url(scheme.get, call_603447.host, call_603447.base,
                         call_603447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603447, url, valid)

proc call*(call_603448: Call_PostRemoveTagsFromResource_603433; TagKeys: JsonNode;
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
  var query_603449 = newJObject()
  var formData_603450 = newJObject()
  if TagKeys != nil:
    formData_603450.add "TagKeys", TagKeys
  add(query_603449, "Action", newJString(Action))
  add(query_603449, "Version", newJString(Version))
  add(formData_603450, "ResourceName", newJString(ResourceName))
  result = call_603448.call(nil, query_603449, nil, formData_603450, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_603433(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_603434, base: "/",
    url: url_PostRemoveTagsFromResource_603435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_603416 = ref object of OpenApiRestCall_601373
proc url_GetRemoveTagsFromResource_603418(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_603417(path: JsonNode; query: JsonNode;
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
  var valid_603419 = query.getOrDefault("ResourceName")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = nil)
  if valid_603419 != nil:
    section.add "ResourceName", valid_603419
  var valid_603420 = query.getOrDefault("TagKeys")
  valid_603420 = validateParameter(valid_603420, JArray, required = true, default = nil)
  if valid_603420 != nil:
    section.add "TagKeys", valid_603420
  var valid_603421 = query.getOrDefault("Action")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603421 != nil:
    section.add "Action", valid_603421
  var valid_603422 = query.getOrDefault("Version")
  valid_603422 = validateParameter(valid_603422, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603422 != nil:
    section.add "Version", valid_603422
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603423 = header.getOrDefault("X-Amz-Signature")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Signature", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Date")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Date", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Credential")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Credential", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Security-Token")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Security-Token", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Algorithm")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Algorithm", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-SignedHeaders", valid_603429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603430: Call_GetRemoveTagsFromResource_603416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_603430.validator(path, query, header, formData, body)
  let scheme = call_603430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603430.url(scheme.get, call_603430.host, call_603430.base,
                         call_603430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603430, url, valid)

proc call*(call_603431: Call_GetRemoveTagsFromResource_603416;
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
  var query_603432 = newJObject()
  add(query_603432, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_603432.add "TagKeys", TagKeys
  add(query_603432, "Action", newJString(Action))
  add(query_603432, "Version", newJString(Version))
  result = call_603431.call(nil, query_603432, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_603416(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_603417, base: "/",
    url: url_GetRemoveTagsFromResource_603418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_603469 = ref object of OpenApiRestCall_601373
proc url_PostResetDBClusterParameterGroup_603471(protocol: Scheme; host: string;
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

proc validate_PostResetDBClusterParameterGroup_603470(path: JsonNode;
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
  var valid_603472 = query.getOrDefault("Action")
  valid_603472 = validateParameter(valid_603472, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_603472 != nil:
    section.add "Action", valid_603472
  var valid_603473 = query.getOrDefault("Version")
  valid_603473 = validateParameter(valid_603473, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603473 != nil:
    section.add "Version", valid_603473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Content-Sha256", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Date")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Date", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Credential")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Credential", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Security-Token")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Security-Token", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Algorithm")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Algorithm", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-SignedHeaders", valid_603480
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  section = newJObject()
  var valid_603481 = formData.getOrDefault("ResetAllParameters")
  valid_603481 = validateParameter(valid_603481, JBool, required = false, default = nil)
  if valid_603481 != nil:
    section.add "ResetAllParameters", valid_603481
  var valid_603482 = formData.getOrDefault("Parameters")
  valid_603482 = validateParameter(valid_603482, JArray, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "Parameters", valid_603482
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603483 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_603483 = validateParameter(valid_603483, JString, required = true,
                                 default = nil)
  if valid_603483 != nil:
    section.add "DBClusterParameterGroupName", valid_603483
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603484: Call_PostResetDBClusterParameterGroup_603469;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_603484.validator(path, query, header, formData, body)
  let scheme = call_603484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603484.url(scheme.get, call_603484.host, call_603484.base,
                         call_603484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603484, url, valid)

proc call*(call_603485: Call_PostResetDBClusterParameterGroup_603469;
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
  var query_603486 = newJObject()
  var formData_603487 = newJObject()
  add(formData_603487, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603486, "Action", newJString(Action))
  if Parameters != nil:
    formData_603487.add "Parameters", Parameters
  add(formData_603487, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603486, "Version", newJString(Version))
  result = call_603485.call(nil, query_603486, nil, formData_603487, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_603469(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_603470, base: "/",
    url: url_PostResetDBClusterParameterGroup_603471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_603451 = ref object of OpenApiRestCall_601373
proc url_GetResetDBClusterParameterGroup_603453(protocol: Scheme; host: string;
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

proc validate_GetResetDBClusterParameterGroup_603452(path: JsonNode;
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
  var valid_603454 = query.getOrDefault("Parameters")
  valid_603454 = validateParameter(valid_603454, JArray, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "Parameters", valid_603454
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_603455 = query.getOrDefault("DBClusterParameterGroupName")
  valid_603455 = validateParameter(valid_603455, JString, required = true,
                                 default = nil)
  if valid_603455 != nil:
    section.add "DBClusterParameterGroupName", valid_603455
  var valid_603456 = query.getOrDefault("ResetAllParameters")
  valid_603456 = validateParameter(valid_603456, JBool, required = false, default = nil)
  if valid_603456 != nil:
    section.add "ResetAllParameters", valid_603456
  var valid_603457 = query.getOrDefault("Action")
  valid_603457 = validateParameter(valid_603457, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_603457 != nil:
    section.add "Action", valid_603457
  var valid_603458 = query.getOrDefault("Version")
  valid_603458 = validateParameter(valid_603458, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603458 != nil:
    section.add "Version", valid_603458
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Content-Sha256", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Date")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Date", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Credential")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Credential", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Security-Token")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Security-Token", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Algorithm")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Algorithm", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-SignedHeaders", valid_603465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603466: Call_GetResetDBClusterParameterGroup_603451;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_603466.validator(path, query, header, formData, body)
  let scheme = call_603466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603466.url(scheme.get, call_603466.host, call_603466.base,
                         call_603466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603466, url, valid)

proc call*(call_603467: Call_GetResetDBClusterParameterGroup_603451;
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
  var query_603468 = newJObject()
  if Parameters != nil:
    query_603468.add "Parameters", Parameters
  add(query_603468, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_603468, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603468, "Action", newJString(Action))
  add(query_603468, "Version", newJString(Version))
  result = call_603467.call(nil, query_603468, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_603451(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_603452, base: "/",
    url: url_GetResetDBClusterParameterGroup_603453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_603515 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBClusterFromSnapshot_603517(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBClusterFromSnapshot_603516(path: JsonNode;
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
  var valid_603518 = query.getOrDefault("Action")
  valid_603518 = validateParameter(valid_603518, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_603518 != nil:
    section.add "Action", valid_603518
  var valid_603519 = query.getOrDefault("Version")
  valid_603519 = validateParameter(valid_603519, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603519 != nil:
    section.add "Version", valid_603519
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603520 = header.getOrDefault("X-Amz-Signature")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Signature", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Content-Sha256", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Date")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Date", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Credential")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Credential", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Security-Token")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Security-Token", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Algorithm")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Algorithm", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-SignedHeaders", valid_603526
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
  var valid_603527 = formData.getOrDefault("Port")
  valid_603527 = validateParameter(valid_603527, JInt, required = false, default = nil)
  if valid_603527 != nil:
    section.add "Port", valid_603527
  var valid_603528 = formData.getOrDefault("EngineVersion")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "EngineVersion", valid_603528
  var valid_603529 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603529 = validateParameter(valid_603529, JArray, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "VpcSecurityGroupIds", valid_603529
  var valid_603530 = formData.getOrDefault("AvailabilityZones")
  valid_603530 = validateParameter(valid_603530, JArray, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "AvailabilityZones", valid_603530
  var valid_603531 = formData.getOrDefault("KmsKeyId")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "KmsKeyId", valid_603531
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603532 = formData.getOrDefault("Engine")
  valid_603532 = validateParameter(valid_603532, JString, required = true,
                                 default = nil)
  if valid_603532 != nil:
    section.add "Engine", valid_603532
  var valid_603533 = formData.getOrDefault("SnapshotIdentifier")
  valid_603533 = validateParameter(valid_603533, JString, required = true,
                                 default = nil)
  if valid_603533 != nil:
    section.add "SnapshotIdentifier", valid_603533
  var valid_603534 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_603534 = validateParameter(valid_603534, JArray, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "EnableCloudwatchLogsExports", valid_603534
  var valid_603535 = formData.getOrDefault("Tags")
  valid_603535 = validateParameter(valid_603535, JArray, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "Tags", valid_603535
  var valid_603536 = formData.getOrDefault("DBSubnetGroupName")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "DBSubnetGroupName", valid_603536
  var valid_603537 = formData.getOrDefault("DBClusterIdentifier")
  valid_603537 = validateParameter(valid_603537, JString, required = true,
                                 default = nil)
  if valid_603537 != nil:
    section.add "DBClusterIdentifier", valid_603537
  var valid_603538 = formData.getOrDefault("DeletionProtection")
  valid_603538 = validateParameter(valid_603538, JBool, required = false, default = nil)
  if valid_603538 != nil:
    section.add "DeletionProtection", valid_603538
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603539: Call_PostRestoreDBClusterFromSnapshot_603515;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_603539.validator(path, query, header, formData, body)
  let scheme = call_603539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603539.url(scheme.get, call_603539.host, call_603539.base,
                         call_603539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603539, url, valid)

proc call*(call_603540: Call_PostRestoreDBClusterFromSnapshot_603515;
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
  var query_603541 = newJObject()
  var formData_603542 = newJObject()
  add(formData_603542, "Port", newJInt(Port))
  add(formData_603542, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_603542.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if AvailabilityZones != nil:
    formData_603542.add "AvailabilityZones", AvailabilityZones
  add(formData_603542, "KmsKeyId", newJString(KmsKeyId))
  add(formData_603542, "Engine", newJString(Engine))
  add(formData_603542, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if EnableCloudwatchLogsExports != nil:
    formData_603542.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_603541, "Action", newJString(Action))
  if Tags != nil:
    formData_603542.add "Tags", Tags
  add(formData_603542, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603541, "Version", newJString(Version))
  add(formData_603542, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_603542, "DeletionProtection", newJBool(DeletionProtection))
  result = call_603540.call(nil, query_603541, nil, formData_603542, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_603515(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_603516, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_603517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_603488 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBClusterFromSnapshot_603490(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBClusterFromSnapshot_603489(path: JsonNode;
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
  var valid_603491 = query.getOrDefault("DeletionProtection")
  valid_603491 = validateParameter(valid_603491, JBool, required = false, default = nil)
  if valid_603491 != nil:
    section.add "DeletionProtection", valid_603491
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_603492 = query.getOrDefault("Engine")
  valid_603492 = validateParameter(valid_603492, JString, required = true,
                                 default = nil)
  if valid_603492 != nil:
    section.add "Engine", valid_603492
  var valid_603493 = query.getOrDefault("SnapshotIdentifier")
  valid_603493 = validateParameter(valid_603493, JString, required = true,
                                 default = nil)
  if valid_603493 != nil:
    section.add "SnapshotIdentifier", valid_603493
  var valid_603494 = query.getOrDefault("Tags")
  valid_603494 = validateParameter(valid_603494, JArray, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "Tags", valid_603494
  var valid_603495 = query.getOrDefault("KmsKeyId")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "KmsKeyId", valid_603495
  var valid_603496 = query.getOrDefault("DBClusterIdentifier")
  valid_603496 = validateParameter(valid_603496, JString, required = true,
                                 default = nil)
  if valid_603496 != nil:
    section.add "DBClusterIdentifier", valid_603496
  var valid_603497 = query.getOrDefault("AvailabilityZones")
  valid_603497 = validateParameter(valid_603497, JArray, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "AvailabilityZones", valid_603497
  var valid_603498 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_603498 = validateParameter(valid_603498, JArray, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "EnableCloudwatchLogsExports", valid_603498
  var valid_603499 = query.getOrDefault("EngineVersion")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "EngineVersion", valid_603499
  var valid_603500 = query.getOrDefault("Action")
  valid_603500 = validateParameter(valid_603500, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_603500 != nil:
    section.add "Action", valid_603500
  var valid_603501 = query.getOrDefault("Port")
  valid_603501 = validateParameter(valid_603501, JInt, required = false, default = nil)
  if valid_603501 != nil:
    section.add "Port", valid_603501
  var valid_603502 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603502 = validateParameter(valid_603502, JArray, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "VpcSecurityGroupIds", valid_603502
  var valid_603503 = query.getOrDefault("DBSubnetGroupName")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "DBSubnetGroupName", valid_603503
  var valid_603504 = query.getOrDefault("Version")
  valid_603504 = validateParameter(valid_603504, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603504 != nil:
    section.add "Version", valid_603504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603505 = header.getOrDefault("X-Amz-Signature")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Signature", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Content-Sha256", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Date")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Date", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Credential")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Credential", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Security-Token")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Security-Token", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Algorithm")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Algorithm", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-SignedHeaders", valid_603511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603512: Call_GetRestoreDBClusterFromSnapshot_603488;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_603512.validator(path, query, header, formData, body)
  let scheme = call_603512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603512.url(scheme.get, call_603512.host, call_603512.base,
                         call_603512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603512, url, valid)

proc call*(call_603513: Call_GetRestoreDBClusterFromSnapshot_603488;
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
  var query_603514 = newJObject()
  add(query_603514, "DeletionProtection", newJBool(DeletionProtection))
  add(query_603514, "Engine", newJString(Engine))
  add(query_603514, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  if Tags != nil:
    query_603514.add "Tags", Tags
  add(query_603514, "KmsKeyId", newJString(KmsKeyId))
  add(query_603514, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if AvailabilityZones != nil:
    query_603514.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    query_603514.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_603514, "EngineVersion", newJString(EngineVersion))
  add(query_603514, "Action", newJString(Action))
  add(query_603514, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_603514.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603514, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603514, "Version", newJString(Version))
  result = call_603513.call(nil, query_603514, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_603488(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_603489, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_603490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_603569 = ref object of OpenApiRestCall_601373
proc url_PostRestoreDBClusterToPointInTime_603571(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBClusterToPointInTime_603570(path: JsonNode;
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
  var valid_603572 = query.getOrDefault("Action")
  valid_603572 = validateParameter(valid_603572, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_603572 != nil:
    section.add "Action", valid_603572
  var valid_603573 = query.getOrDefault("Version")
  valid_603573 = validateParameter(valid_603573, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603573 != nil:
    section.add "Version", valid_603573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603574 = header.getOrDefault("X-Amz-Signature")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Signature", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Content-Sha256", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Date")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Date", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Credential")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Credential", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Security-Token")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Security-Token", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Algorithm")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Algorithm", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-SignedHeaders", valid_603580
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
  var valid_603581 = formData.getOrDefault("Port")
  valid_603581 = validateParameter(valid_603581, JInt, required = false, default = nil)
  if valid_603581 != nil:
    section.add "Port", valid_603581
  var valid_603582 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603582 = validateParameter(valid_603582, JArray, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "VpcSecurityGroupIds", valid_603582
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterIdentifier` field"
  var valid_603583 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_603583 = validateParameter(valid_603583, JString, required = true,
                                 default = nil)
  if valid_603583 != nil:
    section.add "SourceDBClusterIdentifier", valid_603583
  var valid_603584 = formData.getOrDefault("KmsKeyId")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "KmsKeyId", valid_603584
  var valid_603585 = formData.getOrDefault("UseLatestRestorableTime")
  valid_603585 = validateParameter(valid_603585, JBool, required = false, default = nil)
  if valid_603585 != nil:
    section.add "UseLatestRestorableTime", valid_603585
  var valid_603586 = formData.getOrDefault("RestoreToTime")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "RestoreToTime", valid_603586
  var valid_603587 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_603587 = validateParameter(valid_603587, JArray, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "EnableCloudwatchLogsExports", valid_603587
  var valid_603588 = formData.getOrDefault("Tags")
  valid_603588 = validateParameter(valid_603588, JArray, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "Tags", valid_603588
  var valid_603589 = formData.getOrDefault("DBSubnetGroupName")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "DBSubnetGroupName", valid_603589
  var valid_603590 = formData.getOrDefault("DBClusterIdentifier")
  valid_603590 = validateParameter(valid_603590, JString, required = true,
                                 default = nil)
  if valid_603590 != nil:
    section.add "DBClusterIdentifier", valid_603590
  var valid_603591 = formData.getOrDefault("DeletionProtection")
  valid_603591 = validateParameter(valid_603591, JBool, required = false, default = nil)
  if valid_603591 != nil:
    section.add "DeletionProtection", valid_603591
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603592: Call_PostRestoreDBClusterToPointInTime_603569;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_603592.validator(path, query, header, formData, body)
  let scheme = call_603592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603592.url(scheme.get, call_603592.host, call_603592.base,
                         call_603592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603592, url, valid)

proc call*(call_603593: Call_PostRestoreDBClusterToPointInTime_603569;
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
  var query_603594 = newJObject()
  var formData_603595 = newJObject()
  add(formData_603595, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_603595.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603595, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_603595, "KmsKeyId", newJString(KmsKeyId))
  add(formData_603595, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_603595, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    formData_603595.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_603594, "Action", newJString(Action))
  if Tags != nil:
    formData_603595.add "Tags", Tags
  add(formData_603595, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603594, "Version", newJString(Version))
  add(formData_603595, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_603595, "DeletionProtection", newJBool(DeletionProtection))
  result = call_603593.call(nil, query_603594, nil, formData_603595, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_603569(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_603570, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_603571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_603543 = ref object of OpenApiRestCall_601373
proc url_GetRestoreDBClusterToPointInTime_603545(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBClusterToPointInTime_603544(path: JsonNode;
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
  var valid_603546 = query.getOrDefault("DeletionProtection")
  valid_603546 = validateParameter(valid_603546, JBool, required = false, default = nil)
  if valid_603546 != nil:
    section.add "DeletionProtection", valid_603546
  var valid_603547 = query.getOrDefault("UseLatestRestorableTime")
  valid_603547 = validateParameter(valid_603547, JBool, required = false, default = nil)
  if valid_603547 != nil:
    section.add "UseLatestRestorableTime", valid_603547
  var valid_603548 = query.getOrDefault("Tags")
  valid_603548 = validateParameter(valid_603548, JArray, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "Tags", valid_603548
  var valid_603549 = query.getOrDefault("KmsKeyId")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "KmsKeyId", valid_603549
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_603550 = query.getOrDefault("DBClusterIdentifier")
  valid_603550 = validateParameter(valid_603550, JString, required = true,
                                 default = nil)
  if valid_603550 != nil:
    section.add "DBClusterIdentifier", valid_603550
  var valid_603551 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_603551 = validateParameter(valid_603551, JString, required = true,
                                 default = nil)
  if valid_603551 != nil:
    section.add "SourceDBClusterIdentifier", valid_603551
  var valid_603552 = query.getOrDefault("RestoreToTime")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "RestoreToTime", valid_603552
  var valid_603553 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_603553 = validateParameter(valid_603553, JArray, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "EnableCloudwatchLogsExports", valid_603553
  var valid_603554 = query.getOrDefault("Action")
  valid_603554 = validateParameter(valid_603554, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_603554 != nil:
    section.add "Action", valid_603554
  var valid_603555 = query.getOrDefault("Port")
  valid_603555 = validateParameter(valid_603555, JInt, required = false, default = nil)
  if valid_603555 != nil:
    section.add "Port", valid_603555
  var valid_603556 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603556 = validateParameter(valid_603556, JArray, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "VpcSecurityGroupIds", valid_603556
  var valid_603557 = query.getOrDefault("DBSubnetGroupName")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "DBSubnetGroupName", valid_603557
  var valid_603558 = query.getOrDefault("Version")
  valid_603558 = validateParameter(valid_603558, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603558 != nil:
    section.add "Version", valid_603558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603559 = header.getOrDefault("X-Amz-Signature")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Signature", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Content-Sha256", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Date")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Date", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Credential")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Credential", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Security-Token")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Security-Token", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Algorithm")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Algorithm", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-SignedHeaders", valid_603565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603566: Call_GetRestoreDBClusterToPointInTime_603543;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_603566.validator(path, query, header, formData, body)
  let scheme = call_603566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603566.url(scheme.get, call_603566.host, call_603566.base,
                         call_603566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603566, url, valid)

proc call*(call_603567: Call_GetRestoreDBClusterToPointInTime_603543;
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
  var query_603568 = newJObject()
  add(query_603568, "DeletionProtection", newJBool(DeletionProtection))
  add(query_603568, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_603568.add "Tags", Tags
  add(query_603568, "KmsKeyId", newJString(KmsKeyId))
  add(query_603568, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603568, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_603568, "RestoreToTime", newJString(RestoreToTime))
  if EnableCloudwatchLogsExports != nil:
    query_603568.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(query_603568, "Action", newJString(Action))
  add(query_603568, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_603568.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603568, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603568, "Version", newJString(Version))
  result = call_603567.call(nil, query_603568, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_603543(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_603544, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_603545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_603612 = ref object of OpenApiRestCall_601373
proc url_PostStartDBCluster_603614(protocol: Scheme; host: string; base: string;
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

proc validate_PostStartDBCluster_603613(path: JsonNode; query: JsonNode;
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
  var valid_603615 = query.getOrDefault("Action")
  valid_603615 = validateParameter(valid_603615, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_603615 != nil:
    section.add "Action", valid_603615
  var valid_603616 = query.getOrDefault("Version")
  valid_603616 = validateParameter(valid_603616, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603616 != nil:
    section.add "Version", valid_603616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603617 = header.getOrDefault("X-Amz-Signature")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Signature", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Content-Sha256", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Date")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Date", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Credential")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Credential", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Security-Token")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Security-Token", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Algorithm")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Algorithm", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-SignedHeaders", valid_603623
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_603624 = formData.getOrDefault("DBClusterIdentifier")
  valid_603624 = validateParameter(valid_603624, JString, required = true,
                                 default = nil)
  if valid_603624 != nil:
    section.add "DBClusterIdentifier", valid_603624
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603625: Call_PostStartDBCluster_603612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_603625.validator(path, query, header, formData, body)
  let scheme = call_603625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603625.url(scheme.get, call_603625.host, call_603625.base,
                         call_603625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603625, url, valid)

proc call*(call_603626: Call_PostStartDBCluster_603612;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_603627 = newJObject()
  var formData_603628 = newJObject()
  add(query_603627, "Action", newJString(Action))
  add(query_603627, "Version", newJString(Version))
  add(formData_603628, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_603626.call(nil, query_603627, nil, formData_603628, nil)

var postStartDBCluster* = Call_PostStartDBCluster_603612(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_603613, base: "/",
    url: url_PostStartDBCluster_603614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_603596 = ref object of OpenApiRestCall_601373
proc url_GetStartDBCluster_603598(protocol: Scheme; host: string; base: string;
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

proc validate_GetStartDBCluster_603597(path: JsonNode; query: JsonNode;
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
  var valid_603599 = query.getOrDefault("DBClusterIdentifier")
  valid_603599 = validateParameter(valid_603599, JString, required = true,
                                 default = nil)
  if valid_603599 != nil:
    section.add "DBClusterIdentifier", valid_603599
  var valid_603600 = query.getOrDefault("Action")
  valid_603600 = validateParameter(valid_603600, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_603600 != nil:
    section.add "Action", valid_603600
  var valid_603601 = query.getOrDefault("Version")
  valid_603601 = validateParameter(valid_603601, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603601 != nil:
    section.add "Version", valid_603601
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603602 = header.getOrDefault("X-Amz-Signature")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Signature", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Content-Sha256", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Date")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Date", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Credential")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Credential", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Security-Token")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Security-Token", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Algorithm")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Algorithm", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-SignedHeaders", valid_603608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603609: Call_GetStartDBCluster_603596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_603609.validator(path, query, header, formData, body)
  let scheme = call_603609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603609.url(scheme.get, call_603609.host, call_603609.base,
                         call_603609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603609, url, valid)

proc call*(call_603610: Call_GetStartDBCluster_603596; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603611 = newJObject()
  add(query_603611, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603611, "Action", newJString(Action))
  add(query_603611, "Version", newJString(Version))
  result = call_603610.call(nil, query_603611, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_603596(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_603597,
    base: "/", url: url_GetStartDBCluster_603598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_603645 = ref object of OpenApiRestCall_601373
proc url_PostStopDBCluster_603647(protocol: Scheme; host: string; base: string;
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

proc validate_PostStopDBCluster_603646(path: JsonNode; query: JsonNode;
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
  var valid_603648 = query.getOrDefault("Action")
  valid_603648 = validateParameter(valid_603648, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_603648 != nil:
    section.add "Action", valid_603648
  var valid_603649 = query.getOrDefault("Version")
  valid_603649 = validateParameter(valid_603649, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603649 != nil:
    section.add "Version", valid_603649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603650 = header.getOrDefault("X-Amz-Signature")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Signature", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Content-Sha256", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Date")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Date", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Credential")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Credential", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Security-Token")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Security-Token", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Algorithm")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Algorithm", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-SignedHeaders", valid_603656
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_603657 = formData.getOrDefault("DBClusterIdentifier")
  valid_603657 = validateParameter(valid_603657, JString, required = true,
                                 default = nil)
  if valid_603657 != nil:
    section.add "DBClusterIdentifier", valid_603657
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603658: Call_PostStopDBCluster_603645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_603658.validator(path, query, header, formData, body)
  let scheme = call_603658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603658.url(scheme.get, call_603658.host, call_603658.base,
                         call_603658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603658, url, valid)

proc call*(call_603659: Call_PostStopDBCluster_603645; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  var query_603660 = newJObject()
  var formData_603661 = newJObject()
  add(query_603660, "Action", newJString(Action))
  add(query_603660, "Version", newJString(Version))
  add(formData_603661, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  result = call_603659.call(nil, query_603660, nil, formData_603661, nil)

var postStopDBCluster* = Call_PostStopDBCluster_603645(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_603646,
    base: "/", url: url_PostStopDBCluster_603647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_603629 = ref object of OpenApiRestCall_601373
proc url_GetStopDBCluster_603631(protocol: Scheme; host: string; base: string;
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

proc validate_GetStopDBCluster_603630(path: JsonNode; query: JsonNode;
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
  var valid_603632 = query.getOrDefault("DBClusterIdentifier")
  valid_603632 = validateParameter(valid_603632, JString, required = true,
                                 default = nil)
  if valid_603632 != nil:
    section.add "DBClusterIdentifier", valid_603632
  var valid_603633 = query.getOrDefault("Action")
  valid_603633 = validateParameter(valid_603633, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_603633 != nil:
    section.add "Action", valid_603633
  var valid_603634 = query.getOrDefault("Version")
  valid_603634 = validateParameter(valid_603634, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_603634 != nil:
    section.add "Version", valid_603634
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603635 = header.getOrDefault("X-Amz-Signature")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Signature", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Content-Sha256", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Date")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Date", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Credential")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Credential", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Security-Token")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Security-Token", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Algorithm")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Algorithm", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-SignedHeaders", valid_603641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603642: Call_GetStopDBCluster_603629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_603642.validator(path, query, header, formData, body)
  let scheme = call_603642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603642.url(scheme.get, call_603642.host, call_603642.base,
                         call_603642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603642, url, valid)

proc call*(call_603643: Call_GetStopDBCluster_603629; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603644 = newJObject()
  add(query_603644, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_603644, "Action", newJString(Action))
  add(query_603644, "Version", newJString(Version))
  result = call_603643.call(nil, query_603644, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_603629(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_603630,
    base: "/", url: url_GetStopDBCluster_603631,
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

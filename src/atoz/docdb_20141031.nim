
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593421): Option[Scheme] {.used.} =
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
  awsServiceName = "docdb"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddTagsToResource_594030 = ref object of OpenApiRestCall_593421
proc url_PostAddTagsToResource_594032(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_594031(path: JsonNode; query: JsonNode;
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
  var valid_594033 = query.getOrDefault("Action")
  valid_594033 = validateParameter(valid_594033, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_594033 != nil:
    section.add "Action", valid_594033
  var valid_594034 = query.getOrDefault("Version")
  valid_594034 = validateParameter(valid_594034, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594034 != nil:
    section.add "Version", valid_594034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594035 = header.getOrDefault("X-Amz-Date")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Date", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Security-Token")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Security-Token", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Content-Sha256", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Algorithm")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Algorithm", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Signature")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Signature", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-SignedHeaders", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Credential")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Credential", valid_594041
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be assigned to the Amazon DocumentDB resource. 
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are added to. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_594042 = formData.getOrDefault("Tags")
  valid_594042 = validateParameter(valid_594042, JArray, required = true, default = nil)
  if valid_594042 != nil:
    section.add "Tags", valid_594042
  var valid_594043 = formData.getOrDefault("ResourceName")
  valid_594043 = validateParameter(valid_594043, JString, required = true,
                                 default = nil)
  if valid_594043 != nil:
    section.add "ResourceName", valid_594043
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594044: Call_PostAddTagsToResource_594030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_594044.validator(path, query, header, formData, body)
  let scheme = call_594044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594044.url(scheme.get, call_594044.host, call_594044.base,
                         call_594044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594044, url, valid)

proc call*(call_594045: Call_PostAddTagsToResource_594030; Tags: JsonNode;
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
  var query_594046 = newJObject()
  var formData_594047 = newJObject()
  if Tags != nil:
    formData_594047.add "Tags", Tags
  add(query_594046, "Action", newJString(Action))
  add(formData_594047, "ResourceName", newJString(ResourceName))
  add(query_594046, "Version", newJString(Version))
  result = call_594045.call(nil, query_594046, nil, formData_594047, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_594030(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_594031, base: "/",
    url: url_PostAddTagsToResource_594032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_593758 = ref object of OpenApiRestCall_593421
proc url_GetAddTagsToResource_593760(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_593759(path: JsonNode; query: JsonNode;
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
  var valid_593872 = query.getOrDefault("Tags")
  valid_593872 = validateParameter(valid_593872, JArray, required = true, default = nil)
  if valid_593872 != nil:
    section.add "Tags", valid_593872
  var valid_593873 = query.getOrDefault("ResourceName")
  valid_593873 = validateParameter(valid_593873, JString, required = true,
                                 default = nil)
  if valid_593873 != nil:
    section.add "ResourceName", valid_593873
  var valid_593887 = query.getOrDefault("Action")
  valid_593887 = validateParameter(valid_593887, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_593887 != nil:
    section.add "Action", valid_593887
  var valid_593888 = query.getOrDefault("Version")
  valid_593888 = validateParameter(valid_593888, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_593888 != nil:
    section.add "Version", valid_593888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593889 = header.getOrDefault("X-Amz-Date")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Date", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Security-Token")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Security-Token", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Content-Sha256", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Algorithm")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Algorithm", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Signature")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Signature", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-SignedHeaders", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Credential")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Credential", valid_593895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593918: Call_GetAddTagsToResource_593758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an Amazon DocumentDB resource. You can use these tags with cost allocation reporting to track costs that are associated with Amazon DocumentDB resources. or in a <code>Condition</code> statement in an AWS Identity and Access Management (IAM) policy for Amazon DocumentDB.
  ## 
  let valid = call_593918.validator(path, query, header, formData, body)
  let scheme = call_593918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593918.url(scheme.get, call_593918.host, call_593918.base,
                         call_593918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593918, url, valid)

proc call*(call_593989: Call_GetAddTagsToResource_593758; Tags: JsonNode;
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
  var query_593990 = newJObject()
  if Tags != nil:
    query_593990.add "Tags", Tags
  add(query_593990, "ResourceName", newJString(ResourceName))
  add(query_593990, "Action", newJString(Action))
  add(query_593990, "Version", newJString(Version))
  result = call_593989.call(nil, query_593990, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_593758(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_593759, base: "/",
    url: url_GetAddTagsToResource_593760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyPendingMaintenanceAction_594066 = ref object of OpenApiRestCall_593421
proc url_PostApplyPendingMaintenanceAction_594068(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplyPendingMaintenanceAction_594067(path: JsonNode;
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
  var valid_594069 = query.getOrDefault("Action")
  valid_594069 = validateParameter(valid_594069, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_594069 != nil:
    section.add "Action", valid_594069
  var valid_594070 = query.getOrDefault("Version")
  valid_594070 = validateParameter(valid_594070, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594070 != nil:
    section.add "Version", valid_594070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594071 = header.getOrDefault("X-Amz-Date")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Date", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Security-Token")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Security-Token", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Content-Sha256", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Algorithm")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Algorithm", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Signature")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Signature", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-SignedHeaders", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Credential")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Credential", valid_594077
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
  var valid_594078 = formData.getOrDefault("ApplyAction")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = nil)
  if valid_594078 != nil:
    section.add "ApplyAction", valid_594078
  var valid_594079 = formData.getOrDefault("ResourceIdentifier")
  valid_594079 = validateParameter(valid_594079, JString, required = true,
                                 default = nil)
  if valid_594079 != nil:
    section.add "ResourceIdentifier", valid_594079
  var valid_594080 = formData.getOrDefault("OptInType")
  valid_594080 = validateParameter(valid_594080, JString, required = true,
                                 default = nil)
  if valid_594080 != nil:
    section.add "OptInType", valid_594080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594081: Call_PostApplyPendingMaintenanceAction_594066;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_594081.validator(path, query, header, formData, body)
  let scheme = call_594081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594081.url(scheme.get, call_594081.host, call_594081.base,
                         call_594081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594081, url, valid)

proc call*(call_594082: Call_PostApplyPendingMaintenanceAction_594066;
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
  var query_594083 = newJObject()
  var formData_594084 = newJObject()
  add(query_594083, "Action", newJString(Action))
  add(formData_594084, "ApplyAction", newJString(ApplyAction))
  add(formData_594084, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(formData_594084, "OptInType", newJString(OptInType))
  add(query_594083, "Version", newJString(Version))
  result = call_594082.call(nil, query_594083, nil, formData_594084, nil)

var postApplyPendingMaintenanceAction* = Call_PostApplyPendingMaintenanceAction_594066(
    name: "postApplyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_PostApplyPendingMaintenanceAction_594067, base: "/",
    url: url_PostApplyPendingMaintenanceAction_594068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyPendingMaintenanceAction_594048 = ref object of OpenApiRestCall_593421
proc url_GetApplyPendingMaintenanceAction_594050(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplyPendingMaintenanceAction_594049(path: JsonNode;
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
  var valid_594051 = query.getOrDefault("ApplyAction")
  valid_594051 = validateParameter(valid_594051, JString, required = true,
                                 default = nil)
  if valid_594051 != nil:
    section.add "ApplyAction", valid_594051
  var valid_594052 = query.getOrDefault("ResourceIdentifier")
  valid_594052 = validateParameter(valid_594052, JString, required = true,
                                 default = nil)
  if valid_594052 != nil:
    section.add "ResourceIdentifier", valid_594052
  var valid_594053 = query.getOrDefault("Action")
  valid_594053 = validateParameter(valid_594053, JString, required = true, default = newJString(
      "ApplyPendingMaintenanceAction"))
  if valid_594053 != nil:
    section.add "Action", valid_594053
  var valid_594054 = query.getOrDefault("OptInType")
  valid_594054 = validateParameter(valid_594054, JString, required = true,
                                 default = nil)
  if valid_594054 != nil:
    section.add "OptInType", valid_594054
  var valid_594055 = query.getOrDefault("Version")
  valid_594055 = validateParameter(valid_594055, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594055 != nil:
    section.add "Version", valid_594055
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594056 = header.getOrDefault("X-Amz-Date")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Date", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Security-Token")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Security-Token", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Content-Sha256", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Algorithm")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Algorithm", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Signature")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Signature", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-SignedHeaders", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Credential")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Credential", valid_594062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594063: Call_GetApplyPendingMaintenanceAction_594048;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a DB instance).
  ## 
  let valid = call_594063.validator(path, query, header, formData, body)
  let scheme = call_594063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594063.url(scheme.get, call_594063.host, call_594063.base,
                         call_594063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594063, url, valid)

proc call*(call_594064: Call_GetApplyPendingMaintenanceAction_594048;
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
  var query_594065 = newJObject()
  add(query_594065, "ApplyAction", newJString(ApplyAction))
  add(query_594065, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_594065, "Action", newJString(Action))
  add(query_594065, "OptInType", newJString(OptInType))
  add(query_594065, "Version", newJString(Version))
  result = call_594064.call(nil, query_594065, nil, nil, nil)

var getApplyPendingMaintenanceAction* = Call_GetApplyPendingMaintenanceAction_594048(
    name: "getApplyPendingMaintenanceAction", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ApplyPendingMaintenanceAction",
    validator: validate_GetApplyPendingMaintenanceAction_594049, base: "/",
    url: url_GetApplyPendingMaintenanceAction_594050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterParameterGroup_594104 = ref object of OpenApiRestCall_593421
proc url_PostCopyDBClusterParameterGroup_594106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBClusterParameterGroup_594105(path: JsonNode;
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
  var valid_594107 = query.getOrDefault("Action")
  valid_594107 = validateParameter(valid_594107, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_594107 != nil:
    section.add "Action", valid_594107
  var valid_594108 = query.getOrDefault("Version")
  valid_594108 = validateParameter(valid_594108, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594108 != nil:
    section.add "Version", valid_594108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594109 = header.getOrDefault("X-Amz-Date")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Date", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Security-Token")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Security-Token", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Content-Sha256", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Algorithm")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Algorithm", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Signature")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Signature", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-SignedHeaders", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
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
  var valid_594116 = formData.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_594116 = validateParameter(valid_594116, JString, required = true,
                                 default = nil)
  if valid_594116 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_594116
  var valid_594117 = formData.getOrDefault("Tags")
  valid_594117 = validateParameter(valid_594117, JArray, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "Tags", valid_594117
  var valid_594118 = formData.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_594118 = validateParameter(valid_594118, JString, required = true,
                                 default = nil)
  if valid_594118 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_594118
  var valid_594119 = formData.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_594119 = validateParameter(valid_594119, JString, required = true,
                                 default = nil)
  if valid_594119 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_594119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594120: Call_PostCopyDBClusterParameterGroup_594104;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_594120.validator(path, query, header, formData, body)
  let scheme = call_594120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594120.url(scheme.get, call_594120.host, call_594120.base,
                         call_594120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594120, url, valid)

proc call*(call_594121: Call_PostCopyDBClusterParameterGroup_594104;
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
  var query_594122 = newJObject()
  var formData_594123 = newJObject()
  add(formData_594123, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  if Tags != nil:
    formData_594123.add "Tags", Tags
  add(query_594122, "Action", newJString(Action))
  add(formData_594123, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  add(formData_594123, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_594122, "Version", newJString(Version))
  result = call_594121.call(nil, query_594122, nil, formData_594123, nil)

var postCopyDBClusterParameterGroup* = Call_PostCopyDBClusterParameterGroup_594104(
    name: "postCopyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_PostCopyDBClusterParameterGroup_594105, base: "/",
    url: url_PostCopyDBClusterParameterGroup_594106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterParameterGroup_594085 = ref object of OpenApiRestCall_593421
proc url_GetCopyDBClusterParameterGroup_594087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBClusterParameterGroup_594086(path: JsonNode;
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
  var valid_594088 = query.getOrDefault("SourceDBClusterParameterGroupIdentifier")
  valid_594088 = validateParameter(valid_594088, JString, required = true,
                                 default = nil)
  if valid_594088 != nil:
    section.add "SourceDBClusterParameterGroupIdentifier", valid_594088
  var valid_594089 = query.getOrDefault("Tags")
  valid_594089 = validateParameter(valid_594089, JArray, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "Tags", valid_594089
  var valid_594090 = query.getOrDefault("TargetDBClusterParameterGroupDescription")
  valid_594090 = validateParameter(valid_594090, JString, required = true,
                                 default = nil)
  if valid_594090 != nil:
    section.add "TargetDBClusterParameterGroupDescription", valid_594090
  var valid_594091 = query.getOrDefault("Action")
  valid_594091 = validateParameter(valid_594091, JString, required = true, default = newJString(
      "CopyDBClusterParameterGroup"))
  if valid_594091 != nil:
    section.add "Action", valid_594091
  var valid_594092 = query.getOrDefault("TargetDBClusterParameterGroupIdentifier")
  valid_594092 = validateParameter(valid_594092, JString, required = true,
                                 default = nil)
  if valid_594092 != nil:
    section.add "TargetDBClusterParameterGroupIdentifier", valid_594092
  var valid_594093 = query.getOrDefault("Version")
  valid_594093 = validateParameter(valid_594093, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594093 != nil:
    section.add "Version", valid_594093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594094 = header.getOrDefault("X-Amz-Date")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Date", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Security-Token")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Security-Token", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Content-Sha256", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Algorithm")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Algorithm", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Signature")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Signature", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-SignedHeaders", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Credential")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Credential", valid_594100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594101: Call_GetCopyDBClusterParameterGroup_594085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the specified DB cluster parameter group.
  ## 
  let valid = call_594101.validator(path, query, header, formData, body)
  let scheme = call_594101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594101.url(scheme.get, call_594101.host, call_594101.base,
                         call_594101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594101, url, valid)

proc call*(call_594102: Call_GetCopyDBClusterParameterGroup_594085;
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
  var query_594103 = newJObject()
  add(query_594103, "SourceDBClusterParameterGroupIdentifier",
      newJString(SourceDBClusterParameterGroupIdentifier))
  if Tags != nil:
    query_594103.add "Tags", Tags
  add(query_594103, "TargetDBClusterParameterGroupDescription",
      newJString(TargetDBClusterParameterGroupDescription))
  add(query_594103, "Action", newJString(Action))
  add(query_594103, "TargetDBClusterParameterGroupIdentifier",
      newJString(TargetDBClusterParameterGroupIdentifier))
  add(query_594103, "Version", newJString(Version))
  result = call_594102.call(nil, query_594103, nil, nil, nil)

var getCopyDBClusterParameterGroup* = Call_GetCopyDBClusterParameterGroup_594085(
    name: "getCopyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterParameterGroup",
    validator: validate_GetCopyDBClusterParameterGroup_594086, base: "/",
    url: url_GetCopyDBClusterParameterGroup_594087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBClusterSnapshot_594145 = ref object of OpenApiRestCall_593421
proc url_PostCopyDBClusterSnapshot_594147(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBClusterSnapshot_594146(path: JsonNode; query: JsonNode;
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
  var valid_594148 = query.getOrDefault("Action")
  valid_594148 = validateParameter(valid_594148, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_594148 != nil:
    section.add "Action", valid_594148
  var valid_594149 = query.getOrDefault("Version")
  valid_594149 = validateParameter(valid_594149, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594149 != nil:
    section.add "Version", valid_594149
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594150 = header.getOrDefault("X-Amz-Date")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Date", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Security-Token")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Security-Token", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Content-Sha256", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Algorithm")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Algorithm", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Signature")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Signature", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-SignedHeaders", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Credential")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Credential", valid_594156
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
  var valid_594157 = formData.getOrDefault("PreSignedUrl")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "PreSignedUrl", valid_594157
  var valid_594158 = formData.getOrDefault("Tags")
  valid_594158 = validateParameter(valid_594158, JArray, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "Tags", valid_594158
  var valid_594159 = formData.getOrDefault("CopyTags")
  valid_594159 = validateParameter(valid_594159, JBool, required = false, default = nil)
  if valid_594159 != nil:
    section.add "CopyTags", valid_594159
  assert formData != nil, "formData argument is necessary due to required `SourceDBClusterSnapshotIdentifier` field"
  var valid_594160 = formData.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_594160 = validateParameter(valid_594160, JString, required = true,
                                 default = nil)
  if valid_594160 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_594160
  var valid_594161 = formData.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_594161 = validateParameter(valid_594161, JString, required = true,
                                 default = nil)
  if valid_594161 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_594161
  var valid_594162 = formData.getOrDefault("KmsKeyId")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "KmsKeyId", valid_594162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594163: Call_PostCopyDBClusterSnapshot_594145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_594163.validator(path, query, header, formData, body)
  let scheme = call_594163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594163.url(scheme.get, call_594163.host, call_594163.base,
                         call_594163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594163, url, valid)

proc call*(call_594164: Call_PostCopyDBClusterSnapshot_594145;
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
  var query_594165 = newJObject()
  var formData_594166 = newJObject()
  add(formData_594166, "PreSignedUrl", newJString(PreSignedUrl))
  if Tags != nil:
    formData_594166.add "Tags", Tags
  add(formData_594166, "CopyTags", newJBool(CopyTags))
  add(formData_594166, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(formData_594166, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  add(query_594165, "Action", newJString(Action))
  add(formData_594166, "KmsKeyId", newJString(KmsKeyId))
  add(query_594165, "Version", newJString(Version))
  result = call_594164.call(nil, query_594165, nil, formData_594166, nil)

var postCopyDBClusterSnapshot* = Call_PostCopyDBClusterSnapshot_594145(
    name: "postCopyDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_PostCopyDBClusterSnapshot_594146, base: "/",
    url: url_PostCopyDBClusterSnapshot_594147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBClusterSnapshot_594124 = ref object of OpenApiRestCall_593421
proc url_GetCopyDBClusterSnapshot_594126(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBClusterSnapshot_594125(path: JsonNode; query: JsonNode;
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
  var valid_594127 = query.getOrDefault("PreSignedUrl")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "PreSignedUrl", valid_594127
  assert query != nil, "query argument is necessary due to required `TargetDBClusterSnapshotIdentifier` field"
  var valid_594128 = query.getOrDefault("TargetDBClusterSnapshotIdentifier")
  valid_594128 = validateParameter(valid_594128, JString, required = true,
                                 default = nil)
  if valid_594128 != nil:
    section.add "TargetDBClusterSnapshotIdentifier", valid_594128
  var valid_594129 = query.getOrDefault("Tags")
  valid_594129 = validateParameter(valid_594129, JArray, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "Tags", valid_594129
  var valid_594130 = query.getOrDefault("Action")
  valid_594130 = validateParameter(valid_594130, JString, required = true,
                                 default = newJString("CopyDBClusterSnapshot"))
  if valid_594130 != nil:
    section.add "Action", valid_594130
  var valid_594131 = query.getOrDefault("KmsKeyId")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "KmsKeyId", valid_594131
  var valid_594132 = query.getOrDefault("SourceDBClusterSnapshotIdentifier")
  valid_594132 = validateParameter(valid_594132, JString, required = true,
                                 default = nil)
  if valid_594132 != nil:
    section.add "SourceDBClusterSnapshotIdentifier", valid_594132
  var valid_594133 = query.getOrDefault("Version")
  valid_594133 = validateParameter(valid_594133, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594133 != nil:
    section.add "Version", valid_594133
  var valid_594134 = query.getOrDefault("CopyTags")
  valid_594134 = validateParameter(valid_594134, JBool, required = false, default = nil)
  if valid_594134 != nil:
    section.add "CopyTags", valid_594134
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594135 = header.getOrDefault("X-Amz-Date")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Date", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Security-Token")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Security-Token", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Content-Sha256", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Algorithm")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Algorithm", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Signature")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Signature", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-SignedHeaders", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Credential")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Credential", valid_594141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594142: Call_GetCopyDBClusterSnapshot_594124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies a snapshot of a DB cluster.</p> <p>To copy a DB cluster snapshot from a shared manual DB cluster snapshot, <code>SourceDBClusterSnapshotIdentifier</code> must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.</p> <p>To cancel the copy operation after it is in progress, delete the target DB cluster snapshot identified by <code>TargetDBClusterSnapshotIdentifier</code> while that DB cluster snapshot is in the <i>copying</i> status.</p>
  ## 
  let valid = call_594142.validator(path, query, header, formData, body)
  let scheme = call_594142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594142.url(scheme.get, call_594142.host, call_594142.base,
                         call_594142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594142, url, valid)

proc call*(call_594143: Call_GetCopyDBClusterSnapshot_594124;
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
  var query_594144 = newJObject()
  add(query_594144, "PreSignedUrl", newJString(PreSignedUrl))
  add(query_594144, "TargetDBClusterSnapshotIdentifier",
      newJString(TargetDBClusterSnapshotIdentifier))
  if Tags != nil:
    query_594144.add "Tags", Tags
  add(query_594144, "Action", newJString(Action))
  add(query_594144, "KmsKeyId", newJString(KmsKeyId))
  add(query_594144, "SourceDBClusterSnapshotIdentifier",
      newJString(SourceDBClusterSnapshotIdentifier))
  add(query_594144, "Version", newJString(Version))
  add(query_594144, "CopyTags", newJBool(CopyTags))
  result = call_594143.call(nil, query_594144, nil, nil, nil)

var getCopyDBClusterSnapshot* = Call_GetCopyDBClusterSnapshot_594124(
    name: "getCopyDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBClusterSnapshot",
    validator: validate_GetCopyDBClusterSnapshot_594125, base: "/",
    url: url_GetCopyDBClusterSnapshot_594126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBCluster_594200 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBCluster_594202(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBCluster_594201(path: JsonNode; query: JsonNode;
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
  var valid_594203 = query.getOrDefault("Action")
  valid_594203 = validateParameter(valid_594203, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_594203 != nil:
    section.add "Action", valid_594203
  var valid_594204 = query.getOrDefault("Version")
  valid_594204 = validateParameter(valid_594204, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594204 != nil:
    section.add "Version", valid_594204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594205 = header.getOrDefault("X-Amz-Date")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Date", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Security-Token")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Security-Token", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Content-Sha256", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Algorithm")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Algorithm", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Signature")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Signature", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-SignedHeaders", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Credential")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Credential", valid_594211
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
  ##   DeletionProtection: JBool
  ##                     : Specifies whether this cluster can be deleted. If <code>DeletionProtection</code> is enabled, the cluster cannot be deleted unless it is modified and <code>DeletionProtection</code> is disabled. <code>DeletionProtection</code> protects clusters from being accidentally deleted.
  ##   DBSubnetGroupName: JString
  ##                    : <p>A DB subnet group to associate with this DB cluster.</p> <p>Constraints: Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   AvailabilityZones: JArray
  ##                    : A list of Amazon EC2 Availability Zones that instances in the DB cluster can be created in.
  ##   DBClusterParameterGroupName: JString
  ##                              :  The name of the DB cluster parameter group to associate with this DB cluster.
  ##   MasterUsername: JString (required)
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 16 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
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
  var valid_594212 = formData.getOrDefault("Port")
  valid_594212 = validateParameter(valid_594212, JInt, required = false, default = nil)
  if valid_594212 != nil:
    section.add "Port", valid_594212
  var valid_594213 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_594213 = validateParameter(valid_594213, JArray, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "VpcSecurityGroupIds", valid_594213
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_594214 = formData.getOrDefault("Engine")
  valid_594214 = validateParameter(valid_594214, JString, required = true,
                                 default = nil)
  if valid_594214 != nil:
    section.add "Engine", valid_594214
  var valid_594215 = formData.getOrDefault("BackupRetentionPeriod")
  valid_594215 = validateParameter(valid_594215, JInt, required = false, default = nil)
  if valid_594215 != nil:
    section.add "BackupRetentionPeriod", valid_594215
  var valid_594216 = formData.getOrDefault("Tags")
  valid_594216 = validateParameter(valid_594216, JArray, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "Tags", valid_594216
  var valid_594217 = formData.getOrDefault("MasterUserPassword")
  valid_594217 = validateParameter(valid_594217, JString, required = true,
                                 default = nil)
  if valid_594217 != nil:
    section.add "MasterUserPassword", valid_594217
  var valid_594218 = formData.getOrDefault("DeletionProtection")
  valid_594218 = validateParameter(valid_594218, JBool, required = false, default = nil)
  if valid_594218 != nil:
    section.add "DeletionProtection", valid_594218
  var valid_594219 = formData.getOrDefault("DBSubnetGroupName")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "DBSubnetGroupName", valid_594219
  var valid_594220 = formData.getOrDefault("AvailabilityZones")
  valid_594220 = validateParameter(valid_594220, JArray, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "AvailabilityZones", valid_594220
  var valid_594221 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "DBClusterParameterGroupName", valid_594221
  var valid_594222 = formData.getOrDefault("MasterUsername")
  valid_594222 = validateParameter(valid_594222, JString, required = true,
                                 default = nil)
  if valid_594222 != nil:
    section.add "MasterUsername", valid_594222
  var valid_594223 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_594223 = validateParameter(valid_594223, JArray, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "EnableCloudwatchLogsExports", valid_594223
  var valid_594224 = formData.getOrDefault("PreferredBackupWindow")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "PreferredBackupWindow", valid_594224
  var valid_594225 = formData.getOrDefault("KmsKeyId")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "KmsKeyId", valid_594225
  var valid_594226 = formData.getOrDefault("StorageEncrypted")
  valid_594226 = validateParameter(valid_594226, JBool, required = false, default = nil)
  if valid_594226 != nil:
    section.add "StorageEncrypted", valid_594226
  var valid_594227 = formData.getOrDefault("DBClusterIdentifier")
  valid_594227 = validateParameter(valid_594227, JString, required = true,
                                 default = nil)
  if valid_594227 != nil:
    section.add "DBClusterIdentifier", valid_594227
  var valid_594228 = formData.getOrDefault("EngineVersion")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "EngineVersion", valid_594228
  var valid_594229 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "PreferredMaintenanceWindow", valid_594229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594230: Call_PostCreateDBCluster_594200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_594230.validator(path, query, header, formData, body)
  let scheme = call_594230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594230.url(scheme.get, call_594230.host, call_594230.base,
                         call_594230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594230, url, valid)

proc call*(call_594231: Call_PostCreateDBCluster_594200; Engine: string;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
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
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 16 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
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
  var query_594232 = newJObject()
  var formData_594233 = newJObject()
  add(formData_594233, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_594233.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_594233, "Engine", newJString(Engine))
  add(formData_594233, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if Tags != nil:
    formData_594233.add "Tags", Tags
  add(formData_594233, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_594233, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_594233, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594232, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_594233.add "AvailabilityZones", AvailabilityZones
  add(formData_594233, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_594233, "MasterUsername", newJString(MasterUsername))
  if EnableCloudwatchLogsExports != nil:
    formData_594233.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_594233, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_594233, "KmsKeyId", newJString(KmsKeyId))
  add(formData_594233, "StorageEncrypted", newJBool(StorageEncrypted))
  add(formData_594233, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_594233, "EngineVersion", newJString(EngineVersion))
  add(query_594232, "Version", newJString(Version))
  add(formData_594233, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_594231.call(nil, query_594232, nil, formData_594233, nil)

var postCreateDBCluster* = Call_PostCreateDBCluster_594200(
    name: "postCreateDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBCluster",
    validator: validate_PostCreateDBCluster_594201, base: "/",
    url: url_PostCreateDBCluster_594202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBCluster_594167 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBCluster_594169(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBCluster_594168(path: JsonNode; query: JsonNode;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
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
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 16 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_594170 = query.getOrDefault("Engine")
  valid_594170 = validateParameter(valid_594170, JString, required = true,
                                 default = nil)
  if valid_594170 != nil:
    section.add "Engine", valid_594170
  var valid_594171 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "PreferredMaintenanceWindow", valid_594171
  var valid_594172 = query.getOrDefault("DBClusterParameterGroupName")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "DBClusterParameterGroupName", valid_594172
  var valid_594173 = query.getOrDefault("StorageEncrypted")
  valid_594173 = validateParameter(valid_594173, JBool, required = false, default = nil)
  if valid_594173 != nil:
    section.add "StorageEncrypted", valid_594173
  var valid_594174 = query.getOrDefault("AvailabilityZones")
  valid_594174 = validateParameter(valid_594174, JArray, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "AvailabilityZones", valid_594174
  var valid_594175 = query.getOrDefault("DBClusterIdentifier")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = nil)
  if valid_594175 != nil:
    section.add "DBClusterIdentifier", valid_594175
  var valid_594176 = query.getOrDefault("MasterUserPassword")
  valid_594176 = validateParameter(valid_594176, JString, required = true,
                                 default = nil)
  if valid_594176 != nil:
    section.add "MasterUserPassword", valid_594176
  var valid_594177 = query.getOrDefault("VpcSecurityGroupIds")
  valid_594177 = validateParameter(valid_594177, JArray, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "VpcSecurityGroupIds", valid_594177
  var valid_594178 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_594178 = validateParameter(valid_594178, JArray, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "EnableCloudwatchLogsExports", valid_594178
  var valid_594179 = query.getOrDefault("Tags")
  valid_594179 = validateParameter(valid_594179, JArray, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "Tags", valid_594179
  var valid_594180 = query.getOrDefault("BackupRetentionPeriod")
  valid_594180 = validateParameter(valid_594180, JInt, required = false, default = nil)
  if valid_594180 != nil:
    section.add "BackupRetentionPeriod", valid_594180
  var valid_594181 = query.getOrDefault("DeletionProtection")
  valid_594181 = validateParameter(valid_594181, JBool, required = false, default = nil)
  if valid_594181 != nil:
    section.add "DeletionProtection", valid_594181
  var valid_594182 = query.getOrDefault("Action")
  valid_594182 = validateParameter(valid_594182, JString, required = true,
                                 default = newJString("CreateDBCluster"))
  if valid_594182 != nil:
    section.add "Action", valid_594182
  var valid_594183 = query.getOrDefault("DBSubnetGroupName")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "DBSubnetGroupName", valid_594183
  var valid_594184 = query.getOrDefault("KmsKeyId")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "KmsKeyId", valid_594184
  var valid_594185 = query.getOrDefault("EngineVersion")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "EngineVersion", valid_594185
  var valid_594186 = query.getOrDefault("Port")
  valid_594186 = validateParameter(valid_594186, JInt, required = false, default = nil)
  if valid_594186 != nil:
    section.add "Port", valid_594186
  var valid_594187 = query.getOrDefault("PreferredBackupWindow")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "PreferredBackupWindow", valid_594187
  var valid_594188 = query.getOrDefault("Version")
  valid_594188 = validateParameter(valid_594188, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594188 != nil:
    section.add "Version", valid_594188
  var valid_594189 = query.getOrDefault("MasterUsername")
  valid_594189 = validateParameter(valid_594189, JString, required = true,
                                 default = nil)
  if valid_594189 != nil:
    section.add "MasterUsername", valid_594189
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594190 = header.getOrDefault("X-Amz-Date")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Date", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Security-Token")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Security-Token", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Content-Sha256", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Algorithm")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Algorithm", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Signature")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Signature", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-SignedHeaders", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Credential")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Credential", valid_594196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594197: Call_GetCreateDBCluster_594167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Amazon DocumentDB DB cluster.
  ## 
  let valid = call_594197.validator(path, query, header, formData, body)
  let scheme = call_594197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594197.url(scheme.get, call_594197.host, call_594197.base,
                         call_594197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594197, url, valid)

proc call*(call_594198: Call_GetCreateDBCluster_594167; Engine: string;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
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
  ##                 : <p>The name of the master user for the DB cluster.</p> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 16 letters or numbers.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot be a reserved word for the chosen database engine.</p> </li> </ul>
  var query_594199 = newJObject()
  add(query_594199, "Engine", newJString(Engine))
  add(query_594199, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594199, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_594199, "StorageEncrypted", newJBool(StorageEncrypted))
  if AvailabilityZones != nil:
    query_594199.add "AvailabilityZones", AvailabilityZones
  add(query_594199, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594199, "MasterUserPassword", newJString(MasterUserPassword))
  if VpcSecurityGroupIds != nil:
    query_594199.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_594199.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_594199.add "Tags", Tags
  add(query_594199, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_594199, "DeletionProtection", newJBool(DeletionProtection))
  add(query_594199, "Action", newJString(Action))
  add(query_594199, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594199, "KmsKeyId", newJString(KmsKeyId))
  add(query_594199, "EngineVersion", newJString(EngineVersion))
  add(query_594199, "Port", newJInt(Port))
  add(query_594199, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_594199, "Version", newJString(Version))
  add(query_594199, "MasterUsername", newJString(MasterUsername))
  result = call_594198.call(nil, query_594199, nil, nil, nil)

var getCreateDBCluster* = Call_GetCreateDBCluster_594167(
    name: "getCreateDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CreateDBCluster", validator: validate_GetCreateDBCluster_594168,
    base: "/", url: url_GetCreateDBCluster_594169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterParameterGroup_594253 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBClusterParameterGroup_594255(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBClusterParameterGroup_594254(path: JsonNode;
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
  var valid_594256 = query.getOrDefault("Action")
  valid_594256 = validateParameter(valid_594256, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_594256 != nil:
    section.add "Action", valid_594256
  var valid_594257 = query.getOrDefault("Version")
  valid_594257 = validateParameter(valid_594257, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594257 != nil:
    section.add "Version", valid_594257
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594258 = header.getOrDefault("X-Amz-Date")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Date", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Security-Token")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Security-Token", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Content-Sha256", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Algorithm")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Algorithm", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-Signature")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Signature", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-SignedHeaders", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Credential")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Credential", valid_594264
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
  var valid_594265 = formData.getOrDefault("Tags")
  valid_594265 = validateParameter(valid_594265, JArray, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "Tags", valid_594265
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_594266 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_594266 = validateParameter(valid_594266, JString, required = true,
                                 default = nil)
  if valid_594266 != nil:
    section.add "DBClusterParameterGroupName", valid_594266
  var valid_594267 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594267 = validateParameter(valid_594267, JString, required = true,
                                 default = nil)
  if valid_594267 != nil:
    section.add "DBParameterGroupFamily", valid_594267
  var valid_594268 = formData.getOrDefault("Description")
  valid_594268 = validateParameter(valid_594268, JString, required = true,
                                 default = nil)
  if valid_594268 != nil:
    section.add "Description", valid_594268
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594269: Call_PostCreateDBClusterParameterGroup_594253;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_594269.validator(path, query, header, formData, body)
  let scheme = call_594269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594269.url(scheme.get, call_594269.host, call_594269.base,
                         call_594269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594269, url, valid)

proc call*(call_594270: Call_PostCreateDBClusterParameterGroup_594253;
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
  var query_594271 = newJObject()
  var formData_594272 = newJObject()
  if Tags != nil:
    formData_594272.add "Tags", Tags
  add(query_594271, "Action", newJString(Action))
  add(formData_594272, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_594272, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_594271, "Version", newJString(Version))
  add(formData_594272, "Description", newJString(Description))
  result = call_594270.call(nil, query_594271, nil, formData_594272, nil)

var postCreateDBClusterParameterGroup* = Call_PostCreateDBClusterParameterGroup_594253(
    name: "postCreateDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_PostCreateDBClusterParameterGroup_594254, base: "/",
    url: url_PostCreateDBClusterParameterGroup_594255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterParameterGroup_594234 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBClusterParameterGroup_594236(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBClusterParameterGroup_594235(path: JsonNode;
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
  var valid_594237 = query.getOrDefault("DBClusterParameterGroupName")
  valid_594237 = validateParameter(valid_594237, JString, required = true,
                                 default = nil)
  if valid_594237 != nil:
    section.add "DBClusterParameterGroupName", valid_594237
  var valid_594238 = query.getOrDefault("Description")
  valid_594238 = validateParameter(valid_594238, JString, required = true,
                                 default = nil)
  if valid_594238 != nil:
    section.add "Description", valid_594238
  var valid_594239 = query.getOrDefault("DBParameterGroupFamily")
  valid_594239 = validateParameter(valid_594239, JString, required = true,
                                 default = nil)
  if valid_594239 != nil:
    section.add "DBParameterGroupFamily", valid_594239
  var valid_594240 = query.getOrDefault("Tags")
  valid_594240 = validateParameter(valid_594240, JArray, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "Tags", valid_594240
  var valid_594241 = query.getOrDefault("Action")
  valid_594241 = validateParameter(valid_594241, JString, required = true, default = newJString(
      "CreateDBClusterParameterGroup"))
  if valid_594241 != nil:
    section.add "Action", valid_594241
  var valid_594242 = query.getOrDefault("Version")
  valid_594242 = validateParameter(valid_594242, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594242 != nil:
    section.add "Version", valid_594242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594243 = header.getOrDefault("X-Amz-Date")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Date", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Security-Token")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Security-Token", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Content-Sha256", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Algorithm")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Algorithm", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Signature")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Signature", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-SignedHeaders", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Credential")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Credential", valid_594249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_GetCreateDBClusterParameterGroup_594234;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster parameter group.</p> <p>Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster.</p> <p>A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after you create it. After you create a DB cluster parameter group, you must associate it with your DB cluster. For the new DB cluster parameter group and associated settings to take effect, you must then reboot the DB instances in the DB cluster without failover.</p> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_GetCreateDBClusterParameterGroup_594234;
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
  var query_594252 = newJObject()
  add(query_594252, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_594252, "Description", newJString(Description))
  add(query_594252, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_594252.add "Tags", Tags
  add(query_594252, "Action", newJString(Action))
  add(query_594252, "Version", newJString(Version))
  result = call_594251.call(nil, query_594252, nil, nil, nil)

var getCreateDBClusterParameterGroup* = Call_GetCreateDBClusterParameterGroup_594234(
    name: "getCreateDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterParameterGroup",
    validator: validate_GetCreateDBClusterParameterGroup_594235, base: "/",
    url: url_GetCreateDBClusterParameterGroup_594236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBClusterSnapshot_594291 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBClusterSnapshot_594293(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBClusterSnapshot_594292(path: JsonNode; query: JsonNode;
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
  var valid_594294 = query.getOrDefault("Action")
  valid_594294 = validateParameter(valid_594294, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_594294 != nil:
    section.add "Action", valid_594294
  var valid_594295 = query.getOrDefault("Version")
  valid_594295 = validateParameter(valid_594295, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594295 != nil:
    section.add "Version", valid_594295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594296 = header.getOrDefault("X-Amz-Date")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Date", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Security-Token")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Security-Token", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Content-Sha256", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Algorithm")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Algorithm", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Signature")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Signature", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-SignedHeaders", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Credential")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Credential", valid_594302
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
  var valid_594303 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594303 = validateParameter(valid_594303, JString, required = true,
                                 default = nil)
  if valid_594303 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594303
  var valid_594304 = formData.getOrDefault("Tags")
  valid_594304 = validateParameter(valid_594304, JArray, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "Tags", valid_594304
  var valid_594305 = formData.getOrDefault("DBClusterIdentifier")
  valid_594305 = validateParameter(valid_594305, JString, required = true,
                                 default = nil)
  if valid_594305 != nil:
    section.add "DBClusterIdentifier", valid_594305
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594306: Call_PostCreateDBClusterSnapshot_594291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_594306.validator(path, query, header, formData, body)
  let scheme = call_594306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594306.url(scheme.get, call_594306.host, call_594306.base,
                         call_594306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594306, url, valid)

proc call*(call_594307: Call_PostCreateDBClusterSnapshot_594291;
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
  var query_594308 = newJObject()
  var formData_594309 = newJObject()
  add(formData_594309, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    formData_594309.add "Tags", Tags
  add(query_594308, "Action", newJString(Action))
  add(formData_594309, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594308, "Version", newJString(Version))
  result = call_594307.call(nil, query_594308, nil, formData_594309, nil)

var postCreateDBClusterSnapshot* = Call_PostCreateDBClusterSnapshot_594291(
    name: "postCreateDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_PostCreateDBClusterSnapshot_594292, base: "/",
    url: url_PostCreateDBClusterSnapshot_594293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBClusterSnapshot_594273 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBClusterSnapshot_594275(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBClusterSnapshot_594274(path: JsonNode; query: JsonNode;
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
  var valid_594276 = query.getOrDefault("DBClusterIdentifier")
  valid_594276 = validateParameter(valid_594276, JString, required = true,
                                 default = nil)
  if valid_594276 != nil:
    section.add "DBClusterIdentifier", valid_594276
  var valid_594277 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594277 = validateParameter(valid_594277, JString, required = true,
                                 default = nil)
  if valid_594277 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594277
  var valid_594278 = query.getOrDefault("Tags")
  valid_594278 = validateParameter(valid_594278, JArray, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "Tags", valid_594278
  var valid_594279 = query.getOrDefault("Action")
  valid_594279 = validateParameter(valid_594279, JString, required = true, default = newJString(
      "CreateDBClusterSnapshot"))
  if valid_594279 != nil:
    section.add "Action", valid_594279
  var valid_594280 = query.getOrDefault("Version")
  valid_594280 = validateParameter(valid_594280, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594280 != nil:
    section.add "Version", valid_594280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594281 = header.getOrDefault("X-Amz-Date")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Date", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Security-Token")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Security-Token", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Content-Sha256", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Algorithm")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Algorithm", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Signature")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Signature", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-SignedHeaders", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Credential")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Credential", valid_594287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594288: Call_GetCreateDBClusterSnapshot_594273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a snapshot of a DB cluster. 
  ## 
  let valid = call_594288.validator(path, query, header, formData, body)
  let scheme = call_594288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594288.url(scheme.get, call_594288.host, call_594288.base,
                         call_594288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594288, url, valid)

proc call*(call_594289: Call_GetCreateDBClusterSnapshot_594273;
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
  var query_594290 = newJObject()
  add(query_594290, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594290, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Tags != nil:
    query_594290.add "Tags", Tags
  add(query_594290, "Action", newJString(Action))
  add(query_594290, "Version", newJString(Version))
  result = call_594289.call(nil, query_594290, nil, nil, nil)

var getCreateDBClusterSnapshot* = Call_GetCreateDBClusterSnapshot_594273(
    name: "getCreateDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBClusterSnapshot",
    validator: validate_GetCreateDBClusterSnapshot_594274, base: "/",
    url: url_GetCreateDBClusterSnapshot_594275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_594334 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBInstance_594336(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_594335(path: JsonNode; query: JsonNode;
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
  var valid_594337 = query.getOrDefault("Action")
  valid_594337 = validateParameter(valid_594337, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_594337 != nil:
    section.add "Action", valid_594337
  var valid_594338 = query.getOrDefault("Version")
  valid_594338 = validateParameter(valid_594338, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594338 != nil:
    section.add "Version", valid_594338
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594339 = header.getOrDefault("X-Amz-Date")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Date", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Security-Token")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Security-Token", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Content-Sha256", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Algorithm")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Algorithm", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Signature")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Signature", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-SignedHeaders", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Credential")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Credential", valid_594345
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##         : <p>The name of the database engine to be used for this instance.</p> <p>Valid value: <code>docdb</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  ##   Tags: JArray
  ##       : The tags to be assigned to the DB instance.
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
  var valid_594346 = formData.getOrDefault("Engine")
  valid_594346 = validateParameter(valid_594346, JString, required = true,
                                 default = nil)
  if valid_594346 != nil:
    section.add "Engine", valid_594346
  var valid_594347 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594347 = validateParameter(valid_594347, JString, required = true,
                                 default = nil)
  if valid_594347 != nil:
    section.add "DBInstanceIdentifier", valid_594347
  var valid_594348 = formData.getOrDefault("Tags")
  valid_594348 = validateParameter(valid_594348, JArray, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "Tags", valid_594348
  var valid_594349 = formData.getOrDefault("AvailabilityZone")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "AvailabilityZone", valid_594349
  var valid_594350 = formData.getOrDefault("PromotionTier")
  valid_594350 = validateParameter(valid_594350, JInt, required = false, default = nil)
  if valid_594350 != nil:
    section.add "PromotionTier", valid_594350
  var valid_594351 = formData.getOrDefault("DBInstanceClass")
  valid_594351 = validateParameter(valid_594351, JString, required = true,
                                 default = nil)
  if valid_594351 != nil:
    section.add "DBInstanceClass", valid_594351
  var valid_594352 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_594352 = validateParameter(valid_594352, JBool, required = false, default = nil)
  if valid_594352 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594352
  var valid_594353 = formData.getOrDefault("DBClusterIdentifier")
  valid_594353 = validateParameter(valid_594353, JString, required = true,
                                 default = nil)
  if valid_594353 != nil:
    section.add "DBClusterIdentifier", valid_594353
  var valid_594354 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "PreferredMaintenanceWindow", valid_594354
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_PostCreateDBInstance_594334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_PostCreateDBInstance_594334; Engine: string;
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
  ##       : The tags to be assigned to the DB instance.
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
  var query_594357 = newJObject()
  var formData_594358 = newJObject()
  add(formData_594358, "Engine", newJString(Engine))
  add(formData_594358, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_594358.add "Tags", Tags
  add(formData_594358, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_594357, "Action", newJString(Action))
  add(formData_594358, "PromotionTier", newJInt(PromotionTier))
  add(formData_594358, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_594358, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_594358, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594357, "Version", newJString(Version))
  add(formData_594358, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_594356.call(nil, query_594357, nil, formData_594358, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_594334(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_594335, base: "/",
    url: url_PostCreateDBInstance_594336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_594310 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBInstance_594312(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_594311(path: JsonNode; query: JsonNode;
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
  ##       : The tags to be assigned to the DB instance.
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
  var valid_594313 = query.getOrDefault("Engine")
  valid_594313 = validateParameter(valid_594313, JString, required = true,
                                 default = nil)
  if valid_594313 != nil:
    section.add "Engine", valid_594313
  var valid_594314 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "PreferredMaintenanceWindow", valid_594314
  var valid_594315 = query.getOrDefault("PromotionTier")
  valid_594315 = validateParameter(valid_594315, JInt, required = false, default = nil)
  if valid_594315 != nil:
    section.add "PromotionTier", valid_594315
  var valid_594316 = query.getOrDefault("DBClusterIdentifier")
  valid_594316 = validateParameter(valid_594316, JString, required = true,
                                 default = nil)
  if valid_594316 != nil:
    section.add "DBClusterIdentifier", valid_594316
  var valid_594317 = query.getOrDefault("AvailabilityZone")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "AvailabilityZone", valid_594317
  var valid_594318 = query.getOrDefault("Tags")
  valid_594318 = validateParameter(valid_594318, JArray, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "Tags", valid_594318
  var valid_594319 = query.getOrDefault("DBInstanceClass")
  valid_594319 = validateParameter(valid_594319, JString, required = true,
                                 default = nil)
  if valid_594319 != nil:
    section.add "DBInstanceClass", valid_594319
  var valid_594320 = query.getOrDefault("Action")
  valid_594320 = validateParameter(valid_594320, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_594320 != nil:
    section.add "Action", valid_594320
  var valid_594321 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_594321 = validateParameter(valid_594321, JBool, required = false, default = nil)
  if valid_594321 != nil:
    section.add "AutoMinorVersionUpgrade", valid_594321
  var valid_594322 = query.getOrDefault("Version")
  valid_594322 = validateParameter(valid_594322, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594322 != nil:
    section.add "Version", valid_594322
  var valid_594323 = query.getOrDefault("DBInstanceIdentifier")
  valid_594323 = validateParameter(valid_594323, JString, required = true,
                                 default = nil)
  if valid_594323 != nil:
    section.add "DBInstanceIdentifier", valid_594323
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594324 = header.getOrDefault("X-Amz-Date")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Date", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Security-Token")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Security-Token", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Content-Sha256", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Algorithm")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Algorithm", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Signature")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Signature", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-SignedHeaders", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Credential")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Credential", valid_594330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594331: Call_GetCreateDBInstance_594310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB instance.
  ## 
  let valid = call_594331.validator(path, query, header, formData, body)
  let scheme = call_594331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594331.url(scheme.get, call_594331.host, call_594331.base,
                         call_594331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594331, url, valid)

proc call*(call_594332: Call_GetCreateDBInstance_594310; Engine: string;
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
  ##       : The tags to be assigned to the DB instance.
  ##   DBInstanceClass: string (required)
  ##                  : The compute and memory capacity of the DB instance; for example, <code>db.r5.large</code>. 
  ##   Action: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##                          : <p>Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window.</p> <p>Default: <code>true</code> </p>
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must contain from 1 to 63 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul> <p>Example: <code>mydbinstance</code> </p>
  var query_594333 = newJObject()
  add(query_594333, "Engine", newJString(Engine))
  add(query_594333, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_594333, "PromotionTier", newJInt(PromotionTier))
  add(query_594333, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594333, "AvailabilityZone", newJString(AvailabilityZone))
  if Tags != nil:
    query_594333.add "Tags", Tags
  add(query_594333, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_594333, "Action", newJString(Action))
  add(query_594333, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_594333, "Version", newJString(Version))
  add(query_594333, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594332.call(nil, query_594333, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_594310(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_594311, base: "/",
    url: url_GetCreateDBInstance_594312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_594378 = ref object of OpenApiRestCall_593421
proc url_PostCreateDBSubnetGroup_594380(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_594379(path: JsonNode; query: JsonNode;
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
  var valid_594381 = query.getOrDefault("Action")
  valid_594381 = validateParameter(valid_594381, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_594381 != nil:
    section.add "Action", valid_594381
  var valid_594382 = query.getOrDefault("Version")
  valid_594382 = validateParameter(valid_594382, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594382 != nil:
    section.add "Version", valid_594382
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594383 = header.getOrDefault("X-Amz-Date")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Date", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Security-Token")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Security-Token", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Content-Sha256", valid_594385
  var valid_594386 = header.getOrDefault("X-Amz-Algorithm")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-Algorithm", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-Signature")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-Signature", valid_594387
  var valid_594388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "X-Amz-SignedHeaders", valid_594388
  var valid_594389 = header.getOrDefault("X-Amz-Credential")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Credential", valid_594389
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
  var valid_594390 = formData.getOrDefault("Tags")
  valid_594390 = validateParameter(valid_594390, JArray, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "Tags", valid_594390
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594391 = formData.getOrDefault("DBSubnetGroupName")
  valid_594391 = validateParameter(valid_594391, JString, required = true,
                                 default = nil)
  if valid_594391 != nil:
    section.add "DBSubnetGroupName", valid_594391
  var valid_594392 = formData.getOrDefault("SubnetIds")
  valid_594392 = validateParameter(valid_594392, JArray, required = true, default = nil)
  if valid_594392 != nil:
    section.add "SubnetIds", valid_594392
  var valid_594393 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_594393 = validateParameter(valid_594393, JString, required = true,
                                 default = nil)
  if valid_594393 != nil:
    section.add "DBSubnetGroupDescription", valid_594393
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594394: Call_PostCreateDBSubnetGroup_594378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_594394.validator(path, query, header, formData, body)
  let scheme = call_594394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594394.url(scheme.get, call_594394.host, call_594394.base,
                         call_594394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594394, url, valid)

proc call*(call_594395: Call_PostCreateDBSubnetGroup_594378;
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
  var query_594396 = newJObject()
  var formData_594397 = newJObject()
  if Tags != nil:
    formData_594397.add "Tags", Tags
  add(formData_594397, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_594397.add "SubnetIds", SubnetIds
  add(query_594396, "Action", newJString(Action))
  add(formData_594397, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594396, "Version", newJString(Version))
  result = call_594395.call(nil, query_594396, nil, formData_594397, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_594378(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_594379, base: "/",
    url: url_PostCreateDBSubnetGroup_594380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_594359 = ref object of OpenApiRestCall_593421
proc url_GetCreateDBSubnetGroup_594361(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_594360(path: JsonNode; query: JsonNode;
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
  var valid_594362 = query.getOrDefault("Tags")
  valid_594362 = validateParameter(valid_594362, JArray, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "Tags", valid_594362
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594363 = query.getOrDefault("Action")
  valid_594363 = validateParameter(valid_594363, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_594363 != nil:
    section.add "Action", valid_594363
  var valid_594364 = query.getOrDefault("DBSubnetGroupName")
  valid_594364 = validateParameter(valid_594364, JString, required = true,
                                 default = nil)
  if valid_594364 != nil:
    section.add "DBSubnetGroupName", valid_594364
  var valid_594365 = query.getOrDefault("SubnetIds")
  valid_594365 = validateParameter(valid_594365, JArray, required = true, default = nil)
  if valid_594365 != nil:
    section.add "SubnetIds", valid_594365
  var valid_594366 = query.getOrDefault("DBSubnetGroupDescription")
  valid_594366 = validateParameter(valid_594366, JString, required = true,
                                 default = nil)
  if valid_594366 != nil:
    section.add "DBSubnetGroupDescription", valid_594366
  var valid_594367 = query.getOrDefault("Version")
  valid_594367 = validateParameter(valid_594367, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594367 != nil:
    section.add "Version", valid_594367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594368 = header.getOrDefault("X-Amz-Date")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Date", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Security-Token")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Security-Token", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Content-Sha256", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-Algorithm")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-Algorithm", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Signature")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Signature", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-SignedHeaders", valid_594373
  var valid_594374 = header.getOrDefault("X-Amz-Credential")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Credential", valid_594374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594375: Call_GetCreateDBSubnetGroup_594359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_594375.validator(path, query, header, formData, body)
  let scheme = call_594375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594375.url(scheme.get, call_594375.host, call_594375.base,
                         call_594375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594375, url, valid)

proc call*(call_594376: Call_GetCreateDBSubnetGroup_594359;
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
  var query_594377 = newJObject()
  if Tags != nil:
    query_594377.add "Tags", Tags
  add(query_594377, "Action", newJString(Action))
  add(query_594377, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_594377.add "SubnetIds", SubnetIds
  add(query_594377, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_594377, "Version", newJString(Version))
  result = call_594376.call(nil, query_594377, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_594359(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_594360, base: "/",
    url: url_GetCreateDBSubnetGroup_594361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBCluster_594416 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBCluster_594418(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBCluster_594417(path: JsonNode; query: JsonNode;
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
  var valid_594419 = query.getOrDefault("Action")
  valid_594419 = validateParameter(valid_594419, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_594419 != nil:
    section.add "Action", valid_594419
  var valid_594420 = query.getOrDefault("Version")
  valid_594420 = validateParameter(valid_594420, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594420 != nil:
    section.add "Version", valid_594420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594421 = header.getOrDefault("X-Amz-Date")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Date", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Security-Token")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Security-Token", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Content-Sha256", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Algorithm")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Algorithm", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Signature")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Signature", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-SignedHeaders", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Credential")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Credential", valid_594427
  result.add "header", section
  ## parameters in `formData` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##                            : <p> The DB cluster snapshot identifier of the new DB cluster snapshot created when <code>SkipFinalSnapshot</code> is set to <code>false</code>. </p> <note> <p> Specifying this parameter and also setting the <code>SkipFinalShapshot</code> parameter to <code>true</code> results in an error. </p> </note> <p>Constraints:</p> <ul> <li> <p>Must be from 1 to 255 letters, numbers, or hyphens.</p> </li> <li> <p>The first character must be a letter.</p> </li> <li> <p>Cannot end with a hyphen or contain two consecutive hyphens.</p> </li> </ul>
  ##   DBClusterIdentifier: JString (required)
  ##                      : <p>The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match an existing <code>DBClusterIdentifier</code>.</p> </li> </ul>
  ##   SkipFinalSnapshot: JBool
  ##                    : <p> Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If <code>true</code> is specified, no DB cluster snapshot is created. If <code>false</code> is specified, a DB cluster snapshot is created before the DB cluster is deleted. </p> <note> <p>If <code>SkipFinalSnapshot</code> is <code>false</code>, you must specify a <code>FinalDBSnapshotIdentifier</code> parameter.</p> </note> <p>Default: <code>false</code> </p>
  section = newJObject()
  var valid_594428 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_594428
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_594429 = formData.getOrDefault("DBClusterIdentifier")
  valid_594429 = validateParameter(valid_594429, JString, required = true,
                                 default = nil)
  if valid_594429 != nil:
    section.add "DBClusterIdentifier", valid_594429
  var valid_594430 = formData.getOrDefault("SkipFinalSnapshot")
  valid_594430 = validateParameter(valid_594430, JBool, required = false, default = nil)
  if valid_594430 != nil:
    section.add "SkipFinalSnapshot", valid_594430
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594431: Call_PostDeleteDBCluster_594416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_594431.validator(path, query, header, formData, body)
  let scheme = call_594431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594431.url(scheme.get, call_594431.host, call_594431.base,
                         call_594431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594431, url, valid)

proc call*(call_594432: Call_PostDeleteDBCluster_594416;
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
  var query_594433 = newJObject()
  var formData_594434 = newJObject()
  add(formData_594434, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_594433, "Action", newJString(Action))
  add(formData_594434, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594433, "Version", newJString(Version))
  add(formData_594434, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_594432.call(nil, query_594433, nil, formData_594434, nil)

var postDeleteDBCluster* = Call_PostDeleteDBCluster_594416(
    name: "postDeleteDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBCluster",
    validator: validate_PostDeleteDBCluster_594417, base: "/",
    url: url_PostDeleteDBCluster_594418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBCluster_594398 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBCluster_594400(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBCluster_594399(path: JsonNode; query: JsonNode;
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
  var valid_594401 = query.getOrDefault("DBClusterIdentifier")
  valid_594401 = validateParameter(valid_594401, JString, required = true,
                                 default = nil)
  if valid_594401 != nil:
    section.add "DBClusterIdentifier", valid_594401
  var valid_594402 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_594402
  var valid_594403 = query.getOrDefault("Action")
  valid_594403 = validateParameter(valid_594403, JString, required = true,
                                 default = newJString("DeleteDBCluster"))
  if valid_594403 != nil:
    section.add "Action", valid_594403
  var valid_594404 = query.getOrDefault("SkipFinalSnapshot")
  valid_594404 = validateParameter(valid_594404, JBool, required = false, default = nil)
  if valid_594404 != nil:
    section.add "SkipFinalSnapshot", valid_594404
  var valid_594405 = query.getOrDefault("Version")
  valid_594405 = validateParameter(valid_594405, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594405 != nil:
    section.add "Version", valid_594405
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594406 = header.getOrDefault("X-Amz-Date")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Date", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Security-Token")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Security-Token", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Content-Sha256", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Algorithm")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Algorithm", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Signature")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Signature", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-SignedHeaders", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Credential")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Credential", valid_594412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594413: Call_GetDeleteDBCluster_594398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted.</p> <p/>
  ## 
  let valid = call_594413.validator(path, query, header, formData, body)
  let scheme = call_594413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594413.url(scheme.get, call_594413.host, call_594413.base,
                         call_594413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594413, url, valid)

proc call*(call_594414: Call_GetDeleteDBCluster_594398;
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
  var query_594415 = newJObject()
  add(query_594415, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594415, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_594415, "Action", newJString(Action))
  add(query_594415, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_594415, "Version", newJString(Version))
  result = call_594414.call(nil, query_594415, nil, nil, nil)

var getDeleteDBCluster* = Call_GetDeleteDBCluster_594398(
    name: "getDeleteDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DeleteDBCluster", validator: validate_GetDeleteDBCluster_594399,
    base: "/", url: url_GetDeleteDBCluster_594400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterParameterGroup_594451 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBClusterParameterGroup_594453(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBClusterParameterGroup_594452(path: JsonNode;
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
  var valid_594454 = query.getOrDefault("Action")
  valid_594454 = validateParameter(valid_594454, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_594454 != nil:
    section.add "Action", valid_594454
  var valid_594455 = query.getOrDefault("Version")
  valid_594455 = validateParameter(valid_594455, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594455 != nil:
    section.add "Version", valid_594455
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594456 = header.getOrDefault("X-Amz-Date")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Date", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Security-Token")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Security-Token", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Content-Sha256", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Algorithm")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Algorithm", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Signature")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Signature", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-SignedHeaders", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Credential")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Credential", valid_594462
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_594463 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_594463 = validateParameter(valid_594463, JString, required = true,
                                 default = nil)
  if valid_594463 != nil:
    section.add "DBClusterParameterGroupName", valid_594463
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594464: Call_PostDeleteDBClusterParameterGroup_594451;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_594464.validator(path, query, header, formData, body)
  let scheme = call_594464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594464.url(scheme.get, call_594464.host, call_594464.base,
                         call_594464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594464, url, valid)

proc call*(call_594465: Call_PostDeleteDBClusterParameterGroup_594451;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   Action: string (required)
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Version: string (required)
  var query_594466 = newJObject()
  var formData_594467 = newJObject()
  add(query_594466, "Action", newJString(Action))
  add(formData_594467, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_594466, "Version", newJString(Version))
  result = call_594465.call(nil, query_594466, nil, formData_594467, nil)

var postDeleteDBClusterParameterGroup* = Call_PostDeleteDBClusterParameterGroup_594451(
    name: "postDeleteDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_PostDeleteDBClusterParameterGroup_594452, base: "/",
    url: url_PostDeleteDBClusterParameterGroup_594453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterParameterGroup_594435 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBClusterParameterGroup_594437(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBClusterParameterGroup_594436(path: JsonNode;
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
  var valid_594438 = query.getOrDefault("DBClusterParameterGroupName")
  valid_594438 = validateParameter(valid_594438, JString, required = true,
                                 default = nil)
  if valid_594438 != nil:
    section.add "DBClusterParameterGroupName", valid_594438
  var valid_594439 = query.getOrDefault("Action")
  valid_594439 = validateParameter(valid_594439, JString, required = true, default = newJString(
      "DeleteDBClusterParameterGroup"))
  if valid_594439 != nil:
    section.add "Action", valid_594439
  var valid_594440 = query.getOrDefault("Version")
  valid_594440 = validateParameter(valid_594440, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594440 != nil:
    section.add "Version", valid_594440
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594441 = header.getOrDefault("X-Amz-Date")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Date", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Security-Token")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Security-Token", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Content-Sha256", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Algorithm")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Algorithm", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Signature")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Signature", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-SignedHeaders", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Credential")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Credential", valid_594447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594448: Call_GetDeleteDBClusterParameterGroup_594435;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ## 
  let valid = call_594448.validator(path, query, header, formData, body)
  let scheme = call_594448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594448.url(scheme.get, call_594448.host, call_594448.base,
                         call_594448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594448, url, valid)

proc call*(call_594449: Call_GetDeleteDBClusterParameterGroup_594435;
          DBClusterParameterGroupName: string;
          Action: string = "DeleteDBClusterParameterGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterParameterGroup
  ## Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
  ##   DBClusterParameterGroupName: string (required)
  ##                              : <p>The name of the DB cluster parameter group.</p> <p>Constraints:</p> <ul> <li> <p>Must be the name of an existing DB cluster parameter group.</p> </li> <li> <p>You can't delete a default DB cluster parameter group.</p> </li> <li> <p>Cannot be associated with any DB clusters.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594450 = newJObject()
  add(query_594450, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_594450, "Action", newJString(Action))
  add(query_594450, "Version", newJString(Version))
  result = call_594449.call(nil, query_594450, nil, nil, nil)

var getDeleteDBClusterParameterGroup* = Call_GetDeleteDBClusterParameterGroup_594435(
    name: "getDeleteDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterParameterGroup",
    validator: validate_GetDeleteDBClusterParameterGroup_594436, base: "/",
    url: url_GetDeleteDBClusterParameterGroup_594437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBClusterSnapshot_594484 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBClusterSnapshot_594486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBClusterSnapshot_594485(path: JsonNode; query: JsonNode;
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
  var valid_594487 = query.getOrDefault("Action")
  valid_594487 = validateParameter(valid_594487, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_594487 != nil:
    section.add "Action", valid_594487
  var valid_594488 = query.getOrDefault("Version")
  valid_594488 = validateParameter(valid_594488, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594488 != nil:
    section.add "Version", valid_594488
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594489 = header.getOrDefault("X-Amz-Date")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Date", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Security-Token")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Security-Token", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Content-Sha256", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Algorithm")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Algorithm", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Signature")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Signature", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-SignedHeaders", valid_594494
  var valid_594495 = header.getOrDefault("X-Amz-Credential")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-Credential", valid_594495
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_594496 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594496 = validateParameter(valid_594496, JString, required = true,
                                 default = nil)
  if valid_594496 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594496
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594497: Call_PostDeleteDBClusterSnapshot_594484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_594497.validator(path, query, header, formData, body)
  let scheme = call_594497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594497.url(scheme.get, call_594497.host, call_594497.base,
                         call_594497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594497, url, valid)

proc call*(call_594498: Call_PostDeleteDBClusterSnapshot_594484;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594499 = newJObject()
  var formData_594500 = newJObject()
  add(formData_594500, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_594499, "Action", newJString(Action))
  add(query_594499, "Version", newJString(Version))
  result = call_594498.call(nil, query_594499, nil, formData_594500, nil)

var postDeleteDBClusterSnapshot* = Call_PostDeleteDBClusterSnapshot_594484(
    name: "postDeleteDBClusterSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_PostDeleteDBClusterSnapshot_594485, base: "/",
    url: url_PostDeleteDBClusterSnapshot_594486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBClusterSnapshot_594468 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBClusterSnapshot_594470(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBClusterSnapshot_594469(path: JsonNode; query: JsonNode;
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
  var valid_594471 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594471 = validateParameter(valid_594471, JString, required = true,
                                 default = nil)
  if valid_594471 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594471
  var valid_594472 = query.getOrDefault("Action")
  valid_594472 = validateParameter(valid_594472, JString, required = true, default = newJString(
      "DeleteDBClusterSnapshot"))
  if valid_594472 != nil:
    section.add "Action", valid_594472
  var valid_594473 = query.getOrDefault("Version")
  valid_594473 = validateParameter(valid_594473, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594473 != nil:
    section.add "Version", valid_594473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594474 = header.getOrDefault("X-Amz-Date")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Date", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Security-Token")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Security-Token", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Content-Sha256", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Algorithm")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Algorithm", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Signature")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Signature", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-SignedHeaders", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-Credential")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Credential", valid_594480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594481: Call_GetDeleteDBClusterSnapshot_594468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ## 
  let valid = call_594481.validator(path, query, header, formData, body)
  let scheme = call_594481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594481.url(scheme.get, call_594481.host, call_594481.base,
                         call_594481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594481, url, valid)

proc call*(call_594482: Call_GetDeleteDBClusterSnapshot_594468;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DeleteDBClusterSnapshot"; Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBClusterSnapshot
  ## <p>Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated.</p> <note> <p>The DB cluster snapshot must be in the <code>available</code> state to be deleted.</p> </note>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : <p>The identifier of the DB cluster snapshot to delete.</p> <p>Constraints: Must be the name of an existing DB cluster snapshot in the <code>available</code> state.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594483 = newJObject()
  add(query_594483, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_594483, "Action", newJString(Action))
  add(query_594483, "Version", newJString(Version))
  result = call_594482.call(nil, query_594483, nil, nil, nil)

var getDeleteDBClusterSnapshot* = Call_GetDeleteDBClusterSnapshot_594468(
    name: "getDeleteDBClusterSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBClusterSnapshot",
    validator: validate_GetDeleteDBClusterSnapshot_594469, base: "/",
    url: url_GetDeleteDBClusterSnapshot_594470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_594517 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBInstance_594519(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_594518(path: JsonNode; query: JsonNode;
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
  var valid_594520 = query.getOrDefault("Action")
  valid_594520 = validateParameter(valid_594520, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_594520 != nil:
    section.add "Action", valid_594520
  var valid_594521 = query.getOrDefault("Version")
  valid_594521 = validateParameter(valid_594521, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594521 != nil:
    section.add "Version", valid_594521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594522 = header.getOrDefault("X-Amz-Date")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Date", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Security-Token")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Security-Token", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Content-Sha256", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Algorithm")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Algorithm", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-Signature")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Signature", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-SignedHeaders", valid_594527
  var valid_594528 = header.getOrDefault("X-Amz-Credential")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "X-Amz-Credential", valid_594528
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_594529 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594529 = validateParameter(valid_594529, JString, required = true,
                                 default = nil)
  if valid_594529 != nil:
    section.add "DBInstanceIdentifier", valid_594529
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594530: Call_PostDeleteDBInstance_594517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_594530.validator(path, query, header, formData, body)
  let scheme = call_594530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594530.url(scheme.get, call_594530.host, call_594530.base,
                         call_594530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594530, url, valid)

proc call*(call_594531: Call_PostDeleteDBInstance_594517;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594532 = newJObject()
  var formData_594533 = newJObject()
  add(formData_594533, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_594532, "Action", newJString(Action))
  add(query_594532, "Version", newJString(Version))
  result = call_594531.call(nil, query_594532, nil, formData_594533, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_594517(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_594518, base: "/",
    url: url_PostDeleteDBInstance_594519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_594501 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBInstance_594503(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_594502(path: JsonNode; query: JsonNode;
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
  var valid_594504 = query.getOrDefault("Action")
  valid_594504 = validateParameter(valid_594504, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_594504 != nil:
    section.add "Action", valid_594504
  var valid_594505 = query.getOrDefault("Version")
  valid_594505 = validateParameter(valid_594505, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594505 != nil:
    section.add "Version", valid_594505
  var valid_594506 = query.getOrDefault("DBInstanceIdentifier")
  valid_594506 = validateParameter(valid_594506, JString, required = true,
                                 default = nil)
  if valid_594506 != nil:
    section.add "DBInstanceIdentifier", valid_594506
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594507 = header.getOrDefault("X-Amz-Date")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Date", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Security-Token")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Security-Token", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Content-Sha256", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-Algorithm")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Algorithm", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-Signature")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Signature", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-SignedHeaders", valid_594512
  var valid_594513 = header.getOrDefault("X-Amz-Credential")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "X-Amz-Credential", valid_594513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594514: Call_GetDeleteDBInstance_594501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DB instance. 
  ## 
  let valid = call_594514.validator(path, query, header, formData, body)
  let scheme = call_594514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594514.url(scheme.get, call_594514.host, call_594514.base,
                         call_594514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594514, url, valid)

proc call*(call_594515: Call_GetDeleteDBInstance_594501;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBInstance
  ## Deletes a previously provisioned DB instance. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##                       : <p>The DB instance identifier for the DB instance to be deleted. This parameter isn't case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the name of an existing DB instance.</p> </li> </ul>
  var query_594516 = newJObject()
  add(query_594516, "Action", newJString(Action))
  add(query_594516, "Version", newJString(Version))
  add(query_594516, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594515.call(nil, query_594516, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_594501(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_594502, base: "/",
    url: url_GetDeleteDBInstance_594503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_594550 = ref object of OpenApiRestCall_593421
proc url_PostDeleteDBSubnetGroup_594552(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_594551(path: JsonNode; query: JsonNode;
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
  var valid_594553 = query.getOrDefault("Action")
  valid_594553 = validateParameter(valid_594553, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_594553 != nil:
    section.add "Action", valid_594553
  var valid_594554 = query.getOrDefault("Version")
  valid_594554 = validateParameter(valid_594554, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594554 != nil:
    section.add "Version", valid_594554
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594555 = header.getOrDefault("X-Amz-Date")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Date", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Security-Token")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Security-Token", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Content-Sha256", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-Algorithm")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-Algorithm", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Signature")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Signature", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-SignedHeaders", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Credential")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Credential", valid_594561
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_594562 = formData.getOrDefault("DBSubnetGroupName")
  valid_594562 = validateParameter(valid_594562, JString, required = true,
                                 default = nil)
  if valid_594562 != nil:
    section.add "DBSubnetGroupName", valid_594562
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594563: Call_PostDeleteDBSubnetGroup_594550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_594563.validator(path, query, header, formData, body)
  let scheme = call_594563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594563.url(scheme.get, call_594563.host, call_594563.base,
                         call_594563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594563, url, valid)

proc call*(call_594564: Call_PostDeleteDBSubnetGroup_594550;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## postDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594565 = newJObject()
  var formData_594566 = newJObject()
  add(formData_594566, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594565, "Action", newJString(Action))
  add(query_594565, "Version", newJString(Version))
  result = call_594564.call(nil, query_594565, nil, formData_594566, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_594550(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_594551, base: "/",
    url: url_PostDeleteDBSubnetGroup_594552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_594534 = ref object of OpenApiRestCall_593421
proc url_GetDeleteDBSubnetGroup_594536(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_594535(path: JsonNode; query: JsonNode;
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
  var valid_594537 = query.getOrDefault("Action")
  valid_594537 = validateParameter(valid_594537, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_594537 != nil:
    section.add "Action", valid_594537
  var valid_594538 = query.getOrDefault("DBSubnetGroupName")
  valid_594538 = validateParameter(valid_594538, JString, required = true,
                                 default = nil)
  if valid_594538 != nil:
    section.add "DBSubnetGroupName", valid_594538
  var valid_594539 = query.getOrDefault("Version")
  valid_594539 = validateParameter(valid_594539, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594539 != nil:
    section.add "Version", valid_594539
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594540 = header.getOrDefault("X-Amz-Date")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Date", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-Security-Token")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Security-Token", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Content-Sha256", valid_594542
  var valid_594543 = header.getOrDefault("X-Amz-Algorithm")
  valid_594543 = validateParameter(valid_594543, JString, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "X-Amz-Algorithm", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Signature")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Signature", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-SignedHeaders", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Credential")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Credential", valid_594546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594547: Call_GetDeleteDBSubnetGroup_594534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ## 
  let valid = call_594547.validator(path, query, header, formData, body)
  let scheme = call_594547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594547.url(scheme.get, call_594547.host, call_594547.base,
                         call_594547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594547, url, valid)

proc call*(call_594548: Call_GetDeleteDBSubnetGroup_594534;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-10-31"): Recallable =
  ## getDeleteDBSubnetGroup
  ## <p>Deletes a DB subnet group.</p> <note> <p>The specified database subnet group must not be associated with any DB instances.</p> </note>
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##                    : <p>The name of the database subnet group to delete.</p> <note> <p>You can't delete the default subnet group.</p> </note> <p>Constraints:</p> <p>Must match the name of an existing <code>DBSubnetGroup</code>. Must not be default.</p> <p>Example: <code>mySubnetgroup</code> </p>
  ##   Version: string (required)
  var query_594549 = newJObject()
  add(query_594549, "Action", newJString(Action))
  add(query_594549, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594549, "Version", newJString(Version))
  result = call_594548.call(nil, query_594549, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_594534(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_594535, base: "/",
    url: url_GetDeleteDBSubnetGroup_594536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameterGroups_594586 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBClusterParameterGroups_594588(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterParameterGroups_594587(path: JsonNode;
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
  var valid_594589 = query.getOrDefault("Action")
  valid_594589 = validateParameter(valid_594589, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_594589 != nil:
    section.add "Action", valid_594589
  var valid_594590 = query.getOrDefault("Version")
  valid_594590 = validateParameter(valid_594590, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594590 != nil:
    section.add "Version", valid_594590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594591 = header.getOrDefault("X-Amz-Date")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Date", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-Security-Token")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Security-Token", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Content-Sha256", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Algorithm")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Algorithm", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Signature")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Signature", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-SignedHeaders", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-Credential")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Credential", valid_594597
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
  var valid_594598 = formData.getOrDefault("Marker")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "Marker", valid_594598
  var valid_594599 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "DBClusterParameterGroupName", valid_594599
  var valid_594600 = formData.getOrDefault("Filters")
  valid_594600 = validateParameter(valid_594600, JArray, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "Filters", valid_594600
  var valid_594601 = formData.getOrDefault("MaxRecords")
  valid_594601 = validateParameter(valid_594601, JInt, required = false, default = nil)
  if valid_594601 != nil:
    section.add "MaxRecords", valid_594601
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594602: Call_PostDescribeDBClusterParameterGroups_594586;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_594602.validator(path, query, header, formData, body)
  let scheme = call_594602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594602.url(scheme.get, call_594602.host, call_594602.base,
                         call_594602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594602, url, valid)

proc call*(call_594603: Call_PostDescribeDBClusterParameterGroups_594586;
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
  var query_594604 = newJObject()
  var formData_594605 = newJObject()
  add(formData_594605, "Marker", newJString(Marker))
  add(query_594604, "Action", newJString(Action))
  add(formData_594605, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_594605.add "Filters", Filters
  add(formData_594605, "MaxRecords", newJInt(MaxRecords))
  add(query_594604, "Version", newJString(Version))
  result = call_594603.call(nil, query_594604, nil, formData_594605, nil)

var postDescribeDBClusterParameterGroups* = Call_PostDescribeDBClusterParameterGroups_594586(
    name: "postDescribeDBClusterParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_PostDescribeDBClusterParameterGroups_594587, base: "/",
    url: url_PostDescribeDBClusterParameterGroups_594588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameterGroups_594567 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBClusterParameterGroups_594569(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterParameterGroups_594568(path: JsonNode;
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
  var valid_594570 = query.getOrDefault("MaxRecords")
  valid_594570 = validateParameter(valid_594570, JInt, required = false, default = nil)
  if valid_594570 != nil:
    section.add "MaxRecords", valid_594570
  var valid_594571 = query.getOrDefault("DBClusterParameterGroupName")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "DBClusterParameterGroupName", valid_594571
  var valid_594572 = query.getOrDefault("Filters")
  valid_594572 = validateParameter(valid_594572, JArray, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "Filters", valid_594572
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594573 = query.getOrDefault("Action")
  valid_594573 = validateParameter(valid_594573, JString, required = true, default = newJString(
      "DescribeDBClusterParameterGroups"))
  if valid_594573 != nil:
    section.add "Action", valid_594573
  var valid_594574 = query.getOrDefault("Marker")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "Marker", valid_594574
  var valid_594575 = query.getOrDefault("Version")
  valid_594575 = validateParameter(valid_594575, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594575 != nil:
    section.add "Version", valid_594575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594576 = header.getOrDefault("X-Amz-Date")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Date", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Security-Token")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Security-Token", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Content-Sha256", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Algorithm")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Algorithm", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Signature")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Signature", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-SignedHeaders", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Credential")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Credential", valid_594582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594583: Call_GetDescribeDBClusterParameterGroups_594567;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of <code>DBClusterParameterGroup</code> descriptions. If a <code>DBClusterParameterGroupName</code> parameter is specified, the list contains only the description of the specified DB cluster parameter group. 
  ## 
  let valid = call_594583.validator(path, query, header, formData, body)
  let scheme = call_594583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594583.url(scheme.get, call_594583.host, call_594583.base,
                         call_594583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594583, url, valid)

proc call*(call_594584: Call_GetDescribeDBClusterParameterGroups_594567;
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
  var query_594585 = newJObject()
  add(query_594585, "MaxRecords", newJInt(MaxRecords))
  add(query_594585, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_594585.add "Filters", Filters
  add(query_594585, "Action", newJString(Action))
  add(query_594585, "Marker", newJString(Marker))
  add(query_594585, "Version", newJString(Version))
  result = call_594584.call(nil, query_594585, nil, nil, nil)

var getDescribeDBClusterParameterGroups* = Call_GetDescribeDBClusterParameterGroups_594567(
    name: "getDescribeDBClusterParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameterGroups",
    validator: validate_GetDescribeDBClusterParameterGroups_594568, base: "/",
    url: url_GetDescribeDBClusterParameterGroups_594569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterParameters_594626 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBClusterParameters_594628(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterParameters_594627(path: JsonNode;
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
  var valid_594629 = query.getOrDefault("Action")
  valid_594629 = validateParameter(valid_594629, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_594629 != nil:
    section.add "Action", valid_594629
  var valid_594630 = query.getOrDefault("Version")
  valid_594630 = validateParameter(valid_594630, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594630 != nil:
    section.add "Version", valid_594630
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594631 = header.getOrDefault("X-Amz-Date")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Date", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-Security-Token")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-Security-Token", valid_594632
  var valid_594633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "X-Amz-Content-Sha256", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Algorithm")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Algorithm", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-Signature")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Signature", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-SignedHeaders", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-Credential")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-Credential", valid_594637
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
  var valid_594638 = formData.getOrDefault("Marker")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "Marker", valid_594638
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_594639 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_594639 = validateParameter(valid_594639, JString, required = true,
                                 default = nil)
  if valid_594639 != nil:
    section.add "DBClusterParameterGroupName", valid_594639
  var valid_594640 = formData.getOrDefault("Filters")
  valid_594640 = validateParameter(valid_594640, JArray, required = false,
                                 default = nil)
  if valid_594640 != nil:
    section.add "Filters", valid_594640
  var valid_594641 = formData.getOrDefault("MaxRecords")
  valid_594641 = validateParameter(valid_594641, JInt, required = false, default = nil)
  if valid_594641 != nil:
    section.add "MaxRecords", valid_594641
  var valid_594642 = formData.getOrDefault("Source")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "Source", valid_594642
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594643: Call_PostDescribeDBClusterParameters_594626;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_594643.validator(path, query, header, formData, body)
  let scheme = call_594643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594643.url(scheme.get, call_594643.host, call_594643.base,
                         call_594643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594643, url, valid)

proc call*(call_594644: Call_PostDescribeDBClusterParameters_594626;
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
  var query_594645 = newJObject()
  var formData_594646 = newJObject()
  add(formData_594646, "Marker", newJString(Marker))
  add(query_594645, "Action", newJString(Action))
  add(formData_594646, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    formData_594646.add "Filters", Filters
  add(formData_594646, "MaxRecords", newJInt(MaxRecords))
  add(query_594645, "Version", newJString(Version))
  add(formData_594646, "Source", newJString(Source))
  result = call_594644.call(nil, query_594645, nil, formData_594646, nil)

var postDescribeDBClusterParameters* = Call_PostDescribeDBClusterParameters_594626(
    name: "postDescribeDBClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_PostDescribeDBClusterParameters_594627, base: "/",
    url: url_PostDescribeDBClusterParameters_594628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterParameters_594606 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBClusterParameters_594608(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterParameters_594607(path: JsonNode;
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
  var valid_594609 = query.getOrDefault("MaxRecords")
  valid_594609 = validateParameter(valid_594609, JInt, required = false, default = nil)
  if valid_594609 != nil:
    section.add "MaxRecords", valid_594609
  assert query != nil, "query argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_594610 = query.getOrDefault("DBClusterParameterGroupName")
  valid_594610 = validateParameter(valid_594610, JString, required = true,
                                 default = nil)
  if valid_594610 != nil:
    section.add "DBClusterParameterGroupName", valid_594610
  var valid_594611 = query.getOrDefault("Filters")
  valid_594611 = validateParameter(valid_594611, JArray, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "Filters", valid_594611
  var valid_594612 = query.getOrDefault("Action")
  valid_594612 = validateParameter(valid_594612, JString, required = true, default = newJString(
      "DescribeDBClusterParameters"))
  if valid_594612 != nil:
    section.add "Action", valid_594612
  var valid_594613 = query.getOrDefault("Marker")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "Marker", valid_594613
  var valid_594614 = query.getOrDefault("Source")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "Source", valid_594614
  var valid_594615 = query.getOrDefault("Version")
  valid_594615 = validateParameter(valid_594615, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594615 != nil:
    section.add "Version", valid_594615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594616 = header.getOrDefault("X-Amz-Date")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-Date", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Security-Token")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Security-Token", valid_594617
  var valid_594618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594618 = validateParameter(valid_594618, JString, required = false,
                                 default = nil)
  if valid_594618 != nil:
    section.add "X-Amz-Content-Sha256", valid_594618
  var valid_594619 = header.getOrDefault("X-Amz-Algorithm")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Algorithm", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-Signature")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-Signature", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-SignedHeaders", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-Credential")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-Credential", valid_594622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594623: Call_GetDescribeDBClusterParameters_594606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular DB cluster parameter group.
  ## 
  let valid = call_594623.validator(path, query, header, formData, body)
  let scheme = call_594623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594623.url(scheme.get, call_594623.host, call_594623.base,
                         call_594623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594623, url, valid)

proc call*(call_594624: Call_GetDescribeDBClusterParameters_594606;
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
  var query_594625 = newJObject()
  add(query_594625, "MaxRecords", newJInt(MaxRecords))
  add(query_594625, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Filters != nil:
    query_594625.add "Filters", Filters
  add(query_594625, "Action", newJString(Action))
  add(query_594625, "Marker", newJString(Marker))
  add(query_594625, "Source", newJString(Source))
  add(query_594625, "Version", newJString(Version))
  result = call_594624.call(nil, query_594625, nil, nil, nil)

var getDescribeDBClusterParameters* = Call_GetDescribeDBClusterParameters_594606(
    name: "getDescribeDBClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterParameters",
    validator: validate_GetDescribeDBClusterParameters_594607, base: "/",
    url: url_GetDescribeDBClusterParameters_594608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshotAttributes_594663 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBClusterSnapshotAttributes_594665(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterSnapshotAttributes_594664(path: JsonNode;
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
  var valid_594666 = query.getOrDefault("Action")
  valid_594666 = validateParameter(valid_594666, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_594666 != nil:
    section.add "Action", valid_594666
  var valid_594667 = query.getOrDefault("Version")
  valid_594667 = validateParameter(valid_594667, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594667 != nil:
    section.add "Version", valid_594667
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594668 = header.getOrDefault("X-Amz-Date")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Date", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-Security-Token")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-Security-Token", valid_594669
  var valid_594670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "X-Amz-Content-Sha256", valid_594670
  var valid_594671 = header.getOrDefault("X-Amz-Algorithm")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "X-Amz-Algorithm", valid_594671
  var valid_594672 = header.getOrDefault("X-Amz-Signature")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Signature", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-SignedHeaders", valid_594673
  var valid_594674 = header.getOrDefault("X-Amz-Credential")
  valid_594674 = validateParameter(valid_594674, JString, required = false,
                                 default = nil)
  if valid_594674 != nil:
    section.add "X-Amz-Credential", valid_594674
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterSnapshotIdentifier: JString (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterSnapshotIdentifier` field"
  var valid_594675 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594675 = validateParameter(valid_594675, JString, required = true,
                                 default = nil)
  if valid_594675 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594675
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594676: Call_PostDescribeDBClusterSnapshotAttributes_594663;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_594676.validator(path, query, header, formData, body)
  let scheme = call_594676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594676.url(scheme.get, call_594676.host, call_594676.base,
                         call_594676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594676, url, valid)

proc call*(call_594677: Call_PostDescribeDBClusterSnapshotAttributes_594663;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## postDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594678 = newJObject()
  var formData_594679 = newJObject()
  add(formData_594679, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_594678, "Action", newJString(Action))
  add(query_594678, "Version", newJString(Version))
  result = call_594677.call(nil, query_594678, nil, formData_594679, nil)

var postDescribeDBClusterSnapshotAttributes* = Call_PostDescribeDBClusterSnapshotAttributes_594663(
    name: "postDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_PostDescribeDBClusterSnapshotAttributes_594664, base: "/",
    url: url_PostDescribeDBClusterSnapshotAttributes_594665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshotAttributes_594647 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBClusterSnapshotAttributes_594649(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterSnapshotAttributes_594648(path: JsonNode;
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
  var valid_594650 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594650 = validateParameter(valid_594650, JString, required = true,
                                 default = nil)
  if valid_594650 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594650
  var valid_594651 = query.getOrDefault("Action")
  valid_594651 = validateParameter(valid_594651, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshotAttributes"))
  if valid_594651 != nil:
    section.add "Action", valid_594651
  var valid_594652 = query.getOrDefault("Version")
  valid_594652 = validateParameter(valid_594652, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594652 != nil:
    section.add "Version", valid_594652
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594653 = header.getOrDefault("X-Amz-Date")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Date", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-Security-Token")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-Security-Token", valid_594654
  var valid_594655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594655 = validateParameter(valid_594655, JString, required = false,
                                 default = nil)
  if valid_594655 != nil:
    section.add "X-Amz-Content-Sha256", valid_594655
  var valid_594656 = header.getOrDefault("X-Amz-Algorithm")
  valid_594656 = validateParameter(valid_594656, JString, required = false,
                                 default = nil)
  if valid_594656 != nil:
    section.add "X-Amz-Algorithm", valid_594656
  var valid_594657 = header.getOrDefault("X-Amz-Signature")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Signature", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-SignedHeaders", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-Credential")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-Credential", valid_594659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594660: Call_GetDescribeDBClusterSnapshotAttributes_594647;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ## 
  let valid = call_594660.validator(path, query, header, formData, body)
  let scheme = call_594660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594660.url(scheme.get, call_594660.host, call_594660.base,
                         call_594660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594660, url, valid)

proc call*(call_594661: Call_GetDescribeDBClusterSnapshotAttributes_594647;
          DBClusterSnapshotIdentifier: string;
          Action: string = "DescribeDBClusterSnapshotAttributes";
          Version: string = "2014-10-31"): Recallable =
  ## getDescribeDBClusterSnapshotAttributes
  ## <p>Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot.</p> <p>When you share snapshots with other AWS accounts, <code>DescribeDBClusterSnapshotAttributes</code> returns the <code>restore</code> attribute and a list of IDs for the AWS accounts that are authorized to copy or restore the manual DB cluster snapshot. If <code>all</code> is included in the list of values for the <code>restore</code> attribute, then the manual DB cluster snapshot is public and can be copied or restored by all AWS accounts.</p>
  ##   DBClusterSnapshotIdentifier: string (required)
  ##                              : The identifier for the DB cluster snapshot to describe the attributes for.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594662 = newJObject()
  add(query_594662, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_594662, "Action", newJString(Action))
  add(query_594662, "Version", newJString(Version))
  result = call_594661.call(nil, query_594662, nil, nil, nil)

var getDescribeDBClusterSnapshotAttributes* = Call_GetDescribeDBClusterSnapshotAttributes_594647(
    name: "getDescribeDBClusterSnapshotAttributes", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeDBClusterSnapshotAttributes",
    validator: validate_GetDescribeDBClusterSnapshotAttributes_594648, base: "/",
    url: url_GetDescribeDBClusterSnapshotAttributes_594649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusterSnapshots_594703 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBClusterSnapshots_594705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusterSnapshots_594704(path: JsonNode;
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
  var valid_594706 = query.getOrDefault("Action")
  valid_594706 = validateParameter(valid_594706, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_594706 != nil:
    section.add "Action", valid_594706
  var valid_594707 = query.getOrDefault("Version")
  valid_594707 = validateParameter(valid_594707, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594707 != nil:
    section.add "Version", valid_594707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594708 = header.getOrDefault("X-Amz-Date")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-Date", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Security-Token")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Security-Token", valid_594709
  var valid_594710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Content-Sha256", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Algorithm")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Algorithm", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-Signature")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-Signature", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-SignedHeaders", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Credential")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Credential", valid_594714
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
  var valid_594715 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594715
  var valid_594716 = formData.getOrDefault("IncludeShared")
  valid_594716 = validateParameter(valid_594716, JBool, required = false, default = nil)
  if valid_594716 != nil:
    section.add "IncludeShared", valid_594716
  var valid_594717 = formData.getOrDefault("IncludePublic")
  valid_594717 = validateParameter(valid_594717, JBool, required = false, default = nil)
  if valid_594717 != nil:
    section.add "IncludePublic", valid_594717
  var valid_594718 = formData.getOrDefault("SnapshotType")
  valid_594718 = validateParameter(valid_594718, JString, required = false,
                                 default = nil)
  if valid_594718 != nil:
    section.add "SnapshotType", valid_594718
  var valid_594719 = formData.getOrDefault("Marker")
  valid_594719 = validateParameter(valid_594719, JString, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "Marker", valid_594719
  var valid_594720 = formData.getOrDefault("Filters")
  valid_594720 = validateParameter(valid_594720, JArray, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "Filters", valid_594720
  var valid_594721 = formData.getOrDefault("MaxRecords")
  valid_594721 = validateParameter(valid_594721, JInt, required = false, default = nil)
  if valid_594721 != nil:
    section.add "MaxRecords", valid_594721
  var valid_594722 = formData.getOrDefault("DBClusterIdentifier")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "DBClusterIdentifier", valid_594722
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594723: Call_PostDescribeDBClusterSnapshots_594703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_594723.validator(path, query, header, formData, body)
  let scheme = call_594723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594723.url(scheme.get, call_594723.host, call_594723.base,
                         call_594723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594723, url, valid)

proc call*(call_594724: Call_PostDescribeDBClusterSnapshots_594703;
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
  var query_594725 = newJObject()
  var formData_594726 = newJObject()
  add(formData_594726, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(formData_594726, "IncludeShared", newJBool(IncludeShared))
  add(formData_594726, "IncludePublic", newJBool(IncludePublic))
  add(formData_594726, "SnapshotType", newJString(SnapshotType))
  add(formData_594726, "Marker", newJString(Marker))
  add(query_594725, "Action", newJString(Action))
  if Filters != nil:
    formData_594726.add "Filters", Filters
  add(formData_594726, "MaxRecords", newJInt(MaxRecords))
  add(formData_594726, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594725, "Version", newJString(Version))
  result = call_594724.call(nil, query_594725, nil, formData_594726, nil)

var postDescribeDBClusterSnapshots* = Call_PostDescribeDBClusterSnapshots_594703(
    name: "postDescribeDBClusterSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_PostDescribeDBClusterSnapshots_594704, base: "/",
    url: url_PostDescribeDBClusterSnapshots_594705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusterSnapshots_594680 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBClusterSnapshots_594682(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusterSnapshots_594681(path: JsonNode; query: JsonNode;
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
  var valid_594683 = query.getOrDefault("IncludePublic")
  valid_594683 = validateParameter(valid_594683, JBool, required = false, default = nil)
  if valid_594683 != nil:
    section.add "IncludePublic", valid_594683
  var valid_594684 = query.getOrDefault("MaxRecords")
  valid_594684 = validateParameter(valid_594684, JInt, required = false, default = nil)
  if valid_594684 != nil:
    section.add "MaxRecords", valid_594684
  var valid_594685 = query.getOrDefault("DBClusterIdentifier")
  valid_594685 = validateParameter(valid_594685, JString, required = false,
                                 default = nil)
  if valid_594685 != nil:
    section.add "DBClusterIdentifier", valid_594685
  var valid_594686 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_594686 = validateParameter(valid_594686, JString, required = false,
                                 default = nil)
  if valid_594686 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_594686
  var valid_594687 = query.getOrDefault("Filters")
  valid_594687 = validateParameter(valid_594687, JArray, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "Filters", valid_594687
  var valid_594688 = query.getOrDefault("IncludeShared")
  valid_594688 = validateParameter(valid_594688, JBool, required = false, default = nil)
  if valid_594688 != nil:
    section.add "IncludeShared", valid_594688
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594689 = query.getOrDefault("Action")
  valid_594689 = validateParameter(valid_594689, JString, required = true, default = newJString(
      "DescribeDBClusterSnapshots"))
  if valid_594689 != nil:
    section.add "Action", valid_594689
  var valid_594690 = query.getOrDefault("Marker")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "Marker", valid_594690
  var valid_594691 = query.getOrDefault("SnapshotType")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "SnapshotType", valid_594691
  var valid_594692 = query.getOrDefault("Version")
  valid_594692 = validateParameter(valid_594692, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594692 != nil:
    section.add "Version", valid_594692
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594693 = header.getOrDefault("X-Amz-Date")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-Date", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Security-Token")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Security-Token", valid_594694
  var valid_594695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Content-Sha256", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Algorithm")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Algorithm", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-Signature")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-Signature", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-SignedHeaders", valid_594698
  var valid_594699 = header.getOrDefault("X-Amz-Credential")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "X-Amz-Credential", valid_594699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594700: Call_GetDescribeDBClusterSnapshots_594680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about DB cluster snapshots. This API operation supports pagination.
  ## 
  let valid = call_594700.validator(path, query, header, formData, body)
  let scheme = call_594700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594700.url(scheme.get, call_594700.host, call_594700.base,
                         call_594700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594700, url, valid)

proc call*(call_594701: Call_GetDescribeDBClusterSnapshots_594680;
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
  var query_594702 = newJObject()
  add(query_594702, "IncludePublic", newJBool(IncludePublic))
  add(query_594702, "MaxRecords", newJInt(MaxRecords))
  add(query_594702, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594702, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if Filters != nil:
    query_594702.add "Filters", Filters
  add(query_594702, "IncludeShared", newJBool(IncludeShared))
  add(query_594702, "Action", newJString(Action))
  add(query_594702, "Marker", newJString(Marker))
  add(query_594702, "SnapshotType", newJString(SnapshotType))
  add(query_594702, "Version", newJString(Version))
  result = call_594701.call(nil, query_594702, nil, nil, nil)

var getDescribeDBClusterSnapshots* = Call_GetDescribeDBClusterSnapshots_594680(
    name: "getDescribeDBClusterSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusterSnapshots",
    validator: validate_GetDescribeDBClusterSnapshots_594681, base: "/",
    url: url_GetDescribeDBClusterSnapshots_594682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBClusters_594746 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBClusters_594748(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBClusters_594747(path: JsonNode; query: JsonNode;
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
  var valid_594749 = query.getOrDefault("Action")
  valid_594749 = validateParameter(valid_594749, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_594749 != nil:
    section.add "Action", valid_594749
  var valid_594750 = query.getOrDefault("Version")
  valid_594750 = validateParameter(valid_594750, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594750 != nil:
    section.add "Version", valid_594750
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594751 = header.getOrDefault("X-Amz-Date")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "X-Amz-Date", valid_594751
  var valid_594752 = header.getOrDefault("X-Amz-Security-Token")
  valid_594752 = validateParameter(valid_594752, JString, required = false,
                                 default = nil)
  if valid_594752 != nil:
    section.add "X-Amz-Security-Token", valid_594752
  var valid_594753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594753 = validateParameter(valid_594753, JString, required = false,
                                 default = nil)
  if valid_594753 != nil:
    section.add "X-Amz-Content-Sha256", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Algorithm")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Algorithm", valid_594754
  var valid_594755 = header.getOrDefault("X-Amz-Signature")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Signature", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-SignedHeaders", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-Credential")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Credential", valid_594757
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
  var valid_594758 = formData.getOrDefault("Marker")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "Marker", valid_594758
  var valid_594759 = formData.getOrDefault("Filters")
  valid_594759 = validateParameter(valid_594759, JArray, required = false,
                                 default = nil)
  if valid_594759 != nil:
    section.add "Filters", valid_594759
  var valid_594760 = formData.getOrDefault("MaxRecords")
  valid_594760 = validateParameter(valid_594760, JInt, required = false, default = nil)
  if valid_594760 != nil:
    section.add "MaxRecords", valid_594760
  var valid_594761 = formData.getOrDefault("DBClusterIdentifier")
  valid_594761 = validateParameter(valid_594761, JString, required = false,
                                 default = nil)
  if valid_594761 != nil:
    section.add "DBClusterIdentifier", valid_594761
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594762: Call_PostDescribeDBClusters_594746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_594762.validator(path, query, header, formData, body)
  let scheme = call_594762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594762.url(scheme.get, call_594762.host, call_594762.base,
                         call_594762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594762, url, valid)

proc call*(call_594763: Call_PostDescribeDBClusters_594746; Marker: string = "";
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
  var query_594764 = newJObject()
  var formData_594765 = newJObject()
  add(formData_594765, "Marker", newJString(Marker))
  add(query_594764, "Action", newJString(Action))
  if Filters != nil:
    formData_594765.add "Filters", Filters
  add(formData_594765, "MaxRecords", newJInt(MaxRecords))
  add(formData_594765, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_594764, "Version", newJString(Version))
  result = call_594763.call(nil, query_594764, nil, formData_594765, nil)

var postDescribeDBClusters* = Call_PostDescribeDBClusters_594746(
    name: "postDescribeDBClusters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_PostDescribeDBClusters_594747, base: "/",
    url: url_PostDescribeDBClusters_594748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBClusters_594727 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBClusters_594729(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBClusters_594728(path: JsonNode; query: JsonNode;
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
  var valid_594730 = query.getOrDefault("MaxRecords")
  valid_594730 = validateParameter(valid_594730, JInt, required = false, default = nil)
  if valid_594730 != nil:
    section.add "MaxRecords", valid_594730
  var valid_594731 = query.getOrDefault("DBClusterIdentifier")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "DBClusterIdentifier", valid_594731
  var valid_594732 = query.getOrDefault("Filters")
  valid_594732 = validateParameter(valid_594732, JArray, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "Filters", valid_594732
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594733 = query.getOrDefault("Action")
  valid_594733 = validateParameter(valid_594733, JString, required = true,
                                 default = newJString("DescribeDBClusters"))
  if valid_594733 != nil:
    section.add "Action", valid_594733
  var valid_594734 = query.getOrDefault("Marker")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "Marker", valid_594734
  var valid_594735 = query.getOrDefault("Version")
  valid_594735 = validateParameter(valid_594735, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594735 != nil:
    section.add "Version", valid_594735
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594736 = header.getOrDefault("X-Amz-Date")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Date", valid_594736
  var valid_594737 = header.getOrDefault("X-Amz-Security-Token")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Security-Token", valid_594737
  var valid_594738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "X-Amz-Content-Sha256", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Algorithm")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Algorithm", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Signature")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Signature", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-SignedHeaders", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-Credential")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-Credential", valid_594742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594743: Call_GetDescribeDBClusters_594727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB DB clusters. This API operation supports pagination.
  ## 
  let valid = call_594743.validator(path, query, header, formData, body)
  let scheme = call_594743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594743.url(scheme.get, call_594743.host, call_594743.base,
                         call_594743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594743, url, valid)

proc call*(call_594744: Call_GetDescribeDBClusters_594727; MaxRecords: int = 0;
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
  var query_594745 = newJObject()
  add(query_594745, "MaxRecords", newJInt(MaxRecords))
  add(query_594745, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if Filters != nil:
    query_594745.add "Filters", Filters
  add(query_594745, "Action", newJString(Action))
  add(query_594745, "Marker", newJString(Marker))
  add(query_594745, "Version", newJString(Version))
  result = call_594744.call(nil, query_594745, nil, nil, nil)

var getDescribeDBClusters* = Call_GetDescribeDBClusters_594727(
    name: "getDescribeDBClusters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBClusters",
    validator: validate_GetDescribeDBClusters_594728, base: "/",
    url: url_GetDescribeDBClusters_594729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_594790 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBEngineVersions_594792(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_594791(path: JsonNode; query: JsonNode;
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
  var valid_594793 = query.getOrDefault("Action")
  valid_594793 = validateParameter(valid_594793, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_594793 != nil:
    section.add "Action", valid_594793
  var valid_594794 = query.getOrDefault("Version")
  valid_594794 = validateParameter(valid_594794, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594794 != nil:
    section.add "Version", valid_594794
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594795 = header.getOrDefault("X-Amz-Date")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Date", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-Security-Token")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Security-Token", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Content-Sha256", valid_594797
  var valid_594798 = header.getOrDefault("X-Amz-Algorithm")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-Algorithm", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-Signature")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-Signature", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-SignedHeaders", valid_594800
  var valid_594801 = header.getOrDefault("X-Amz-Credential")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-Credential", valid_594801
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
  var valid_594802 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_594802 = validateParameter(valid_594802, JBool, required = false, default = nil)
  if valid_594802 != nil:
    section.add "ListSupportedCharacterSets", valid_594802
  var valid_594803 = formData.getOrDefault("Engine")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "Engine", valid_594803
  var valid_594804 = formData.getOrDefault("Marker")
  valid_594804 = validateParameter(valid_594804, JString, required = false,
                                 default = nil)
  if valid_594804 != nil:
    section.add "Marker", valid_594804
  var valid_594805 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "DBParameterGroupFamily", valid_594805
  var valid_594806 = formData.getOrDefault("Filters")
  valid_594806 = validateParameter(valid_594806, JArray, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "Filters", valid_594806
  var valid_594807 = formData.getOrDefault("MaxRecords")
  valid_594807 = validateParameter(valid_594807, JInt, required = false, default = nil)
  if valid_594807 != nil:
    section.add "MaxRecords", valid_594807
  var valid_594808 = formData.getOrDefault("EngineVersion")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "EngineVersion", valid_594808
  var valid_594809 = formData.getOrDefault("ListSupportedTimezones")
  valid_594809 = validateParameter(valid_594809, JBool, required = false, default = nil)
  if valid_594809 != nil:
    section.add "ListSupportedTimezones", valid_594809
  var valid_594810 = formData.getOrDefault("DefaultOnly")
  valid_594810 = validateParameter(valid_594810, JBool, required = false, default = nil)
  if valid_594810 != nil:
    section.add "DefaultOnly", valid_594810
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594811: Call_PostDescribeDBEngineVersions_594790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_594811.validator(path, query, header, formData, body)
  let scheme = call_594811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594811.url(scheme.get, call_594811.host, call_594811.base,
                         call_594811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594811, url, valid)

proc call*(call_594812: Call_PostDescribeDBEngineVersions_594790;
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
  var query_594813 = newJObject()
  var formData_594814 = newJObject()
  add(formData_594814, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_594814, "Engine", newJString(Engine))
  add(formData_594814, "Marker", newJString(Marker))
  add(query_594813, "Action", newJString(Action))
  add(formData_594814, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_594814.add "Filters", Filters
  add(formData_594814, "MaxRecords", newJInt(MaxRecords))
  add(formData_594814, "EngineVersion", newJString(EngineVersion))
  add(formData_594814, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_594813, "Version", newJString(Version))
  add(formData_594814, "DefaultOnly", newJBool(DefaultOnly))
  result = call_594812.call(nil, query_594813, nil, formData_594814, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_594790(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_594791, base: "/",
    url: url_PostDescribeDBEngineVersions_594792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_594766 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBEngineVersions_594768(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_594767(path: JsonNode; query: JsonNode;
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
  var valid_594769 = query.getOrDefault("Engine")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "Engine", valid_594769
  var valid_594770 = query.getOrDefault("ListSupportedCharacterSets")
  valid_594770 = validateParameter(valid_594770, JBool, required = false, default = nil)
  if valid_594770 != nil:
    section.add "ListSupportedCharacterSets", valid_594770
  var valid_594771 = query.getOrDefault("MaxRecords")
  valid_594771 = validateParameter(valid_594771, JInt, required = false, default = nil)
  if valid_594771 != nil:
    section.add "MaxRecords", valid_594771
  var valid_594772 = query.getOrDefault("DBParameterGroupFamily")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "DBParameterGroupFamily", valid_594772
  var valid_594773 = query.getOrDefault("Filters")
  valid_594773 = validateParameter(valid_594773, JArray, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "Filters", valid_594773
  var valid_594774 = query.getOrDefault("ListSupportedTimezones")
  valid_594774 = validateParameter(valid_594774, JBool, required = false, default = nil)
  if valid_594774 != nil:
    section.add "ListSupportedTimezones", valid_594774
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594775 = query.getOrDefault("Action")
  valid_594775 = validateParameter(valid_594775, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_594775 != nil:
    section.add "Action", valid_594775
  var valid_594776 = query.getOrDefault("Marker")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "Marker", valid_594776
  var valid_594777 = query.getOrDefault("EngineVersion")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "EngineVersion", valid_594777
  var valid_594778 = query.getOrDefault("DefaultOnly")
  valid_594778 = validateParameter(valid_594778, JBool, required = false, default = nil)
  if valid_594778 != nil:
    section.add "DefaultOnly", valid_594778
  var valid_594779 = query.getOrDefault("Version")
  valid_594779 = validateParameter(valid_594779, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594779 != nil:
    section.add "Version", valid_594779
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594780 = header.getOrDefault("X-Amz-Date")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Date", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Security-Token")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Security-Token", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Content-Sha256", valid_594782
  var valid_594783 = header.getOrDefault("X-Amz-Algorithm")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-Algorithm", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Signature")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Signature", valid_594784
  var valid_594785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "X-Amz-SignedHeaders", valid_594785
  var valid_594786 = header.getOrDefault("X-Amz-Credential")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "X-Amz-Credential", valid_594786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594787: Call_GetDescribeDBEngineVersions_594766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available DB engines.
  ## 
  let valid = call_594787.validator(path, query, header, formData, body)
  let scheme = call_594787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594787.url(scheme.get, call_594787.host, call_594787.base,
                         call_594787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594787, url, valid)

proc call*(call_594788: Call_GetDescribeDBEngineVersions_594766;
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
  var query_594789 = newJObject()
  add(query_594789, "Engine", newJString(Engine))
  add(query_594789, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_594789, "MaxRecords", newJInt(MaxRecords))
  add(query_594789, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_594789.add "Filters", Filters
  add(query_594789, "ListSupportedTimezones", newJBool(ListSupportedTimezones))
  add(query_594789, "Action", newJString(Action))
  add(query_594789, "Marker", newJString(Marker))
  add(query_594789, "EngineVersion", newJString(EngineVersion))
  add(query_594789, "DefaultOnly", newJBool(DefaultOnly))
  add(query_594789, "Version", newJString(Version))
  result = call_594788.call(nil, query_594789, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_594766(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_594767, base: "/",
    url: url_GetDescribeDBEngineVersions_594768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_594834 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBInstances_594836(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_594835(path: JsonNode; query: JsonNode;
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
  var valid_594837 = query.getOrDefault("Action")
  valid_594837 = validateParameter(valid_594837, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_594837 != nil:
    section.add "Action", valid_594837
  var valid_594838 = query.getOrDefault("Version")
  valid_594838 = validateParameter(valid_594838, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594838 != nil:
    section.add "Version", valid_594838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594839 = header.getOrDefault("X-Amz-Date")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-Date", valid_594839
  var valid_594840 = header.getOrDefault("X-Amz-Security-Token")
  valid_594840 = validateParameter(valid_594840, JString, required = false,
                                 default = nil)
  if valid_594840 != nil:
    section.add "X-Amz-Security-Token", valid_594840
  var valid_594841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Content-Sha256", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Algorithm")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Algorithm", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Signature")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Signature", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-SignedHeaders", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Credential")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Credential", valid_594845
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
  var valid_594846 = formData.getOrDefault("DBInstanceIdentifier")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "DBInstanceIdentifier", valid_594846
  var valid_594847 = formData.getOrDefault("Marker")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "Marker", valid_594847
  var valid_594848 = formData.getOrDefault("Filters")
  valid_594848 = validateParameter(valid_594848, JArray, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "Filters", valid_594848
  var valid_594849 = formData.getOrDefault("MaxRecords")
  valid_594849 = validateParameter(valid_594849, JInt, required = false, default = nil)
  if valid_594849 != nil:
    section.add "MaxRecords", valid_594849
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594850: Call_PostDescribeDBInstances_594834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_594850.validator(path, query, header, formData, body)
  let scheme = call_594850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594850.url(scheme.get, call_594850.host, call_594850.base,
                         call_594850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594850, url, valid)

proc call*(call_594851: Call_PostDescribeDBInstances_594834;
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
  var query_594852 = newJObject()
  var formData_594853 = newJObject()
  add(formData_594853, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_594853, "Marker", newJString(Marker))
  add(query_594852, "Action", newJString(Action))
  if Filters != nil:
    formData_594853.add "Filters", Filters
  add(formData_594853, "MaxRecords", newJInt(MaxRecords))
  add(query_594852, "Version", newJString(Version))
  result = call_594851.call(nil, query_594852, nil, formData_594853, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_594834(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_594835, base: "/",
    url: url_PostDescribeDBInstances_594836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_594815 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBInstances_594817(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_594816(path: JsonNode; query: JsonNode;
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
  var valid_594818 = query.getOrDefault("MaxRecords")
  valid_594818 = validateParameter(valid_594818, JInt, required = false, default = nil)
  if valid_594818 != nil:
    section.add "MaxRecords", valid_594818
  var valid_594819 = query.getOrDefault("Filters")
  valid_594819 = validateParameter(valid_594819, JArray, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "Filters", valid_594819
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594820 = query.getOrDefault("Action")
  valid_594820 = validateParameter(valid_594820, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_594820 != nil:
    section.add "Action", valid_594820
  var valid_594821 = query.getOrDefault("Marker")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "Marker", valid_594821
  var valid_594822 = query.getOrDefault("Version")
  valid_594822 = validateParameter(valid_594822, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594822 != nil:
    section.add "Version", valid_594822
  var valid_594823 = query.getOrDefault("DBInstanceIdentifier")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "DBInstanceIdentifier", valid_594823
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594824 = header.getOrDefault("X-Amz-Date")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "X-Amz-Date", valid_594824
  var valid_594825 = header.getOrDefault("X-Amz-Security-Token")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-Security-Token", valid_594825
  var valid_594826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Content-Sha256", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Algorithm")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Algorithm", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-Signature")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Signature", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-SignedHeaders", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Credential")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Credential", valid_594830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594831: Call_GetDescribeDBInstances_594815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about provisioned Amazon DocumentDB instances. This API supports pagination.
  ## 
  let valid = call_594831.validator(path, query, header, formData, body)
  let scheme = call_594831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594831.url(scheme.get, call_594831.host, call_594831.base,
                         call_594831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594831, url, valid)

proc call*(call_594832: Call_GetDescribeDBInstances_594815; MaxRecords: int = 0;
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
  var query_594833 = newJObject()
  add(query_594833, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_594833.add "Filters", Filters
  add(query_594833, "Action", newJString(Action))
  add(query_594833, "Marker", newJString(Marker))
  add(query_594833, "Version", newJString(Version))
  add(query_594833, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_594832.call(nil, query_594833, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_594815(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_594816, base: "/",
    url: url_GetDescribeDBInstances_594817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_594873 = ref object of OpenApiRestCall_593421
proc url_PostDescribeDBSubnetGroups_594875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_594874(path: JsonNode; query: JsonNode;
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
  var valid_594876 = query.getOrDefault("Action")
  valid_594876 = validateParameter(valid_594876, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_594876 != nil:
    section.add "Action", valid_594876
  var valid_594877 = query.getOrDefault("Version")
  valid_594877 = validateParameter(valid_594877, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594877 != nil:
    section.add "Version", valid_594877
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594878 = header.getOrDefault("X-Amz-Date")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-Date", valid_594878
  var valid_594879 = header.getOrDefault("X-Amz-Security-Token")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "X-Amz-Security-Token", valid_594879
  var valid_594880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594880 = validateParameter(valid_594880, JString, required = false,
                                 default = nil)
  if valid_594880 != nil:
    section.add "X-Amz-Content-Sha256", valid_594880
  var valid_594881 = header.getOrDefault("X-Amz-Algorithm")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Algorithm", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Signature")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Signature", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-SignedHeaders", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Credential")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Credential", valid_594884
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
  var valid_594885 = formData.getOrDefault("DBSubnetGroupName")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "DBSubnetGroupName", valid_594885
  var valid_594886 = formData.getOrDefault("Marker")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "Marker", valid_594886
  var valid_594887 = formData.getOrDefault("Filters")
  valid_594887 = validateParameter(valid_594887, JArray, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "Filters", valid_594887
  var valid_594888 = formData.getOrDefault("MaxRecords")
  valid_594888 = validateParameter(valid_594888, JInt, required = false, default = nil)
  if valid_594888 != nil:
    section.add "MaxRecords", valid_594888
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594889: Call_PostDescribeDBSubnetGroups_594873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_594889.validator(path, query, header, formData, body)
  let scheme = call_594889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594889.url(scheme.get, call_594889.host, call_594889.base,
                         call_594889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594889, url, valid)

proc call*(call_594890: Call_PostDescribeDBSubnetGroups_594873;
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
  var query_594891 = newJObject()
  var formData_594892 = newJObject()
  add(formData_594892, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_594892, "Marker", newJString(Marker))
  add(query_594891, "Action", newJString(Action))
  if Filters != nil:
    formData_594892.add "Filters", Filters
  add(formData_594892, "MaxRecords", newJInt(MaxRecords))
  add(query_594891, "Version", newJString(Version))
  result = call_594890.call(nil, query_594891, nil, formData_594892, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_594873(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_594874, base: "/",
    url: url_PostDescribeDBSubnetGroups_594875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_594854 = ref object of OpenApiRestCall_593421
proc url_GetDescribeDBSubnetGroups_594856(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_594855(path: JsonNode; query: JsonNode;
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
  var valid_594857 = query.getOrDefault("MaxRecords")
  valid_594857 = validateParameter(valid_594857, JInt, required = false, default = nil)
  if valid_594857 != nil:
    section.add "MaxRecords", valid_594857
  var valid_594858 = query.getOrDefault("Filters")
  valid_594858 = validateParameter(valid_594858, JArray, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "Filters", valid_594858
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594859 = query.getOrDefault("Action")
  valid_594859 = validateParameter(valid_594859, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_594859 != nil:
    section.add "Action", valid_594859
  var valid_594860 = query.getOrDefault("Marker")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "Marker", valid_594860
  var valid_594861 = query.getOrDefault("DBSubnetGroupName")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "DBSubnetGroupName", valid_594861
  var valid_594862 = query.getOrDefault("Version")
  valid_594862 = validateParameter(valid_594862, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594862 != nil:
    section.add "Version", valid_594862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594863 = header.getOrDefault("X-Amz-Date")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "X-Amz-Date", valid_594863
  var valid_594864 = header.getOrDefault("X-Amz-Security-Token")
  valid_594864 = validateParameter(valid_594864, JString, required = false,
                                 default = nil)
  if valid_594864 != nil:
    section.add "X-Amz-Security-Token", valid_594864
  var valid_594865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594865 = validateParameter(valid_594865, JString, required = false,
                                 default = nil)
  if valid_594865 != nil:
    section.add "X-Amz-Content-Sha256", valid_594865
  var valid_594866 = header.getOrDefault("X-Amz-Algorithm")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Algorithm", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Signature")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Signature", valid_594867
  var valid_594868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-SignedHeaders", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Credential")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Credential", valid_594869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594870: Call_GetDescribeDBSubnetGroups_594854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DBSubnetGroup</code> descriptions. If a <code>DBSubnetGroupName</code> is specified, the list will contain only the descriptions of the specified <code>DBSubnetGroup</code>.
  ## 
  let valid = call_594870.validator(path, query, header, formData, body)
  let scheme = call_594870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594870.url(scheme.get, call_594870.host, call_594870.base,
                         call_594870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594870, url, valid)

proc call*(call_594871: Call_GetDescribeDBSubnetGroups_594854; MaxRecords: int = 0;
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
  var query_594872 = newJObject()
  add(query_594872, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_594872.add "Filters", Filters
  add(query_594872, "Action", newJString(Action))
  add(query_594872, "Marker", newJString(Marker))
  add(query_594872, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_594872, "Version", newJString(Version))
  result = call_594871.call(nil, query_594872, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_594854(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_594855, base: "/",
    url: url_GetDescribeDBSubnetGroups_594856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultClusterParameters_594912 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEngineDefaultClusterParameters_594914(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultClusterParameters_594913(path: JsonNode;
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
  var valid_594915 = query.getOrDefault("Action")
  valid_594915 = validateParameter(valid_594915, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_594915 != nil:
    section.add "Action", valid_594915
  var valid_594916 = query.getOrDefault("Version")
  valid_594916 = validateParameter(valid_594916, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594916 != nil:
    section.add "Version", valid_594916
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594917 = header.getOrDefault("X-Amz-Date")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "X-Amz-Date", valid_594917
  var valid_594918 = header.getOrDefault("X-Amz-Security-Token")
  valid_594918 = validateParameter(valid_594918, JString, required = false,
                                 default = nil)
  if valid_594918 != nil:
    section.add "X-Amz-Security-Token", valid_594918
  var valid_594919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "X-Amz-Content-Sha256", valid_594919
  var valid_594920 = header.getOrDefault("X-Amz-Algorithm")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Algorithm", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Signature")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Signature", valid_594921
  var valid_594922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594922 = validateParameter(valid_594922, JString, required = false,
                                 default = nil)
  if valid_594922 != nil:
    section.add "X-Amz-SignedHeaders", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Credential")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Credential", valid_594923
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
  var valid_594924 = formData.getOrDefault("Marker")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "Marker", valid_594924
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_594925 = formData.getOrDefault("DBParameterGroupFamily")
  valid_594925 = validateParameter(valid_594925, JString, required = true,
                                 default = nil)
  if valid_594925 != nil:
    section.add "DBParameterGroupFamily", valid_594925
  var valid_594926 = formData.getOrDefault("Filters")
  valid_594926 = validateParameter(valid_594926, JArray, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "Filters", valid_594926
  var valid_594927 = formData.getOrDefault("MaxRecords")
  valid_594927 = validateParameter(valid_594927, JInt, required = false, default = nil)
  if valid_594927 != nil:
    section.add "MaxRecords", valid_594927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594928: Call_PostDescribeEngineDefaultClusterParameters_594912;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_594928.validator(path, query, header, formData, body)
  let scheme = call_594928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594928.url(scheme.get, call_594928.host, call_594928.base,
                         call_594928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594928, url, valid)

proc call*(call_594929: Call_PostDescribeEngineDefaultClusterParameters_594912;
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
  var query_594930 = newJObject()
  var formData_594931 = newJObject()
  add(formData_594931, "Marker", newJString(Marker))
  add(query_594930, "Action", newJString(Action))
  add(formData_594931, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_594931.add "Filters", Filters
  add(formData_594931, "MaxRecords", newJInt(MaxRecords))
  add(query_594930, "Version", newJString(Version))
  result = call_594929.call(nil, query_594930, nil, formData_594931, nil)

var postDescribeEngineDefaultClusterParameters* = Call_PostDescribeEngineDefaultClusterParameters_594912(
    name: "postDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_PostDescribeEngineDefaultClusterParameters_594913,
    base: "/", url: url_PostDescribeEngineDefaultClusterParameters_594914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultClusterParameters_594893 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEngineDefaultClusterParameters_594895(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultClusterParameters_594894(path: JsonNode;
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
  var valid_594896 = query.getOrDefault("MaxRecords")
  valid_594896 = validateParameter(valid_594896, JInt, required = false, default = nil)
  if valid_594896 != nil:
    section.add "MaxRecords", valid_594896
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_594897 = query.getOrDefault("DBParameterGroupFamily")
  valid_594897 = validateParameter(valid_594897, JString, required = true,
                                 default = nil)
  if valid_594897 != nil:
    section.add "DBParameterGroupFamily", valid_594897
  var valid_594898 = query.getOrDefault("Filters")
  valid_594898 = validateParameter(valid_594898, JArray, required = false,
                                 default = nil)
  if valid_594898 != nil:
    section.add "Filters", valid_594898
  var valid_594899 = query.getOrDefault("Action")
  valid_594899 = validateParameter(valid_594899, JString, required = true, default = newJString(
      "DescribeEngineDefaultClusterParameters"))
  if valid_594899 != nil:
    section.add "Action", valid_594899
  var valid_594900 = query.getOrDefault("Marker")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "Marker", valid_594900
  var valid_594901 = query.getOrDefault("Version")
  valid_594901 = validateParameter(valid_594901, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594901 != nil:
    section.add "Version", valid_594901
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594902 = header.getOrDefault("X-Amz-Date")
  valid_594902 = validateParameter(valid_594902, JString, required = false,
                                 default = nil)
  if valid_594902 != nil:
    section.add "X-Amz-Date", valid_594902
  var valid_594903 = header.getOrDefault("X-Amz-Security-Token")
  valid_594903 = validateParameter(valid_594903, JString, required = false,
                                 default = nil)
  if valid_594903 != nil:
    section.add "X-Amz-Security-Token", valid_594903
  var valid_594904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594904 = validateParameter(valid_594904, JString, required = false,
                                 default = nil)
  if valid_594904 != nil:
    section.add "X-Amz-Content-Sha256", valid_594904
  var valid_594905 = header.getOrDefault("X-Amz-Algorithm")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "X-Amz-Algorithm", valid_594905
  var valid_594906 = header.getOrDefault("X-Amz-Signature")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Signature", valid_594906
  var valid_594907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-SignedHeaders", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Credential")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Credential", valid_594908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594909: Call_GetDescribeEngineDefaultClusterParameters_594893;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the default engine and system parameter information for the cluster database engine.
  ## 
  let valid = call_594909.validator(path, query, header, formData, body)
  let scheme = call_594909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594909.url(scheme.get, call_594909.host, call_594909.base,
                         call_594909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594909, url, valid)

proc call*(call_594910: Call_GetDescribeEngineDefaultClusterParameters_594893;
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
  var query_594911 = newJObject()
  add(query_594911, "MaxRecords", newJInt(MaxRecords))
  add(query_594911, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_594911.add "Filters", Filters
  add(query_594911, "Action", newJString(Action))
  add(query_594911, "Marker", newJString(Marker))
  add(query_594911, "Version", newJString(Version))
  result = call_594910.call(nil, query_594911, nil, nil, nil)

var getDescribeEngineDefaultClusterParameters* = Call_GetDescribeEngineDefaultClusterParameters_594893(
    name: "getDescribeEngineDefaultClusterParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultClusterParameters",
    validator: validate_GetDescribeEngineDefaultClusterParameters_594894,
    base: "/", url: url_GetDescribeEngineDefaultClusterParameters_594895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_594949 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEventCategories_594951(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_594950(path: JsonNode; query: JsonNode;
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
  var valid_594952 = query.getOrDefault("Action")
  valid_594952 = validateParameter(valid_594952, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_594952 != nil:
    section.add "Action", valid_594952
  var valid_594953 = query.getOrDefault("Version")
  valid_594953 = validateParameter(valid_594953, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594953 != nil:
    section.add "Version", valid_594953
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594954 = header.getOrDefault("X-Amz-Date")
  valid_594954 = validateParameter(valid_594954, JString, required = false,
                                 default = nil)
  if valid_594954 != nil:
    section.add "X-Amz-Date", valid_594954
  var valid_594955 = header.getOrDefault("X-Amz-Security-Token")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Security-Token", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Content-Sha256", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Algorithm")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Algorithm", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Signature")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Signature", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-SignedHeaders", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Credential")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Credential", valid_594960
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   SourceType: JString
  ##             : <p>The type of source that is generating the events.</p> <p>Valid values: <code>db-instance</code>, <code>db-parameter-group</code>, <code>db-security-group</code>, <code>db-snapshot</code> </p>
  section = newJObject()
  var valid_594961 = formData.getOrDefault("Filters")
  valid_594961 = validateParameter(valid_594961, JArray, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "Filters", valid_594961
  var valid_594962 = formData.getOrDefault("SourceType")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "SourceType", valid_594962
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594963: Call_PostDescribeEventCategories_594949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_594963.validator(path, query, header, formData, body)
  let scheme = call_594963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594963.url(scheme.get, call_594963.host, call_594963.base,
                         call_594963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594963, url, valid)

proc call*(call_594964: Call_PostDescribeEventCategories_594949;
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
  var query_594965 = newJObject()
  var formData_594966 = newJObject()
  add(query_594965, "Action", newJString(Action))
  if Filters != nil:
    formData_594966.add "Filters", Filters
  add(query_594965, "Version", newJString(Version))
  add(formData_594966, "SourceType", newJString(SourceType))
  result = call_594964.call(nil, query_594965, nil, formData_594966, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_594949(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_594950, base: "/",
    url: url_PostDescribeEventCategories_594951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_594932 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEventCategories_594934(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_594933(path: JsonNode; query: JsonNode;
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
  var valid_594935 = query.getOrDefault("SourceType")
  valid_594935 = validateParameter(valid_594935, JString, required = false,
                                 default = nil)
  if valid_594935 != nil:
    section.add "SourceType", valid_594935
  var valid_594936 = query.getOrDefault("Filters")
  valid_594936 = validateParameter(valid_594936, JArray, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "Filters", valid_594936
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594937 = query.getOrDefault("Action")
  valid_594937 = validateParameter(valid_594937, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_594937 != nil:
    section.add "Action", valid_594937
  var valid_594938 = query.getOrDefault("Version")
  valid_594938 = validateParameter(valid_594938, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594938 != nil:
    section.add "Version", valid_594938
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594939 = header.getOrDefault("X-Amz-Date")
  valid_594939 = validateParameter(valid_594939, JString, required = false,
                                 default = nil)
  if valid_594939 != nil:
    section.add "X-Amz-Date", valid_594939
  var valid_594940 = header.getOrDefault("X-Amz-Security-Token")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "X-Amz-Security-Token", valid_594940
  var valid_594941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Content-Sha256", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Algorithm")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Algorithm", valid_594942
  var valid_594943 = header.getOrDefault("X-Amz-Signature")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-Signature", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-SignedHeaders", valid_594944
  var valid_594945 = header.getOrDefault("X-Amz-Credential")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "X-Amz-Credential", valid_594945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594946: Call_GetDescribeEventCategories_594932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays a list of categories for all event source types, or, if specified, for a specified source type. 
  ## 
  let valid = call_594946.validator(path, query, header, formData, body)
  let scheme = call_594946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594946.url(scheme.get, call_594946.host, call_594946.base,
                         call_594946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594946, url, valid)

proc call*(call_594947: Call_GetDescribeEventCategories_594932;
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
  var query_594948 = newJObject()
  add(query_594948, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_594948.add "Filters", Filters
  add(query_594948, "Action", newJString(Action))
  add(query_594948, "Version", newJString(Version))
  result = call_594947.call(nil, query_594948, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_594932(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_594933, base: "/",
    url: url_GetDescribeEventCategories_594934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_594991 = ref object of OpenApiRestCall_593421
proc url_PostDescribeEvents_594993(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_594992(path: JsonNode; query: JsonNode;
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
  var valid_594994 = query.getOrDefault("Action")
  valid_594994 = validateParameter(valid_594994, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594994 != nil:
    section.add "Action", valid_594994
  var valid_594995 = query.getOrDefault("Version")
  valid_594995 = validateParameter(valid_594995, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594995 != nil:
    section.add "Version", valid_594995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594996 = header.getOrDefault("X-Amz-Date")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Date", valid_594996
  var valid_594997 = header.getOrDefault("X-Amz-Security-Token")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "X-Amz-Security-Token", valid_594997
  var valid_594998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "X-Amz-Content-Sha256", valid_594998
  var valid_594999 = header.getOrDefault("X-Amz-Algorithm")
  valid_594999 = validateParameter(valid_594999, JString, required = false,
                                 default = nil)
  if valid_594999 != nil:
    section.add "X-Amz-Algorithm", valid_594999
  var valid_595000 = header.getOrDefault("X-Amz-Signature")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "X-Amz-Signature", valid_595000
  var valid_595001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "X-Amz-SignedHeaders", valid_595001
  var valid_595002 = header.getOrDefault("X-Amz-Credential")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "X-Amz-Credential", valid_595002
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
  var valid_595003 = formData.getOrDefault("SourceIdentifier")
  valid_595003 = validateParameter(valid_595003, JString, required = false,
                                 default = nil)
  if valid_595003 != nil:
    section.add "SourceIdentifier", valid_595003
  var valid_595004 = formData.getOrDefault("EventCategories")
  valid_595004 = validateParameter(valid_595004, JArray, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "EventCategories", valid_595004
  var valid_595005 = formData.getOrDefault("Marker")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "Marker", valid_595005
  var valid_595006 = formData.getOrDefault("StartTime")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "StartTime", valid_595006
  var valid_595007 = formData.getOrDefault("Duration")
  valid_595007 = validateParameter(valid_595007, JInt, required = false, default = nil)
  if valid_595007 != nil:
    section.add "Duration", valid_595007
  var valid_595008 = formData.getOrDefault("Filters")
  valid_595008 = validateParameter(valid_595008, JArray, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "Filters", valid_595008
  var valid_595009 = formData.getOrDefault("EndTime")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "EndTime", valid_595009
  var valid_595010 = formData.getOrDefault("MaxRecords")
  valid_595010 = validateParameter(valid_595010, JInt, required = false, default = nil)
  if valid_595010 != nil:
    section.add "MaxRecords", valid_595010
  var valid_595011 = formData.getOrDefault("SourceType")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_595011 != nil:
    section.add "SourceType", valid_595011
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595012: Call_PostDescribeEvents_594991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_595012.validator(path, query, header, formData, body)
  let scheme = call_595012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595012.url(scheme.get, call_595012.host, call_595012.base,
                         call_595012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595012, url, valid)

proc call*(call_595013: Call_PostDescribeEvents_594991;
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
  var query_595014 = newJObject()
  var formData_595015 = newJObject()
  add(formData_595015, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_595015.add "EventCategories", EventCategories
  add(formData_595015, "Marker", newJString(Marker))
  add(formData_595015, "StartTime", newJString(StartTime))
  add(query_595014, "Action", newJString(Action))
  add(formData_595015, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_595015.add "Filters", Filters
  add(formData_595015, "EndTime", newJString(EndTime))
  add(formData_595015, "MaxRecords", newJInt(MaxRecords))
  add(query_595014, "Version", newJString(Version))
  add(formData_595015, "SourceType", newJString(SourceType))
  result = call_595013.call(nil, query_595014, nil, formData_595015, nil)

var postDescribeEvents* = Call_PostDescribeEvents_594991(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_594992, base: "/",
    url: url_PostDescribeEvents_594993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_594967 = ref object of OpenApiRestCall_593421
proc url_GetDescribeEvents_594969(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_594968(path: JsonNode; query: JsonNode;
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
  var valid_594970 = query.getOrDefault("SourceType")
  valid_594970 = validateParameter(valid_594970, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_594970 != nil:
    section.add "SourceType", valid_594970
  var valid_594971 = query.getOrDefault("MaxRecords")
  valid_594971 = validateParameter(valid_594971, JInt, required = false, default = nil)
  if valid_594971 != nil:
    section.add "MaxRecords", valid_594971
  var valid_594972 = query.getOrDefault("StartTime")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "StartTime", valid_594972
  var valid_594973 = query.getOrDefault("Filters")
  valid_594973 = validateParameter(valid_594973, JArray, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "Filters", valid_594973
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594974 = query.getOrDefault("Action")
  valid_594974 = validateParameter(valid_594974, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_594974 != nil:
    section.add "Action", valid_594974
  var valid_594975 = query.getOrDefault("SourceIdentifier")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "SourceIdentifier", valid_594975
  var valid_594976 = query.getOrDefault("Marker")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "Marker", valid_594976
  var valid_594977 = query.getOrDefault("EventCategories")
  valid_594977 = validateParameter(valid_594977, JArray, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "EventCategories", valid_594977
  var valid_594978 = query.getOrDefault("Duration")
  valid_594978 = validateParameter(valid_594978, JInt, required = false, default = nil)
  if valid_594978 != nil:
    section.add "Duration", valid_594978
  var valid_594979 = query.getOrDefault("EndTime")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "EndTime", valid_594979
  var valid_594980 = query.getOrDefault("Version")
  valid_594980 = validateParameter(valid_594980, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_594980 != nil:
    section.add "Version", valid_594980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594981 = header.getOrDefault("X-Amz-Date")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = nil)
  if valid_594981 != nil:
    section.add "X-Amz-Date", valid_594981
  var valid_594982 = header.getOrDefault("X-Amz-Security-Token")
  valid_594982 = validateParameter(valid_594982, JString, required = false,
                                 default = nil)
  if valid_594982 != nil:
    section.add "X-Amz-Security-Token", valid_594982
  var valid_594983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594983 = validateParameter(valid_594983, JString, required = false,
                                 default = nil)
  if valid_594983 != nil:
    section.add "X-Amz-Content-Sha256", valid_594983
  var valid_594984 = header.getOrDefault("X-Amz-Algorithm")
  valid_594984 = validateParameter(valid_594984, JString, required = false,
                                 default = nil)
  if valid_594984 != nil:
    section.add "X-Amz-Algorithm", valid_594984
  var valid_594985 = header.getOrDefault("X-Amz-Signature")
  valid_594985 = validateParameter(valid_594985, JString, required = false,
                                 default = nil)
  if valid_594985 != nil:
    section.add "X-Amz-Signature", valid_594985
  var valid_594986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "X-Amz-SignedHeaders", valid_594986
  var valid_594987 = header.getOrDefault("X-Amz-Credential")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "X-Amz-Credential", valid_594987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594988: Call_GetDescribeEvents_594967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. You can obtain events specific to a particular DB instance, DB security group, DB snapshot, or DB parameter group by providing the name as a parameter. By default, the events of the past hour are returned.
  ## 
  let valid = call_594988.validator(path, query, header, formData, body)
  let scheme = call_594988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594988.url(scheme.get, call_594988.host, call_594988.base,
                         call_594988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594988, url, valid)

proc call*(call_594989: Call_GetDescribeEvents_594967;
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
  var query_594990 = newJObject()
  add(query_594990, "SourceType", newJString(SourceType))
  add(query_594990, "MaxRecords", newJInt(MaxRecords))
  add(query_594990, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_594990.add "Filters", Filters
  add(query_594990, "Action", newJString(Action))
  add(query_594990, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_594990, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_594990.add "EventCategories", EventCategories
  add(query_594990, "Duration", newJInt(Duration))
  add(query_594990, "EndTime", newJString(EndTime))
  add(query_594990, "Version", newJString(Version))
  result = call_594989.call(nil, query_594990, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_594967(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_594968,
    base: "/", url: url_GetDescribeEvents_594969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_595039 = ref object of OpenApiRestCall_593421
proc url_PostDescribeOrderableDBInstanceOptions_595041(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_595040(path: JsonNode;
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
  var valid_595042 = query.getOrDefault("Action")
  valid_595042 = validateParameter(valid_595042, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595042 != nil:
    section.add "Action", valid_595042
  var valid_595043 = query.getOrDefault("Version")
  valid_595043 = validateParameter(valid_595043, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595043 != nil:
    section.add "Version", valid_595043
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595044 = header.getOrDefault("X-Amz-Date")
  valid_595044 = validateParameter(valid_595044, JString, required = false,
                                 default = nil)
  if valid_595044 != nil:
    section.add "X-Amz-Date", valid_595044
  var valid_595045 = header.getOrDefault("X-Amz-Security-Token")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "X-Amz-Security-Token", valid_595045
  var valid_595046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Content-Sha256", valid_595046
  var valid_595047 = header.getOrDefault("X-Amz-Algorithm")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Algorithm", valid_595047
  var valid_595048 = header.getOrDefault("X-Amz-Signature")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-Signature", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-SignedHeaders", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Credential")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Credential", valid_595050
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
  var valid_595051 = formData.getOrDefault("Engine")
  valid_595051 = validateParameter(valid_595051, JString, required = true,
                                 default = nil)
  if valid_595051 != nil:
    section.add "Engine", valid_595051
  var valid_595052 = formData.getOrDefault("Marker")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "Marker", valid_595052
  var valid_595053 = formData.getOrDefault("Vpc")
  valid_595053 = validateParameter(valid_595053, JBool, required = false, default = nil)
  if valid_595053 != nil:
    section.add "Vpc", valid_595053
  var valid_595054 = formData.getOrDefault("DBInstanceClass")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "DBInstanceClass", valid_595054
  var valid_595055 = formData.getOrDefault("Filters")
  valid_595055 = validateParameter(valid_595055, JArray, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "Filters", valid_595055
  var valid_595056 = formData.getOrDefault("LicenseModel")
  valid_595056 = validateParameter(valid_595056, JString, required = false,
                                 default = nil)
  if valid_595056 != nil:
    section.add "LicenseModel", valid_595056
  var valid_595057 = formData.getOrDefault("MaxRecords")
  valid_595057 = validateParameter(valid_595057, JInt, required = false, default = nil)
  if valid_595057 != nil:
    section.add "MaxRecords", valid_595057
  var valid_595058 = formData.getOrDefault("EngineVersion")
  valid_595058 = validateParameter(valid_595058, JString, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "EngineVersion", valid_595058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595059: Call_PostDescribeOrderableDBInstanceOptions_595039;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_595059.validator(path, query, header, formData, body)
  let scheme = call_595059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595059.url(scheme.get, call_595059.host, call_595059.base,
                         call_595059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595059, url, valid)

proc call*(call_595060: Call_PostDescribeOrderableDBInstanceOptions_595039;
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
  var query_595061 = newJObject()
  var formData_595062 = newJObject()
  add(formData_595062, "Engine", newJString(Engine))
  add(formData_595062, "Marker", newJString(Marker))
  add(query_595061, "Action", newJString(Action))
  add(formData_595062, "Vpc", newJBool(Vpc))
  add(formData_595062, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_595062.add "Filters", Filters
  add(formData_595062, "LicenseModel", newJString(LicenseModel))
  add(formData_595062, "MaxRecords", newJInt(MaxRecords))
  add(formData_595062, "EngineVersion", newJString(EngineVersion))
  add(query_595061, "Version", newJString(Version))
  result = call_595060.call(nil, query_595061, nil, formData_595062, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_595039(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_595040, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_595041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_595016 = ref object of OpenApiRestCall_593421
proc url_GetDescribeOrderableDBInstanceOptions_595018(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_595017(path: JsonNode;
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
  var valid_595019 = query.getOrDefault("Engine")
  valid_595019 = validateParameter(valid_595019, JString, required = true,
                                 default = nil)
  if valid_595019 != nil:
    section.add "Engine", valid_595019
  var valid_595020 = query.getOrDefault("MaxRecords")
  valid_595020 = validateParameter(valid_595020, JInt, required = false, default = nil)
  if valid_595020 != nil:
    section.add "MaxRecords", valid_595020
  var valid_595021 = query.getOrDefault("Filters")
  valid_595021 = validateParameter(valid_595021, JArray, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "Filters", valid_595021
  var valid_595022 = query.getOrDefault("LicenseModel")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "LicenseModel", valid_595022
  var valid_595023 = query.getOrDefault("Vpc")
  valid_595023 = validateParameter(valid_595023, JBool, required = false, default = nil)
  if valid_595023 != nil:
    section.add "Vpc", valid_595023
  var valid_595024 = query.getOrDefault("DBInstanceClass")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "DBInstanceClass", valid_595024
  var valid_595025 = query.getOrDefault("Action")
  valid_595025 = validateParameter(valid_595025, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_595025 != nil:
    section.add "Action", valid_595025
  var valid_595026 = query.getOrDefault("Marker")
  valid_595026 = validateParameter(valid_595026, JString, required = false,
                                 default = nil)
  if valid_595026 != nil:
    section.add "Marker", valid_595026
  var valid_595027 = query.getOrDefault("EngineVersion")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "EngineVersion", valid_595027
  var valid_595028 = query.getOrDefault("Version")
  valid_595028 = validateParameter(valid_595028, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595028 != nil:
    section.add "Version", valid_595028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595029 = header.getOrDefault("X-Amz-Date")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "X-Amz-Date", valid_595029
  var valid_595030 = header.getOrDefault("X-Amz-Security-Token")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "X-Amz-Security-Token", valid_595030
  var valid_595031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Content-Sha256", valid_595031
  var valid_595032 = header.getOrDefault("X-Amz-Algorithm")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Algorithm", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-Signature")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-Signature", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-SignedHeaders", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Credential")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Credential", valid_595035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595036: Call_GetDescribeOrderableDBInstanceOptions_595016;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of orderable DB instance options for the specified engine.
  ## 
  let valid = call_595036.validator(path, query, header, formData, body)
  let scheme = call_595036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595036.url(scheme.get, call_595036.host, call_595036.base,
                         call_595036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595036, url, valid)

proc call*(call_595037: Call_GetDescribeOrderableDBInstanceOptions_595016;
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
  var query_595038 = newJObject()
  add(query_595038, "Engine", newJString(Engine))
  add(query_595038, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595038.add "Filters", Filters
  add(query_595038, "LicenseModel", newJString(LicenseModel))
  add(query_595038, "Vpc", newJBool(Vpc))
  add(query_595038, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595038, "Action", newJString(Action))
  add(query_595038, "Marker", newJString(Marker))
  add(query_595038, "EngineVersion", newJString(EngineVersion))
  add(query_595038, "Version", newJString(Version))
  result = call_595037.call(nil, query_595038, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_595016(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_595017, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_595018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePendingMaintenanceActions_595082 = ref object of OpenApiRestCall_593421
proc url_PostDescribePendingMaintenanceActions_595084(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribePendingMaintenanceActions_595083(path: JsonNode;
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
  var valid_595085 = query.getOrDefault("Action")
  valid_595085 = validateParameter(valid_595085, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_595085 != nil:
    section.add "Action", valid_595085
  var valid_595086 = query.getOrDefault("Version")
  valid_595086 = validateParameter(valid_595086, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595086 != nil:
    section.add "Version", valid_595086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595087 = header.getOrDefault("X-Amz-Date")
  valid_595087 = validateParameter(valid_595087, JString, required = false,
                                 default = nil)
  if valid_595087 != nil:
    section.add "X-Amz-Date", valid_595087
  var valid_595088 = header.getOrDefault("X-Amz-Security-Token")
  valid_595088 = validateParameter(valid_595088, JString, required = false,
                                 default = nil)
  if valid_595088 != nil:
    section.add "X-Amz-Security-Token", valid_595088
  var valid_595089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595089 = validateParameter(valid_595089, JString, required = false,
                                 default = nil)
  if valid_595089 != nil:
    section.add "X-Amz-Content-Sha256", valid_595089
  var valid_595090 = header.getOrDefault("X-Amz-Algorithm")
  valid_595090 = validateParameter(valid_595090, JString, required = false,
                                 default = nil)
  if valid_595090 != nil:
    section.add "X-Amz-Algorithm", valid_595090
  var valid_595091 = header.getOrDefault("X-Amz-Signature")
  valid_595091 = validateParameter(valid_595091, JString, required = false,
                                 default = nil)
  if valid_595091 != nil:
    section.add "X-Amz-Signature", valid_595091
  var valid_595092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595092 = validateParameter(valid_595092, JString, required = false,
                                 default = nil)
  if valid_595092 != nil:
    section.add "X-Amz-SignedHeaders", valid_595092
  var valid_595093 = header.getOrDefault("X-Amz-Credential")
  valid_595093 = validateParameter(valid_595093, JString, required = false,
                                 default = nil)
  if valid_595093 != nil:
    section.add "X-Amz-Credential", valid_595093
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
  var valid_595094 = formData.getOrDefault("Marker")
  valid_595094 = validateParameter(valid_595094, JString, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "Marker", valid_595094
  var valid_595095 = formData.getOrDefault("ResourceIdentifier")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "ResourceIdentifier", valid_595095
  var valid_595096 = formData.getOrDefault("Filters")
  valid_595096 = validateParameter(valid_595096, JArray, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "Filters", valid_595096
  var valid_595097 = formData.getOrDefault("MaxRecords")
  valid_595097 = validateParameter(valid_595097, JInt, required = false, default = nil)
  if valid_595097 != nil:
    section.add "MaxRecords", valid_595097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595098: Call_PostDescribePendingMaintenanceActions_595082;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_595098.validator(path, query, header, formData, body)
  let scheme = call_595098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595098.url(scheme.get, call_595098.host, call_595098.base,
                         call_595098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595098, url, valid)

proc call*(call_595099: Call_PostDescribePendingMaintenanceActions_595082;
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
  var query_595100 = newJObject()
  var formData_595101 = newJObject()
  add(formData_595101, "Marker", newJString(Marker))
  add(query_595100, "Action", newJString(Action))
  add(formData_595101, "ResourceIdentifier", newJString(ResourceIdentifier))
  if Filters != nil:
    formData_595101.add "Filters", Filters
  add(formData_595101, "MaxRecords", newJInt(MaxRecords))
  add(query_595100, "Version", newJString(Version))
  result = call_595099.call(nil, query_595100, nil, formData_595101, nil)

var postDescribePendingMaintenanceActions* = Call_PostDescribePendingMaintenanceActions_595082(
    name: "postDescribePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_PostDescribePendingMaintenanceActions_595083, base: "/",
    url: url_PostDescribePendingMaintenanceActions_595084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePendingMaintenanceActions_595063 = ref object of OpenApiRestCall_593421
proc url_GetDescribePendingMaintenanceActions_595065(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribePendingMaintenanceActions_595064(path: JsonNode;
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
  var valid_595066 = query.getOrDefault("MaxRecords")
  valid_595066 = validateParameter(valid_595066, JInt, required = false, default = nil)
  if valid_595066 != nil:
    section.add "MaxRecords", valid_595066
  var valid_595067 = query.getOrDefault("Filters")
  valid_595067 = validateParameter(valid_595067, JArray, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "Filters", valid_595067
  var valid_595068 = query.getOrDefault("ResourceIdentifier")
  valid_595068 = validateParameter(valid_595068, JString, required = false,
                                 default = nil)
  if valid_595068 != nil:
    section.add "ResourceIdentifier", valid_595068
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595069 = query.getOrDefault("Action")
  valid_595069 = validateParameter(valid_595069, JString, required = true, default = newJString(
      "DescribePendingMaintenanceActions"))
  if valid_595069 != nil:
    section.add "Action", valid_595069
  var valid_595070 = query.getOrDefault("Marker")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "Marker", valid_595070
  var valid_595071 = query.getOrDefault("Version")
  valid_595071 = validateParameter(valid_595071, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595071 != nil:
    section.add "Version", valid_595071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595072 = header.getOrDefault("X-Amz-Date")
  valid_595072 = validateParameter(valid_595072, JString, required = false,
                                 default = nil)
  if valid_595072 != nil:
    section.add "X-Amz-Date", valid_595072
  var valid_595073 = header.getOrDefault("X-Amz-Security-Token")
  valid_595073 = validateParameter(valid_595073, JString, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "X-Amz-Security-Token", valid_595073
  var valid_595074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "X-Amz-Content-Sha256", valid_595074
  var valid_595075 = header.getOrDefault("X-Amz-Algorithm")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = nil)
  if valid_595075 != nil:
    section.add "X-Amz-Algorithm", valid_595075
  var valid_595076 = header.getOrDefault("X-Amz-Signature")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "X-Amz-Signature", valid_595076
  var valid_595077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595077 = validateParameter(valid_595077, JString, required = false,
                                 default = nil)
  if valid_595077 != nil:
    section.add "X-Amz-SignedHeaders", valid_595077
  var valid_595078 = header.getOrDefault("X-Amz-Credential")
  valid_595078 = validateParameter(valid_595078, JString, required = false,
                                 default = nil)
  if valid_595078 != nil:
    section.add "X-Amz-Credential", valid_595078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595079: Call_GetDescribePendingMaintenanceActions_595063;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
  ## 
  let valid = call_595079.validator(path, query, header, formData, body)
  let scheme = call_595079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595079.url(scheme.get, call_595079.host, call_595079.base,
                         call_595079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595079, url, valid)

proc call*(call_595080: Call_GetDescribePendingMaintenanceActions_595063;
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
  var query_595081 = newJObject()
  add(query_595081, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595081.add "Filters", Filters
  add(query_595081, "ResourceIdentifier", newJString(ResourceIdentifier))
  add(query_595081, "Action", newJString(Action))
  add(query_595081, "Marker", newJString(Marker))
  add(query_595081, "Version", newJString(Version))
  result = call_595080.call(nil, query_595081, nil, nil, nil)

var getDescribePendingMaintenanceActions* = Call_GetDescribePendingMaintenanceActions_595063(
    name: "getDescribePendingMaintenanceActions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribePendingMaintenanceActions",
    validator: validate_GetDescribePendingMaintenanceActions_595064, base: "/",
    url: url_GetDescribePendingMaintenanceActions_595065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostFailoverDBCluster_595119 = ref object of OpenApiRestCall_593421
proc url_PostFailoverDBCluster_595121(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostFailoverDBCluster_595120(path: JsonNode; query: JsonNode;
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
  var valid_595122 = query.getOrDefault("Action")
  valid_595122 = validateParameter(valid_595122, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_595122 != nil:
    section.add "Action", valid_595122
  var valid_595123 = query.getOrDefault("Version")
  valid_595123 = validateParameter(valid_595123, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595123 != nil:
    section.add "Version", valid_595123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595124 = header.getOrDefault("X-Amz-Date")
  valid_595124 = validateParameter(valid_595124, JString, required = false,
                                 default = nil)
  if valid_595124 != nil:
    section.add "X-Amz-Date", valid_595124
  var valid_595125 = header.getOrDefault("X-Amz-Security-Token")
  valid_595125 = validateParameter(valid_595125, JString, required = false,
                                 default = nil)
  if valid_595125 != nil:
    section.add "X-Amz-Security-Token", valid_595125
  var valid_595126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "X-Amz-Content-Sha256", valid_595126
  var valid_595127 = header.getOrDefault("X-Amz-Algorithm")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-Algorithm", valid_595127
  var valid_595128 = header.getOrDefault("X-Amz-Signature")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "X-Amz-Signature", valid_595128
  var valid_595129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "X-Amz-SignedHeaders", valid_595129
  var valid_595130 = header.getOrDefault("X-Amz-Credential")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-Credential", valid_595130
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBInstanceIdentifier: JString
  ##                             : <p>The name of the instance to promote to the primary instance.</p> <p>You must specify the instance identifier for an Amazon DocumentDB replica in the DB cluster. For example, <code>mydbcluster-replica1</code>.</p>
  ##   DBClusterIdentifier: JString
  ##                      : <p>A DB cluster identifier to force a failover for. This parameter is not case sensitive.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBCluster</code>.</p> </li> </ul>
  section = newJObject()
  var valid_595131 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "TargetDBInstanceIdentifier", valid_595131
  var valid_595132 = formData.getOrDefault("DBClusterIdentifier")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "DBClusterIdentifier", valid_595132
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595133: Call_PostFailoverDBCluster_595119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_595133.validator(path, query, header, formData, body)
  let scheme = call_595133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595133.url(scheme.get, call_595133.host, call_595133.base,
                         call_595133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595133, url, valid)

proc call*(call_595134: Call_PostFailoverDBCluster_595119;
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
  var query_595135 = newJObject()
  var formData_595136 = newJObject()
  add(query_595135, "Action", newJString(Action))
  add(formData_595136, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_595136, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_595135, "Version", newJString(Version))
  result = call_595134.call(nil, query_595135, nil, formData_595136, nil)

var postFailoverDBCluster* = Call_PostFailoverDBCluster_595119(
    name: "postFailoverDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_PostFailoverDBCluster_595120, base: "/",
    url: url_PostFailoverDBCluster_595121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFailoverDBCluster_595102 = ref object of OpenApiRestCall_593421
proc url_GetFailoverDBCluster_595104(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFailoverDBCluster_595103(path: JsonNode; query: JsonNode;
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
  var valid_595105 = query.getOrDefault("DBClusterIdentifier")
  valid_595105 = validateParameter(valid_595105, JString, required = false,
                                 default = nil)
  if valid_595105 != nil:
    section.add "DBClusterIdentifier", valid_595105
  var valid_595106 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_595106 = validateParameter(valid_595106, JString, required = false,
                                 default = nil)
  if valid_595106 != nil:
    section.add "TargetDBInstanceIdentifier", valid_595106
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595107 = query.getOrDefault("Action")
  valid_595107 = validateParameter(valid_595107, JString, required = true,
                                 default = newJString("FailoverDBCluster"))
  if valid_595107 != nil:
    section.add "Action", valid_595107
  var valid_595108 = query.getOrDefault("Version")
  valid_595108 = validateParameter(valid_595108, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595108 != nil:
    section.add "Version", valid_595108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595109 = header.getOrDefault("X-Amz-Date")
  valid_595109 = validateParameter(valid_595109, JString, required = false,
                                 default = nil)
  if valid_595109 != nil:
    section.add "X-Amz-Date", valid_595109
  var valid_595110 = header.getOrDefault("X-Amz-Security-Token")
  valid_595110 = validateParameter(valid_595110, JString, required = false,
                                 default = nil)
  if valid_595110 != nil:
    section.add "X-Amz-Security-Token", valid_595110
  var valid_595111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Content-Sha256", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-Algorithm")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-Algorithm", valid_595112
  var valid_595113 = header.getOrDefault("X-Amz-Signature")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "X-Amz-Signature", valid_595113
  var valid_595114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "X-Amz-SignedHeaders", valid_595114
  var valid_595115 = header.getOrDefault("X-Amz-Credential")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Credential", valid_595115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595116: Call_GetFailoverDBCluster_595102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Forces a failover for a DB cluster.</p> <p>A failover for a DB cluster promotes one of the Amazon DocumentDB replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer).</p> <p>If the primary instance fails, Amazon DocumentDB automatically fails over to an Amazon DocumentDB replica, if one exists. You can force a failover when you want to simulate a failure of a primary instance for testing.</p>
  ## 
  let valid = call_595116.validator(path, query, header, formData, body)
  let scheme = call_595116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595116.url(scheme.get, call_595116.host, call_595116.base,
                         call_595116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595116, url, valid)

proc call*(call_595117: Call_GetFailoverDBCluster_595102;
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
  var query_595118 = newJObject()
  add(query_595118, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_595118, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_595118, "Action", newJString(Action))
  add(query_595118, "Version", newJString(Version))
  result = call_595117.call(nil, query_595118, nil, nil, nil)

var getFailoverDBCluster* = Call_GetFailoverDBCluster_595102(
    name: "getFailoverDBCluster", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=FailoverDBCluster",
    validator: validate_GetFailoverDBCluster_595103, base: "/",
    url: url_GetFailoverDBCluster_595104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_595154 = ref object of OpenApiRestCall_593421
proc url_PostListTagsForResource_595156(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_595155(path: JsonNode; query: JsonNode;
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
  var valid_595157 = query.getOrDefault("Action")
  valid_595157 = validateParameter(valid_595157, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595157 != nil:
    section.add "Action", valid_595157
  var valid_595158 = query.getOrDefault("Version")
  valid_595158 = validateParameter(valid_595158, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595158 != nil:
    section.add "Version", valid_595158
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595159 = header.getOrDefault("X-Amz-Date")
  valid_595159 = validateParameter(valid_595159, JString, required = false,
                                 default = nil)
  if valid_595159 != nil:
    section.add "X-Amz-Date", valid_595159
  var valid_595160 = header.getOrDefault("X-Amz-Security-Token")
  valid_595160 = validateParameter(valid_595160, JString, required = false,
                                 default = nil)
  if valid_595160 != nil:
    section.add "X-Amz-Security-Token", valid_595160
  var valid_595161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-Content-Sha256", valid_595161
  var valid_595162 = header.getOrDefault("X-Amz-Algorithm")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-Algorithm", valid_595162
  var valid_595163 = header.getOrDefault("X-Amz-Signature")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "X-Amz-Signature", valid_595163
  var valid_595164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595164 = validateParameter(valid_595164, JString, required = false,
                                 default = nil)
  if valid_595164 != nil:
    section.add "X-Amz-SignedHeaders", valid_595164
  var valid_595165 = header.getOrDefault("X-Amz-Credential")
  valid_595165 = validateParameter(valid_595165, JString, required = false,
                                 default = nil)
  if valid_595165 != nil:
    section.add "X-Amz-Credential", valid_595165
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##          : This parameter is not currently supported.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource with tags to be listed. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  var valid_595166 = formData.getOrDefault("Filters")
  valid_595166 = validateParameter(valid_595166, JArray, required = false,
                                 default = nil)
  if valid_595166 != nil:
    section.add "Filters", valid_595166
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_595167 = formData.getOrDefault("ResourceName")
  valid_595167 = validateParameter(valid_595167, JString, required = true,
                                 default = nil)
  if valid_595167 != nil:
    section.add "ResourceName", valid_595167
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595168: Call_PostListTagsForResource_595154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_595168.validator(path, query, header, formData, body)
  let scheme = call_595168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595168.url(scheme.get, call_595168.host, call_595168.base,
                         call_595168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595168, url, valid)

proc call*(call_595169: Call_PostListTagsForResource_595154; ResourceName: string;
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
  var query_595170 = newJObject()
  var formData_595171 = newJObject()
  add(query_595170, "Action", newJString(Action))
  if Filters != nil:
    formData_595171.add "Filters", Filters
  add(formData_595171, "ResourceName", newJString(ResourceName))
  add(query_595170, "Version", newJString(Version))
  result = call_595169.call(nil, query_595170, nil, formData_595171, nil)

var postListTagsForResource* = Call_PostListTagsForResource_595154(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_595155, base: "/",
    url: url_PostListTagsForResource_595156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_595137 = ref object of OpenApiRestCall_593421
proc url_GetListTagsForResource_595139(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_595138(path: JsonNode; query: JsonNode;
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
  var valid_595140 = query.getOrDefault("Filters")
  valid_595140 = validateParameter(valid_595140, JArray, required = false,
                                 default = nil)
  if valid_595140 != nil:
    section.add "Filters", valid_595140
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_595141 = query.getOrDefault("ResourceName")
  valid_595141 = validateParameter(valid_595141, JString, required = true,
                                 default = nil)
  if valid_595141 != nil:
    section.add "ResourceName", valid_595141
  var valid_595142 = query.getOrDefault("Action")
  valid_595142 = validateParameter(valid_595142, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595142 != nil:
    section.add "Action", valid_595142
  var valid_595143 = query.getOrDefault("Version")
  valid_595143 = validateParameter(valid_595143, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595143 != nil:
    section.add "Version", valid_595143
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595144 = header.getOrDefault("X-Amz-Date")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "X-Amz-Date", valid_595144
  var valid_595145 = header.getOrDefault("X-Amz-Security-Token")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "X-Amz-Security-Token", valid_595145
  var valid_595146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "X-Amz-Content-Sha256", valid_595146
  var valid_595147 = header.getOrDefault("X-Amz-Algorithm")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "X-Amz-Algorithm", valid_595147
  var valid_595148 = header.getOrDefault("X-Amz-Signature")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "X-Amz-Signature", valid_595148
  var valid_595149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595149 = validateParameter(valid_595149, JString, required = false,
                                 default = nil)
  if valid_595149 != nil:
    section.add "X-Amz-SignedHeaders", valid_595149
  var valid_595150 = header.getOrDefault("X-Amz-Credential")
  valid_595150 = validateParameter(valid_595150, JString, required = false,
                                 default = nil)
  if valid_595150 != nil:
    section.add "X-Amz-Credential", valid_595150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595151: Call_GetListTagsForResource_595137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on an Amazon DocumentDB resource.
  ## 
  let valid = call_595151.validator(path, query, header, formData, body)
  let scheme = call_595151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595151.url(scheme.get, call_595151.host, call_595151.base,
                         call_595151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595151, url, valid)

proc call*(call_595152: Call_GetListTagsForResource_595137; ResourceName: string;
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
  var query_595153 = newJObject()
  if Filters != nil:
    query_595153.add "Filters", Filters
  add(query_595153, "ResourceName", newJString(ResourceName))
  add(query_595153, "Action", newJString(Action))
  add(query_595153, "Version", newJString(Version))
  result = call_595152.call(nil, query_595153, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_595137(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_595138, base: "/",
    url: url_GetListTagsForResource_595139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBCluster_595201 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBCluster_595203(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBCluster_595202(path: JsonNode; query: JsonNode;
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
  var valid_595204 = query.getOrDefault("Action")
  valid_595204 = validateParameter(valid_595204, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_595204 != nil:
    section.add "Action", valid_595204
  var valid_595205 = query.getOrDefault("Version")
  valid_595205 = validateParameter(valid_595205, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595205 != nil:
    section.add "Version", valid_595205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595206 = header.getOrDefault("X-Amz-Date")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "X-Amz-Date", valid_595206
  var valid_595207 = header.getOrDefault("X-Amz-Security-Token")
  valid_595207 = validateParameter(valid_595207, JString, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "X-Amz-Security-Token", valid_595207
  var valid_595208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595208 = validateParameter(valid_595208, JString, required = false,
                                 default = nil)
  if valid_595208 != nil:
    section.add "X-Amz-Content-Sha256", valid_595208
  var valid_595209 = header.getOrDefault("X-Amz-Algorithm")
  valid_595209 = validateParameter(valid_595209, JString, required = false,
                                 default = nil)
  if valid_595209 != nil:
    section.add "X-Amz-Algorithm", valid_595209
  var valid_595210 = header.getOrDefault("X-Amz-Signature")
  valid_595210 = validateParameter(valid_595210, JString, required = false,
                                 default = nil)
  if valid_595210 != nil:
    section.add "X-Amz-Signature", valid_595210
  var valid_595211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595211 = validateParameter(valid_595211, JString, required = false,
                                 default = nil)
  if valid_595211 != nil:
    section.add "X-Amz-SignedHeaders", valid_595211
  var valid_595212 = header.getOrDefault("X-Amz-Credential")
  valid_595212 = validateParameter(valid_595212, JString, required = false,
                                 default = nil)
  if valid_595212 != nil:
    section.add "X-Amz-Credential", valid_595212
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
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
  var valid_595213 = formData.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_595213 = validateParameter(valid_595213, JArray, required = false,
                                 default = nil)
  if valid_595213 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_595213
  var valid_595214 = formData.getOrDefault("ApplyImmediately")
  valid_595214 = validateParameter(valid_595214, JBool, required = false, default = nil)
  if valid_595214 != nil:
    section.add "ApplyImmediately", valid_595214
  var valid_595215 = formData.getOrDefault("Port")
  valid_595215 = validateParameter(valid_595215, JInt, required = false, default = nil)
  if valid_595215 != nil:
    section.add "Port", valid_595215
  var valid_595216 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_595216 = validateParameter(valid_595216, JArray, required = false,
                                 default = nil)
  if valid_595216 != nil:
    section.add "VpcSecurityGroupIds", valid_595216
  var valid_595217 = formData.getOrDefault("BackupRetentionPeriod")
  valid_595217 = validateParameter(valid_595217, JInt, required = false, default = nil)
  if valid_595217 != nil:
    section.add "BackupRetentionPeriod", valid_595217
  var valid_595218 = formData.getOrDefault("MasterUserPassword")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "MasterUserPassword", valid_595218
  var valid_595219 = formData.getOrDefault("DeletionProtection")
  valid_595219 = validateParameter(valid_595219, JBool, required = false, default = nil)
  if valid_595219 != nil:
    section.add "DeletionProtection", valid_595219
  var valid_595220 = formData.getOrDefault("NewDBClusterIdentifier")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "NewDBClusterIdentifier", valid_595220
  var valid_595221 = formData.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_595221 = validateParameter(valid_595221, JArray, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_595221
  var valid_595222 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_595222 = validateParameter(valid_595222, JString, required = false,
                                 default = nil)
  if valid_595222 != nil:
    section.add "DBClusterParameterGroupName", valid_595222
  var valid_595223 = formData.getOrDefault("PreferredBackupWindow")
  valid_595223 = validateParameter(valid_595223, JString, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "PreferredBackupWindow", valid_595223
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_595224 = formData.getOrDefault("DBClusterIdentifier")
  valid_595224 = validateParameter(valid_595224, JString, required = true,
                                 default = nil)
  if valid_595224 != nil:
    section.add "DBClusterIdentifier", valid_595224
  var valid_595225 = formData.getOrDefault("EngineVersion")
  valid_595225 = validateParameter(valid_595225, JString, required = false,
                                 default = nil)
  if valid_595225 != nil:
    section.add "EngineVersion", valid_595225
  var valid_595226 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_595226 = validateParameter(valid_595226, JString, required = false,
                                 default = nil)
  if valid_595226 != nil:
    section.add "PreferredMaintenanceWindow", valid_595226
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595227: Call_PostModifyDBCluster_595201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_595227.validator(path, query, header, formData, body)
  let scheme = call_595227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595227.url(scheme.get, call_595227.host, call_595227.base,
                         call_595227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595227, url, valid)

proc call*(call_595228: Call_PostModifyDBCluster_595201;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
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
  var query_595229 = newJObject()
  var formData_595230 = newJObject()
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    formData_595230.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                       CloudwatchLogsExportConfigurationEnableLogTypes
  add(formData_595230, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_595230, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_595230.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_595230, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_595230, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_595230, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_595230, "NewDBClusterIdentifier",
      newJString(NewDBClusterIdentifier))
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    formData_595230.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                       CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_595229, "Action", newJString(Action))
  add(formData_595230, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_595230, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_595230, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_595230, "EngineVersion", newJString(EngineVersion))
  add(query_595229, "Version", newJString(Version))
  add(formData_595230, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_595228.call(nil, query_595229, nil, formData_595230, nil)

var postModifyDBCluster* = Call_PostModifyDBCluster_595201(
    name: "postModifyDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBCluster",
    validator: validate_PostModifyDBCluster_595202, base: "/",
    url: url_PostModifyDBCluster_595203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBCluster_595172 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBCluster_595174(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBCluster_595173(path: JsonNode; query: JsonNode;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
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
  var valid_595175 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_595175 = validateParameter(valid_595175, JString, required = false,
                                 default = nil)
  if valid_595175 != nil:
    section.add "PreferredMaintenanceWindow", valid_595175
  var valid_595176 = query.getOrDefault("DBClusterParameterGroupName")
  valid_595176 = validateParameter(valid_595176, JString, required = false,
                                 default = nil)
  if valid_595176 != nil:
    section.add "DBClusterParameterGroupName", valid_595176
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_595177 = query.getOrDefault("DBClusterIdentifier")
  valid_595177 = validateParameter(valid_595177, JString, required = true,
                                 default = nil)
  if valid_595177 != nil:
    section.add "DBClusterIdentifier", valid_595177
  var valid_595178 = query.getOrDefault("MasterUserPassword")
  valid_595178 = validateParameter(valid_595178, JString, required = false,
                                 default = nil)
  if valid_595178 != nil:
    section.add "MasterUserPassword", valid_595178
  var valid_595179 = query.getOrDefault("CloudwatchLogsExportConfiguration.EnableLogTypes")
  valid_595179 = validateParameter(valid_595179, JArray, required = false,
                                 default = nil)
  if valid_595179 != nil:
    section.add "CloudwatchLogsExportConfiguration.EnableLogTypes", valid_595179
  var valid_595180 = query.getOrDefault("VpcSecurityGroupIds")
  valid_595180 = validateParameter(valid_595180, JArray, required = false,
                                 default = nil)
  if valid_595180 != nil:
    section.add "VpcSecurityGroupIds", valid_595180
  var valid_595181 = query.getOrDefault("CloudwatchLogsExportConfiguration.DisableLogTypes")
  valid_595181 = validateParameter(valid_595181, JArray, required = false,
                                 default = nil)
  if valid_595181 != nil:
    section.add "CloudwatchLogsExportConfiguration.DisableLogTypes", valid_595181
  var valid_595182 = query.getOrDefault("BackupRetentionPeriod")
  valid_595182 = validateParameter(valid_595182, JInt, required = false, default = nil)
  if valid_595182 != nil:
    section.add "BackupRetentionPeriod", valid_595182
  var valid_595183 = query.getOrDefault("NewDBClusterIdentifier")
  valid_595183 = validateParameter(valid_595183, JString, required = false,
                                 default = nil)
  if valid_595183 != nil:
    section.add "NewDBClusterIdentifier", valid_595183
  var valid_595184 = query.getOrDefault("DeletionProtection")
  valid_595184 = validateParameter(valid_595184, JBool, required = false, default = nil)
  if valid_595184 != nil:
    section.add "DeletionProtection", valid_595184
  var valid_595185 = query.getOrDefault("Action")
  valid_595185 = validateParameter(valid_595185, JString, required = true,
                                 default = newJString("ModifyDBCluster"))
  if valid_595185 != nil:
    section.add "Action", valid_595185
  var valid_595186 = query.getOrDefault("EngineVersion")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "EngineVersion", valid_595186
  var valid_595187 = query.getOrDefault("Port")
  valid_595187 = validateParameter(valid_595187, JInt, required = false, default = nil)
  if valid_595187 != nil:
    section.add "Port", valid_595187
  var valid_595188 = query.getOrDefault("PreferredBackupWindow")
  valid_595188 = validateParameter(valid_595188, JString, required = false,
                                 default = nil)
  if valid_595188 != nil:
    section.add "PreferredBackupWindow", valid_595188
  var valid_595189 = query.getOrDefault("Version")
  valid_595189 = validateParameter(valid_595189, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595189 != nil:
    section.add "Version", valid_595189
  var valid_595190 = query.getOrDefault("ApplyImmediately")
  valid_595190 = validateParameter(valid_595190, JBool, required = false, default = nil)
  if valid_595190 != nil:
    section.add "ApplyImmediately", valid_595190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595191 = header.getOrDefault("X-Amz-Date")
  valid_595191 = validateParameter(valid_595191, JString, required = false,
                                 default = nil)
  if valid_595191 != nil:
    section.add "X-Amz-Date", valid_595191
  var valid_595192 = header.getOrDefault("X-Amz-Security-Token")
  valid_595192 = validateParameter(valid_595192, JString, required = false,
                                 default = nil)
  if valid_595192 != nil:
    section.add "X-Amz-Security-Token", valid_595192
  var valid_595193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595193 = validateParameter(valid_595193, JString, required = false,
                                 default = nil)
  if valid_595193 != nil:
    section.add "X-Amz-Content-Sha256", valid_595193
  var valid_595194 = header.getOrDefault("X-Amz-Algorithm")
  valid_595194 = validateParameter(valid_595194, JString, required = false,
                                 default = nil)
  if valid_595194 != nil:
    section.add "X-Amz-Algorithm", valid_595194
  var valid_595195 = header.getOrDefault("X-Amz-Signature")
  valid_595195 = validateParameter(valid_595195, JString, required = false,
                                 default = nil)
  if valid_595195 != nil:
    section.add "X-Amz-Signature", valid_595195
  var valid_595196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595196 = validateParameter(valid_595196, JString, required = false,
                                 default = nil)
  if valid_595196 != nil:
    section.add "X-Amz-SignedHeaders", valid_595196
  var valid_595197 = header.getOrDefault("X-Amz-Credential")
  valid_595197 = validateParameter(valid_595197, JString, required = false,
                                 default = nil)
  if valid_595197 != nil:
    section.add "X-Amz-Credential", valid_595197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595198: Call_GetModifyDBCluster_595172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a setting for an Amazon DocumentDB DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. 
  ## 
  let valid = call_595198.validator(path, query, header, formData, body)
  let scheme = call_595198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595198.url(scheme.get, call_595198.host, call_595198.base,
                         call_595198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595198, url, valid)

proc call*(call_595199: Call_GetModifyDBCluster_595172;
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
  ##                     : <p>The password for the master database user. This password can contain any printable ASCII character except forward slash (/), double quote ("), or the "at" symbol (@).</p> <p>Constraints: Must contain from 8 to 41 characters.</p>
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
  var query_595200 = newJObject()
  add(query_595200, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_595200, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_595200, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_595200, "MasterUserPassword", newJString(MasterUserPassword))
  if CloudwatchLogsExportConfigurationEnableLogTypes != nil:
    query_595200.add "CloudwatchLogsExportConfiguration.EnableLogTypes",
                    CloudwatchLogsExportConfigurationEnableLogTypes
  if VpcSecurityGroupIds != nil:
    query_595200.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if CloudwatchLogsExportConfigurationDisableLogTypes != nil:
    query_595200.add "CloudwatchLogsExportConfiguration.DisableLogTypes",
                    CloudwatchLogsExportConfigurationDisableLogTypes
  add(query_595200, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_595200, "NewDBClusterIdentifier", newJString(NewDBClusterIdentifier))
  add(query_595200, "DeletionProtection", newJBool(DeletionProtection))
  add(query_595200, "Action", newJString(Action))
  add(query_595200, "EngineVersion", newJString(EngineVersion))
  add(query_595200, "Port", newJInt(Port))
  add(query_595200, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_595200, "Version", newJString(Version))
  add(query_595200, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_595199.call(nil, query_595200, nil, nil, nil)

var getModifyDBCluster* = Call_GetModifyDBCluster_595172(
    name: "getModifyDBCluster", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=ModifyDBCluster", validator: validate_GetModifyDBCluster_595173,
    base: "/", url: url_GetModifyDBCluster_595174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterParameterGroup_595248 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBClusterParameterGroup_595250(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBClusterParameterGroup_595249(path: JsonNode;
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
  var valid_595251 = query.getOrDefault("Action")
  valid_595251 = validateParameter(valid_595251, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_595251 != nil:
    section.add "Action", valid_595251
  var valid_595252 = query.getOrDefault("Version")
  valid_595252 = validateParameter(valid_595252, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595252 != nil:
    section.add "Version", valid_595252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595253 = header.getOrDefault("X-Amz-Date")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Date", valid_595253
  var valid_595254 = header.getOrDefault("X-Amz-Security-Token")
  valid_595254 = validateParameter(valid_595254, JString, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "X-Amz-Security-Token", valid_595254
  var valid_595255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "X-Amz-Content-Sha256", valid_595255
  var valid_595256 = header.getOrDefault("X-Amz-Algorithm")
  valid_595256 = validateParameter(valid_595256, JString, required = false,
                                 default = nil)
  if valid_595256 != nil:
    section.add "X-Amz-Algorithm", valid_595256
  var valid_595257 = header.getOrDefault("X-Amz-Signature")
  valid_595257 = validateParameter(valid_595257, JString, required = false,
                                 default = nil)
  if valid_595257 != nil:
    section.add "X-Amz-Signature", valid_595257
  var valid_595258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595258 = validateParameter(valid_595258, JString, required = false,
                                 default = nil)
  if valid_595258 != nil:
    section.add "X-Amz-SignedHeaders", valid_595258
  var valid_595259 = header.getOrDefault("X-Amz-Credential")
  valid_595259 = validateParameter(valid_595259, JString, required = false,
                                 default = nil)
  if valid_595259 != nil:
    section.add "X-Amz-Credential", valid_595259
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray (required)
  ##             : A list of parameters in the DB cluster parameter group to modify.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Parameters` field"
  var valid_595260 = formData.getOrDefault("Parameters")
  valid_595260 = validateParameter(valid_595260, JArray, required = true, default = nil)
  if valid_595260 != nil:
    section.add "Parameters", valid_595260
  var valid_595261 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_595261 = validateParameter(valid_595261, JString, required = true,
                                 default = nil)
  if valid_595261 != nil:
    section.add "DBClusterParameterGroupName", valid_595261
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595262: Call_PostModifyDBClusterParameterGroup_595248;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_595262.validator(path, query, header, formData, body)
  let scheme = call_595262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595262.url(scheme.get, call_595262.host, call_595262.base,
                         call_595262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595262, url, valid)

proc call*(call_595263: Call_PostModifyDBClusterParameterGroup_595248;
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
  var query_595264 = newJObject()
  var formData_595265 = newJObject()
  if Parameters != nil:
    formData_595265.add "Parameters", Parameters
  add(query_595264, "Action", newJString(Action))
  add(formData_595265, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(query_595264, "Version", newJString(Version))
  result = call_595263.call(nil, query_595264, nil, formData_595265, nil)

var postModifyDBClusterParameterGroup* = Call_PostModifyDBClusterParameterGroup_595248(
    name: "postModifyDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_PostModifyDBClusterParameterGroup_595249, base: "/",
    url: url_PostModifyDBClusterParameterGroup_595250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterParameterGroup_595231 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBClusterParameterGroup_595233(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBClusterParameterGroup_595232(path: JsonNode;
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
  var valid_595234 = query.getOrDefault("DBClusterParameterGroupName")
  valid_595234 = validateParameter(valid_595234, JString, required = true,
                                 default = nil)
  if valid_595234 != nil:
    section.add "DBClusterParameterGroupName", valid_595234
  var valid_595235 = query.getOrDefault("Parameters")
  valid_595235 = validateParameter(valid_595235, JArray, required = true, default = nil)
  if valid_595235 != nil:
    section.add "Parameters", valid_595235
  var valid_595236 = query.getOrDefault("Action")
  valid_595236 = validateParameter(valid_595236, JString, required = true, default = newJString(
      "ModifyDBClusterParameterGroup"))
  if valid_595236 != nil:
    section.add "Action", valid_595236
  var valid_595237 = query.getOrDefault("Version")
  valid_595237 = validateParameter(valid_595237, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595237 != nil:
    section.add "Version", valid_595237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595238 = header.getOrDefault("X-Amz-Date")
  valid_595238 = validateParameter(valid_595238, JString, required = false,
                                 default = nil)
  if valid_595238 != nil:
    section.add "X-Amz-Date", valid_595238
  var valid_595239 = header.getOrDefault("X-Amz-Security-Token")
  valid_595239 = validateParameter(valid_595239, JString, required = false,
                                 default = nil)
  if valid_595239 != nil:
    section.add "X-Amz-Security-Token", valid_595239
  var valid_595240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595240 = validateParameter(valid_595240, JString, required = false,
                                 default = nil)
  if valid_595240 != nil:
    section.add "X-Amz-Content-Sha256", valid_595240
  var valid_595241 = header.getOrDefault("X-Amz-Algorithm")
  valid_595241 = validateParameter(valid_595241, JString, required = false,
                                 default = nil)
  if valid_595241 != nil:
    section.add "X-Amz-Algorithm", valid_595241
  var valid_595242 = header.getOrDefault("X-Amz-Signature")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "X-Amz-Signature", valid_595242
  var valid_595243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595243 = validateParameter(valid_595243, JString, required = false,
                                 default = nil)
  if valid_595243 != nil:
    section.add "X-Amz-SignedHeaders", valid_595243
  var valid_595244 = header.getOrDefault("X-Amz-Credential")
  valid_595244 = validateParameter(valid_595244, JString, required = false,
                                 default = nil)
  if valid_595244 != nil:
    section.add "X-Amz-Credential", valid_595244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595245: Call_GetModifyDBClusterParameterGroup_595231;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: <code>ParameterName</code>, <code>ParameterValue</code>, and <code>ApplyMethod</code>. A maximum of 20 parameters can be modified in a single request. </p> <note> <p>Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot or maintenance window before the change can take effect.</p> </note> <important> <p>After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon DocumentDB to fully complete the create action before the parameter group is used as the default for a new DB cluster. This step is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the <code>character_set_database</code> parameter.</p> </important>
  ## 
  let valid = call_595245.validator(path, query, header, formData, body)
  let scheme = call_595245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595245.url(scheme.get, call_595245.host, call_595245.base,
                         call_595245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595245, url, valid)

proc call*(call_595246: Call_GetModifyDBClusterParameterGroup_595231;
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
  var query_595247 = newJObject()
  add(query_595247, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_595247.add "Parameters", Parameters
  add(query_595247, "Action", newJString(Action))
  add(query_595247, "Version", newJString(Version))
  result = call_595246.call(nil, query_595247, nil, nil, nil)

var getModifyDBClusterParameterGroup* = Call_GetModifyDBClusterParameterGroup_595231(
    name: "getModifyDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterParameterGroup",
    validator: validate_GetModifyDBClusterParameterGroup_595232, base: "/",
    url: url_GetModifyDBClusterParameterGroup_595233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBClusterSnapshotAttribute_595285 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBClusterSnapshotAttribute_595287(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBClusterSnapshotAttribute_595286(path: JsonNode;
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
  var valid_595288 = query.getOrDefault("Action")
  valid_595288 = validateParameter(valid_595288, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_595288 != nil:
    section.add "Action", valid_595288
  var valid_595289 = query.getOrDefault("Version")
  valid_595289 = validateParameter(valid_595289, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595289 != nil:
    section.add "Version", valid_595289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595290 = header.getOrDefault("X-Amz-Date")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "X-Amz-Date", valid_595290
  var valid_595291 = header.getOrDefault("X-Amz-Security-Token")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "X-Amz-Security-Token", valid_595291
  var valid_595292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595292 = validateParameter(valid_595292, JString, required = false,
                                 default = nil)
  if valid_595292 != nil:
    section.add "X-Amz-Content-Sha256", valid_595292
  var valid_595293 = header.getOrDefault("X-Amz-Algorithm")
  valid_595293 = validateParameter(valid_595293, JString, required = false,
                                 default = nil)
  if valid_595293 != nil:
    section.add "X-Amz-Algorithm", valid_595293
  var valid_595294 = header.getOrDefault("X-Amz-Signature")
  valid_595294 = validateParameter(valid_595294, JString, required = false,
                                 default = nil)
  if valid_595294 != nil:
    section.add "X-Amz-Signature", valid_595294
  var valid_595295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595295 = validateParameter(valid_595295, JString, required = false,
                                 default = nil)
  if valid_595295 != nil:
    section.add "X-Amz-SignedHeaders", valid_595295
  var valid_595296 = header.getOrDefault("X-Amz-Credential")
  valid_595296 = validateParameter(valid_595296, JString, required = false,
                                 default = nil)
  if valid_595296 != nil:
    section.add "X-Amz-Credential", valid_595296
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
  var valid_595297 = formData.getOrDefault("AttributeName")
  valid_595297 = validateParameter(valid_595297, JString, required = true,
                                 default = nil)
  if valid_595297 != nil:
    section.add "AttributeName", valid_595297
  var valid_595298 = formData.getOrDefault("DBClusterSnapshotIdentifier")
  valid_595298 = validateParameter(valid_595298, JString, required = true,
                                 default = nil)
  if valid_595298 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_595298
  var valid_595299 = formData.getOrDefault("ValuesToRemove")
  valid_595299 = validateParameter(valid_595299, JArray, required = false,
                                 default = nil)
  if valid_595299 != nil:
    section.add "ValuesToRemove", valid_595299
  var valid_595300 = formData.getOrDefault("ValuesToAdd")
  valid_595300 = validateParameter(valid_595300, JArray, required = false,
                                 default = nil)
  if valid_595300 != nil:
    section.add "ValuesToAdd", valid_595300
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595301: Call_PostModifyDBClusterSnapshotAttribute_595285;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_595301.validator(path, query, header, formData, body)
  let scheme = call_595301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595301.url(scheme.get, call_595301.host, call_595301.base,
                         call_595301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595301, url, valid)

proc call*(call_595302: Call_PostModifyDBClusterSnapshotAttribute_595285;
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
  var query_595303 = newJObject()
  var formData_595304 = newJObject()
  add(formData_595304, "AttributeName", newJString(AttributeName))
  add(formData_595304, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  add(query_595303, "Action", newJString(Action))
  if ValuesToRemove != nil:
    formData_595304.add "ValuesToRemove", ValuesToRemove
  if ValuesToAdd != nil:
    formData_595304.add "ValuesToAdd", ValuesToAdd
  add(query_595303, "Version", newJString(Version))
  result = call_595302.call(nil, query_595303, nil, formData_595304, nil)

var postModifyDBClusterSnapshotAttribute* = Call_PostModifyDBClusterSnapshotAttribute_595285(
    name: "postModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_PostModifyDBClusterSnapshotAttribute_595286, base: "/",
    url: url_PostModifyDBClusterSnapshotAttribute_595287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBClusterSnapshotAttribute_595266 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBClusterSnapshotAttribute_595268(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBClusterSnapshotAttribute_595267(path: JsonNode;
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
  var valid_595269 = query.getOrDefault("AttributeName")
  valid_595269 = validateParameter(valid_595269, JString, required = true,
                                 default = nil)
  if valid_595269 != nil:
    section.add "AttributeName", valid_595269
  var valid_595270 = query.getOrDefault("DBClusterSnapshotIdentifier")
  valid_595270 = validateParameter(valid_595270, JString, required = true,
                                 default = nil)
  if valid_595270 != nil:
    section.add "DBClusterSnapshotIdentifier", valid_595270
  var valid_595271 = query.getOrDefault("ValuesToAdd")
  valid_595271 = validateParameter(valid_595271, JArray, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "ValuesToAdd", valid_595271
  var valid_595272 = query.getOrDefault("Action")
  valid_595272 = validateParameter(valid_595272, JString, required = true, default = newJString(
      "ModifyDBClusterSnapshotAttribute"))
  if valid_595272 != nil:
    section.add "Action", valid_595272
  var valid_595273 = query.getOrDefault("ValuesToRemove")
  valid_595273 = validateParameter(valid_595273, JArray, required = false,
                                 default = nil)
  if valid_595273 != nil:
    section.add "ValuesToRemove", valid_595273
  var valid_595274 = query.getOrDefault("Version")
  valid_595274 = validateParameter(valid_595274, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595274 != nil:
    section.add "Version", valid_595274
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595275 = header.getOrDefault("X-Amz-Date")
  valid_595275 = validateParameter(valid_595275, JString, required = false,
                                 default = nil)
  if valid_595275 != nil:
    section.add "X-Amz-Date", valid_595275
  var valid_595276 = header.getOrDefault("X-Amz-Security-Token")
  valid_595276 = validateParameter(valid_595276, JString, required = false,
                                 default = nil)
  if valid_595276 != nil:
    section.add "X-Amz-Security-Token", valid_595276
  var valid_595277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595277 = validateParameter(valid_595277, JString, required = false,
                                 default = nil)
  if valid_595277 != nil:
    section.add "X-Amz-Content-Sha256", valid_595277
  var valid_595278 = header.getOrDefault("X-Amz-Algorithm")
  valid_595278 = validateParameter(valid_595278, JString, required = false,
                                 default = nil)
  if valid_595278 != nil:
    section.add "X-Amz-Algorithm", valid_595278
  var valid_595279 = header.getOrDefault("X-Amz-Signature")
  valid_595279 = validateParameter(valid_595279, JString, required = false,
                                 default = nil)
  if valid_595279 != nil:
    section.add "X-Amz-Signature", valid_595279
  var valid_595280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595280 = validateParameter(valid_595280, JString, required = false,
                                 default = nil)
  if valid_595280 != nil:
    section.add "X-Amz-SignedHeaders", valid_595280
  var valid_595281 = header.getOrDefault("X-Amz-Credential")
  valid_595281 = validateParameter(valid_595281, JString, required = false,
                                 default = nil)
  if valid_595281 != nil:
    section.add "X-Amz-Credential", valid_595281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595282: Call_GetModifyDBClusterSnapshotAttribute_595266;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot.</p> <p>To share a manual DB cluster snapshot with other AWS accounts, specify <code>restore</code> as the <code>AttributeName</code>, and use the <code>ValuesToAdd</code> parameter to add a list of IDs of the AWS accounts that are authorized to restore the manual DB cluster snapshot. Use the value <code>all</code> to make the manual DB cluster snapshot public, which means that it can be copied or restored by all AWS accounts. Do not add the <code>all</code> value for any manual DB cluster snapshots that contain private information that you don't want available to all AWS accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized AWS account IDs for the <code>ValuesToAdd</code> parameter. You can't use <code>all</code> as a value for that parameter in this case.</p>
  ## 
  let valid = call_595282.validator(path, query, header, formData, body)
  let scheme = call_595282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595282.url(scheme.get, call_595282.host, call_595282.base,
                         call_595282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595282, url, valid)

proc call*(call_595283: Call_GetModifyDBClusterSnapshotAttribute_595266;
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
  var query_595284 = newJObject()
  add(query_595284, "AttributeName", newJString(AttributeName))
  add(query_595284, "DBClusterSnapshotIdentifier",
      newJString(DBClusterSnapshotIdentifier))
  if ValuesToAdd != nil:
    query_595284.add "ValuesToAdd", ValuesToAdd
  add(query_595284, "Action", newJString(Action))
  if ValuesToRemove != nil:
    query_595284.add "ValuesToRemove", ValuesToRemove
  add(query_595284, "Version", newJString(Version))
  result = call_595283.call(nil, query_595284, nil, nil, nil)

var getModifyDBClusterSnapshotAttribute* = Call_GetModifyDBClusterSnapshotAttribute_595266(
    name: "getModifyDBClusterSnapshotAttribute", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBClusterSnapshotAttribute",
    validator: validate_GetModifyDBClusterSnapshotAttribute_595267, base: "/",
    url: url_GetModifyDBClusterSnapshotAttribute_595268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_595327 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBInstance_595329(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_595328(path: JsonNode; query: JsonNode;
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
  var valid_595330 = query.getOrDefault("Action")
  valid_595330 = validateParameter(valid_595330, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595330 != nil:
    section.add "Action", valid_595330
  var valid_595331 = query.getOrDefault("Version")
  valid_595331 = validateParameter(valid_595331, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595331 != nil:
    section.add "Version", valid_595331
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595332 = header.getOrDefault("X-Amz-Date")
  valid_595332 = validateParameter(valid_595332, JString, required = false,
                                 default = nil)
  if valid_595332 != nil:
    section.add "X-Amz-Date", valid_595332
  var valid_595333 = header.getOrDefault("X-Amz-Security-Token")
  valid_595333 = validateParameter(valid_595333, JString, required = false,
                                 default = nil)
  if valid_595333 != nil:
    section.add "X-Amz-Security-Token", valid_595333
  var valid_595334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595334 = validateParameter(valid_595334, JString, required = false,
                                 default = nil)
  if valid_595334 != nil:
    section.add "X-Amz-Content-Sha256", valid_595334
  var valid_595335 = header.getOrDefault("X-Amz-Algorithm")
  valid_595335 = validateParameter(valid_595335, JString, required = false,
                                 default = nil)
  if valid_595335 != nil:
    section.add "X-Amz-Algorithm", valid_595335
  var valid_595336 = header.getOrDefault("X-Amz-Signature")
  valid_595336 = validateParameter(valid_595336, JString, required = false,
                                 default = nil)
  if valid_595336 != nil:
    section.add "X-Amz-Signature", valid_595336
  var valid_595337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595337 = validateParameter(valid_595337, JString, required = false,
                                 default = nil)
  if valid_595337 != nil:
    section.add "X-Amz-SignedHeaders", valid_595337
  var valid_595338 = header.getOrDefault("X-Amz-Credential")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "X-Amz-Credential", valid_595338
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplyImmediately: JBool
  ##                   : <p>Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the <code>PreferredMaintenanceWindow</code> setting for the DB instance. </p> <p> If this parameter is set to <code>false</code>, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next reboot.</p> <p>Default: <code>false</code> </p>
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This value is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
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
  var valid_595339 = formData.getOrDefault("ApplyImmediately")
  valid_595339 = validateParameter(valid_595339, JBool, required = false, default = nil)
  if valid_595339 != nil:
    section.add "ApplyImmediately", valid_595339
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595340 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595340 = validateParameter(valid_595340, JString, required = true,
                                 default = nil)
  if valid_595340 != nil:
    section.add "DBInstanceIdentifier", valid_595340
  var valid_595341 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_595341 = validateParameter(valid_595341, JString, required = false,
                                 default = nil)
  if valid_595341 != nil:
    section.add "NewDBInstanceIdentifier", valid_595341
  var valid_595342 = formData.getOrDefault("PromotionTier")
  valid_595342 = validateParameter(valid_595342, JInt, required = false, default = nil)
  if valid_595342 != nil:
    section.add "PromotionTier", valid_595342
  var valid_595343 = formData.getOrDefault("DBInstanceClass")
  valid_595343 = validateParameter(valid_595343, JString, required = false,
                                 default = nil)
  if valid_595343 != nil:
    section.add "DBInstanceClass", valid_595343
  var valid_595344 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_595344 = validateParameter(valid_595344, JBool, required = false, default = nil)
  if valid_595344 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595344
  var valid_595345 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_595345 = validateParameter(valid_595345, JString, required = false,
                                 default = nil)
  if valid_595345 != nil:
    section.add "PreferredMaintenanceWindow", valid_595345
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595346: Call_PostModifyDBInstance_595327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_595346.validator(path, query, header, formData, body)
  let scheme = call_595346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595346.url(scheme.get, call_595346.host, call_595346.base,
                         call_595346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595346, url, valid)

proc call*(call_595347: Call_PostModifyDBInstance_595327;
          DBInstanceIdentifier: string; ApplyImmediately: bool = false;
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
  var query_595348 = newJObject()
  var formData_595349 = newJObject()
  add(formData_595349, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_595349, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_595349, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_595348, "Action", newJString(Action))
  add(formData_595349, "PromotionTier", newJInt(PromotionTier))
  add(formData_595349, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_595349, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_595348, "Version", newJString(Version))
  add(formData_595349, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_595347.call(nil, query_595348, nil, formData_595349, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_595327(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_595328, base: "/",
    url: url_PostModifyDBInstance_595329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_595305 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBInstance_595307(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_595306(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
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
  var valid_595308 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_595308 = validateParameter(valid_595308, JString, required = false,
                                 default = nil)
  if valid_595308 != nil:
    section.add "PreferredMaintenanceWindow", valid_595308
  var valid_595309 = query.getOrDefault("PromotionTier")
  valid_595309 = validateParameter(valid_595309, JInt, required = false, default = nil)
  if valid_595309 != nil:
    section.add "PromotionTier", valid_595309
  var valid_595310 = query.getOrDefault("DBInstanceClass")
  valid_595310 = validateParameter(valid_595310, JString, required = false,
                                 default = nil)
  if valid_595310 != nil:
    section.add "DBInstanceClass", valid_595310
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595311 = query.getOrDefault("Action")
  valid_595311 = validateParameter(valid_595311, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_595311 != nil:
    section.add "Action", valid_595311
  var valid_595312 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_595312 = validateParameter(valid_595312, JString, required = false,
                                 default = nil)
  if valid_595312 != nil:
    section.add "NewDBInstanceIdentifier", valid_595312
  var valid_595313 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_595313 = validateParameter(valid_595313, JBool, required = false, default = nil)
  if valid_595313 != nil:
    section.add "AutoMinorVersionUpgrade", valid_595313
  var valid_595314 = query.getOrDefault("Version")
  valid_595314 = validateParameter(valid_595314, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595314 != nil:
    section.add "Version", valid_595314
  var valid_595315 = query.getOrDefault("DBInstanceIdentifier")
  valid_595315 = validateParameter(valid_595315, JString, required = true,
                                 default = nil)
  if valid_595315 != nil:
    section.add "DBInstanceIdentifier", valid_595315
  var valid_595316 = query.getOrDefault("ApplyImmediately")
  valid_595316 = validateParameter(valid_595316, JBool, required = false, default = nil)
  if valid_595316 != nil:
    section.add "ApplyImmediately", valid_595316
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595317 = header.getOrDefault("X-Amz-Date")
  valid_595317 = validateParameter(valid_595317, JString, required = false,
                                 default = nil)
  if valid_595317 != nil:
    section.add "X-Amz-Date", valid_595317
  var valid_595318 = header.getOrDefault("X-Amz-Security-Token")
  valid_595318 = validateParameter(valid_595318, JString, required = false,
                                 default = nil)
  if valid_595318 != nil:
    section.add "X-Amz-Security-Token", valid_595318
  var valid_595319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595319 = validateParameter(valid_595319, JString, required = false,
                                 default = nil)
  if valid_595319 != nil:
    section.add "X-Amz-Content-Sha256", valid_595319
  var valid_595320 = header.getOrDefault("X-Amz-Algorithm")
  valid_595320 = validateParameter(valid_595320, JString, required = false,
                                 default = nil)
  if valid_595320 != nil:
    section.add "X-Amz-Algorithm", valid_595320
  var valid_595321 = header.getOrDefault("X-Amz-Signature")
  valid_595321 = validateParameter(valid_595321, JString, required = false,
                                 default = nil)
  if valid_595321 != nil:
    section.add "X-Amz-Signature", valid_595321
  var valid_595322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595322 = validateParameter(valid_595322, JString, required = false,
                                 default = nil)
  if valid_595322 != nil:
    section.add "X-Amz-SignedHeaders", valid_595322
  var valid_595323 = header.getOrDefault("X-Amz-Credential")
  valid_595323 = validateParameter(valid_595323, JString, required = false,
                                 default = nil)
  if valid_595323 != nil:
    section.add "X-Amz-Credential", valid_595323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595324: Call_GetModifyDBInstance_595305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
  ## 
  let valid = call_595324.validator(path, query, header, formData, body)
  let scheme = call_595324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595324.url(scheme.get, call_595324.host, call_595324.base,
                         call_595324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595324, url, valid)

proc call*(call_595325: Call_GetModifyDBInstance_595305;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          PromotionTier: int = 0; DBInstanceClass: string = "";
          Action: string = "ModifyDBInstance"; NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-10-31";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBInstance
  ## Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
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
  var query_595326 = newJObject()
  add(query_595326, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_595326, "PromotionTier", newJInt(PromotionTier))
  add(query_595326, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_595326, "Action", newJString(Action))
  add(query_595326, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_595326, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_595326, "Version", newJString(Version))
  add(query_595326, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595326, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_595325.call(nil, query_595326, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_595305(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_595306, base: "/",
    url: url_GetModifyDBInstance_595307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_595368 = ref object of OpenApiRestCall_593421
proc url_PostModifyDBSubnetGroup_595370(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_595369(path: JsonNode; query: JsonNode;
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
  var valid_595371 = query.getOrDefault("Action")
  valid_595371 = validateParameter(valid_595371, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595371 != nil:
    section.add "Action", valid_595371
  var valid_595372 = query.getOrDefault("Version")
  valid_595372 = validateParameter(valid_595372, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595372 != nil:
    section.add "Version", valid_595372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595373 = header.getOrDefault("X-Amz-Date")
  valid_595373 = validateParameter(valid_595373, JString, required = false,
                                 default = nil)
  if valid_595373 != nil:
    section.add "X-Amz-Date", valid_595373
  var valid_595374 = header.getOrDefault("X-Amz-Security-Token")
  valid_595374 = validateParameter(valid_595374, JString, required = false,
                                 default = nil)
  if valid_595374 != nil:
    section.add "X-Amz-Security-Token", valid_595374
  var valid_595375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595375 = validateParameter(valid_595375, JString, required = false,
                                 default = nil)
  if valid_595375 != nil:
    section.add "X-Amz-Content-Sha256", valid_595375
  var valid_595376 = header.getOrDefault("X-Amz-Algorithm")
  valid_595376 = validateParameter(valid_595376, JString, required = false,
                                 default = nil)
  if valid_595376 != nil:
    section.add "X-Amz-Algorithm", valid_595376
  var valid_595377 = header.getOrDefault("X-Amz-Signature")
  valid_595377 = validateParameter(valid_595377, JString, required = false,
                                 default = nil)
  if valid_595377 != nil:
    section.add "X-Amz-Signature", valid_595377
  var valid_595378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595378 = validateParameter(valid_595378, JString, required = false,
                                 default = nil)
  if valid_595378 != nil:
    section.add "X-Amz-SignedHeaders", valid_595378
  var valid_595379 = header.getOrDefault("X-Amz-Credential")
  valid_595379 = validateParameter(valid_595379, JString, required = false,
                                 default = nil)
  if valid_595379 != nil:
    section.add "X-Amz-Credential", valid_595379
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
  var valid_595380 = formData.getOrDefault("DBSubnetGroupName")
  valid_595380 = validateParameter(valid_595380, JString, required = true,
                                 default = nil)
  if valid_595380 != nil:
    section.add "DBSubnetGroupName", valid_595380
  var valid_595381 = formData.getOrDefault("SubnetIds")
  valid_595381 = validateParameter(valid_595381, JArray, required = true, default = nil)
  if valid_595381 != nil:
    section.add "SubnetIds", valid_595381
  var valid_595382 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_595382 = validateParameter(valid_595382, JString, required = false,
                                 default = nil)
  if valid_595382 != nil:
    section.add "DBSubnetGroupDescription", valid_595382
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595383: Call_PostModifyDBSubnetGroup_595368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_595383.validator(path, query, header, formData, body)
  let scheme = call_595383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595383.url(scheme.get, call_595383.host, call_595383.base,
                         call_595383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595383, url, valid)

proc call*(call_595384: Call_PostModifyDBSubnetGroup_595368;
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
  var query_595385 = newJObject()
  var formData_595386 = newJObject()
  add(formData_595386, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_595386.add "SubnetIds", SubnetIds
  add(query_595385, "Action", newJString(Action))
  add(formData_595386, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595385, "Version", newJString(Version))
  result = call_595384.call(nil, query_595385, nil, formData_595386, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_595368(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_595369, base: "/",
    url: url_PostModifyDBSubnetGroup_595370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_595350 = ref object of OpenApiRestCall_593421
proc url_GetModifyDBSubnetGroup_595352(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_595351(path: JsonNode; query: JsonNode;
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
  var valid_595353 = query.getOrDefault("Action")
  valid_595353 = validateParameter(valid_595353, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_595353 != nil:
    section.add "Action", valid_595353
  var valid_595354 = query.getOrDefault("DBSubnetGroupName")
  valid_595354 = validateParameter(valid_595354, JString, required = true,
                                 default = nil)
  if valid_595354 != nil:
    section.add "DBSubnetGroupName", valid_595354
  var valid_595355 = query.getOrDefault("SubnetIds")
  valid_595355 = validateParameter(valid_595355, JArray, required = true, default = nil)
  if valid_595355 != nil:
    section.add "SubnetIds", valid_595355
  var valid_595356 = query.getOrDefault("DBSubnetGroupDescription")
  valid_595356 = validateParameter(valid_595356, JString, required = false,
                                 default = nil)
  if valid_595356 != nil:
    section.add "DBSubnetGroupDescription", valid_595356
  var valid_595357 = query.getOrDefault("Version")
  valid_595357 = validateParameter(valid_595357, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595357 != nil:
    section.add "Version", valid_595357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595358 = header.getOrDefault("X-Amz-Date")
  valid_595358 = validateParameter(valid_595358, JString, required = false,
                                 default = nil)
  if valid_595358 != nil:
    section.add "X-Amz-Date", valid_595358
  var valid_595359 = header.getOrDefault("X-Amz-Security-Token")
  valid_595359 = validateParameter(valid_595359, JString, required = false,
                                 default = nil)
  if valid_595359 != nil:
    section.add "X-Amz-Security-Token", valid_595359
  var valid_595360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595360 = validateParameter(valid_595360, JString, required = false,
                                 default = nil)
  if valid_595360 != nil:
    section.add "X-Amz-Content-Sha256", valid_595360
  var valid_595361 = header.getOrDefault("X-Amz-Algorithm")
  valid_595361 = validateParameter(valid_595361, JString, required = false,
                                 default = nil)
  if valid_595361 != nil:
    section.add "X-Amz-Algorithm", valid_595361
  var valid_595362 = header.getOrDefault("X-Amz-Signature")
  valid_595362 = validateParameter(valid_595362, JString, required = false,
                                 default = nil)
  if valid_595362 != nil:
    section.add "X-Amz-Signature", valid_595362
  var valid_595363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595363 = validateParameter(valid_595363, JString, required = false,
                                 default = nil)
  if valid_595363 != nil:
    section.add "X-Amz-SignedHeaders", valid_595363
  var valid_595364 = header.getOrDefault("X-Amz-Credential")
  valid_595364 = validateParameter(valid_595364, JString, required = false,
                                 default = nil)
  if valid_595364 != nil:
    section.add "X-Amz-Credential", valid_595364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595365: Call_GetModifyDBSubnetGroup_595350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two Availability Zones in the AWS Region.
  ## 
  let valid = call_595365.validator(path, query, header, formData, body)
  let scheme = call_595365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595365.url(scheme.get, call_595365.host, call_595365.base,
                         call_595365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595365, url, valid)

proc call*(call_595366: Call_GetModifyDBSubnetGroup_595350;
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
  var query_595367 = newJObject()
  add(query_595367, "Action", newJString(Action))
  add(query_595367, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_595367.add "SubnetIds", SubnetIds
  add(query_595367, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_595367, "Version", newJString(Version))
  result = call_595366.call(nil, query_595367, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_595350(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_595351, base: "/",
    url: url_GetModifyDBSubnetGroup_595352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_595404 = ref object of OpenApiRestCall_593421
proc url_PostRebootDBInstance_595406(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_595405(path: JsonNode; query: JsonNode;
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
  var valid_595407 = query.getOrDefault("Action")
  valid_595407 = validateParameter(valid_595407, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595407 != nil:
    section.add "Action", valid_595407
  var valid_595408 = query.getOrDefault("Version")
  valid_595408 = validateParameter(valid_595408, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595408 != nil:
    section.add "Version", valid_595408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595409 = header.getOrDefault("X-Amz-Date")
  valid_595409 = validateParameter(valid_595409, JString, required = false,
                                 default = nil)
  if valid_595409 != nil:
    section.add "X-Amz-Date", valid_595409
  var valid_595410 = header.getOrDefault("X-Amz-Security-Token")
  valid_595410 = validateParameter(valid_595410, JString, required = false,
                                 default = nil)
  if valid_595410 != nil:
    section.add "X-Amz-Security-Token", valid_595410
  var valid_595411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595411 = validateParameter(valid_595411, JString, required = false,
                                 default = nil)
  if valid_595411 != nil:
    section.add "X-Amz-Content-Sha256", valid_595411
  var valid_595412 = header.getOrDefault("X-Amz-Algorithm")
  valid_595412 = validateParameter(valid_595412, JString, required = false,
                                 default = nil)
  if valid_595412 != nil:
    section.add "X-Amz-Algorithm", valid_595412
  var valid_595413 = header.getOrDefault("X-Amz-Signature")
  valid_595413 = validateParameter(valid_595413, JString, required = false,
                                 default = nil)
  if valid_595413 != nil:
    section.add "X-Amz-Signature", valid_595413
  var valid_595414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595414 = validateParameter(valid_595414, JString, required = false,
                                 default = nil)
  if valid_595414 != nil:
    section.add "X-Amz-SignedHeaders", valid_595414
  var valid_595415 = header.getOrDefault("X-Amz-Credential")
  valid_595415 = validateParameter(valid_595415, JString, required = false,
                                 default = nil)
  if valid_595415 != nil:
    section.add "X-Amz-Credential", valid_595415
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##                       : <p>The DB instance identifier. This parameter is stored as a lowercase string.</p> <p>Constraints:</p> <ul> <li> <p>Must match the identifier of an existing <code>DBInstance</code>.</p> </li> </ul>
  ##   ForceFailover: JBool
  ##                : <p> When <code>true</code>, the reboot is conducted through a Multi-AZ failover. </p> <p>Constraint: You can't specify <code>true</code> if the instance is not configured for Multi-AZ.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_595416 = formData.getOrDefault("DBInstanceIdentifier")
  valid_595416 = validateParameter(valid_595416, JString, required = true,
                                 default = nil)
  if valid_595416 != nil:
    section.add "DBInstanceIdentifier", valid_595416
  var valid_595417 = formData.getOrDefault("ForceFailover")
  valid_595417 = validateParameter(valid_595417, JBool, required = false, default = nil)
  if valid_595417 != nil:
    section.add "ForceFailover", valid_595417
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595418: Call_PostRebootDBInstance_595404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_595418.validator(path, query, header, formData, body)
  let scheme = call_595418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595418.url(scheme.get, call_595418.host, call_595418.base,
                         call_595418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595418, url, valid)

proc call*(call_595419: Call_PostRebootDBInstance_595404;
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
  var query_595420 = newJObject()
  var formData_595421 = newJObject()
  add(formData_595421, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_595420, "Action", newJString(Action))
  add(formData_595421, "ForceFailover", newJBool(ForceFailover))
  add(query_595420, "Version", newJString(Version))
  result = call_595419.call(nil, query_595420, nil, formData_595421, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_595404(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_595405, base: "/",
    url: url_PostRebootDBInstance_595406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_595387 = ref object of OpenApiRestCall_593421
proc url_GetRebootDBInstance_595389(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_595388(path: JsonNode; query: JsonNode;
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
  var valid_595390 = query.getOrDefault("Action")
  valid_595390 = validateParameter(valid_595390, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_595390 != nil:
    section.add "Action", valid_595390
  var valid_595391 = query.getOrDefault("ForceFailover")
  valid_595391 = validateParameter(valid_595391, JBool, required = false, default = nil)
  if valid_595391 != nil:
    section.add "ForceFailover", valid_595391
  var valid_595392 = query.getOrDefault("Version")
  valid_595392 = validateParameter(valid_595392, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595392 != nil:
    section.add "Version", valid_595392
  var valid_595393 = query.getOrDefault("DBInstanceIdentifier")
  valid_595393 = validateParameter(valid_595393, JString, required = true,
                                 default = nil)
  if valid_595393 != nil:
    section.add "DBInstanceIdentifier", valid_595393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595394 = header.getOrDefault("X-Amz-Date")
  valid_595394 = validateParameter(valid_595394, JString, required = false,
                                 default = nil)
  if valid_595394 != nil:
    section.add "X-Amz-Date", valid_595394
  var valid_595395 = header.getOrDefault("X-Amz-Security-Token")
  valid_595395 = validateParameter(valid_595395, JString, required = false,
                                 default = nil)
  if valid_595395 != nil:
    section.add "X-Amz-Security-Token", valid_595395
  var valid_595396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595396 = validateParameter(valid_595396, JString, required = false,
                                 default = nil)
  if valid_595396 != nil:
    section.add "X-Amz-Content-Sha256", valid_595396
  var valid_595397 = header.getOrDefault("X-Amz-Algorithm")
  valid_595397 = validateParameter(valid_595397, JString, required = false,
                                 default = nil)
  if valid_595397 != nil:
    section.add "X-Amz-Algorithm", valid_595397
  var valid_595398 = header.getOrDefault("X-Amz-Signature")
  valid_595398 = validateParameter(valid_595398, JString, required = false,
                                 default = nil)
  if valid_595398 != nil:
    section.add "X-Amz-Signature", valid_595398
  var valid_595399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595399 = validateParameter(valid_595399, JString, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "X-Amz-SignedHeaders", valid_595399
  var valid_595400 = header.getOrDefault("X-Amz-Credential")
  valid_595400 = validateParameter(valid_595400, JString, required = false,
                                 default = nil)
  if valid_595400 != nil:
    section.add "X-Amz-Credential", valid_595400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595401: Call_GetRebootDBInstance_595387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain changes, or if you change the DB cluster parameter group that is associated with the DB instance, you must reboot the instance for the changes to take effect. </p> <p>Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to <i>rebooting</i>. </p>
  ## 
  let valid = call_595401.validator(path, query, header, formData, body)
  let scheme = call_595401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595401.url(scheme.get, call_595401.host, call_595401.base,
                         call_595401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595401, url, valid)

proc call*(call_595402: Call_GetRebootDBInstance_595387;
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
  var query_595403 = newJObject()
  add(query_595403, "Action", newJString(Action))
  add(query_595403, "ForceFailover", newJBool(ForceFailover))
  add(query_595403, "Version", newJString(Version))
  add(query_595403, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_595402.call(nil, query_595403, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_595387(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_595388, base: "/",
    url: url_GetRebootDBInstance_595389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_595439 = ref object of OpenApiRestCall_593421
proc url_PostRemoveTagsFromResource_595441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_595440(path: JsonNode; query: JsonNode;
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
  var valid_595442 = query.getOrDefault("Action")
  valid_595442 = validateParameter(valid_595442, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_595442 != nil:
    section.add "Action", valid_595442
  var valid_595443 = query.getOrDefault("Version")
  valid_595443 = validateParameter(valid_595443, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595443 != nil:
    section.add "Version", valid_595443
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595444 = header.getOrDefault("X-Amz-Date")
  valid_595444 = validateParameter(valid_595444, JString, required = false,
                                 default = nil)
  if valid_595444 != nil:
    section.add "X-Amz-Date", valid_595444
  var valid_595445 = header.getOrDefault("X-Amz-Security-Token")
  valid_595445 = validateParameter(valid_595445, JString, required = false,
                                 default = nil)
  if valid_595445 != nil:
    section.add "X-Amz-Security-Token", valid_595445
  var valid_595446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595446 = validateParameter(valid_595446, JString, required = false,
                                 default = nil)
  if valid_595446 != nil:
    section.add "X-Amz-Content-Sha256", valid_595446
  var valid_595447 = header.getOrDefault("X-Amz-Algorithm")
  valid_595447 = validateParameter(valid_595447, JString, required = false,
                                 default = nil)
  if valid_595447 != nil:
    section.add "X-Amz-Algorithm", valid_595447
  var valid_595448 = header.getOrDefault("X-Amz-Signature")
  valid_595448 = validateParameter(valid_595448, JString, required = false,
                                 default = nil)
  if valid_595448 != nil:
    section.add "X-Amz-Signature", valid_595448
  var valid_595449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595449 = validateParameter(valid_595449, JString, required = false,
                                 default = nil)
  if valid_595449 != nil:
    section.add "X-Amz-SignedHeaders", valid_595449
  var valid_595450 = header.getOrDefault("X-Amz-Credential")
  valid_595450 = validateParameter(valid_595450, JString, required = false,
                                 default = nil)
  if valid_595450 != nil:
    section.add "X-Amz-Credential", valid_595450
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The tag key (name) of the tag to be removed.
  ##   ResourceName: JString (required)
  ##               : The Amazon DocumentDB resource that the tags are removed from. This value is an Amazon Resource Name (ARN).
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_595451 = formData.getOrDefault("TagKeys")
  valid_595451 = validateParameter(valid_595451, JArray, required = true, default = nil)
  if valid_595451 != nil:
    section.add "TagKeys", valid_595451
  var valid_595452 = formData.getOrDefault("ResourceName")
  valid_595452 = validateParameter(valid_595452, JString, required = true,
                                 default = nil)
  if valid_595452 != nil:
    section.add "ResourceName", valid_595452
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595453: Call_PostRemoveTagsFromResource_595439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_595453.validator(path, query, header, formData, body)
  let scheme = call_595453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595453.url(scheme.get, call_595453.host, call_595453.base,
                         call_595453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595453, url, valid)

proc call*(call_595454: Call_PostRemoveTagsFromResource_595439; TagKeys: JsonNode;
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
  var query_595455 = newJObject()
  var formData_595456 = newJObject()
  add(query_595455, "Action", newJString(Action))
  if TagKeys != nil:
    formData_595456.add "TagKeys", TagKeys
  add(formData_595456, "ResourceName", newJString(ResourceName))
  add(query_595455, "Version", newJString(Version))
  result = call_595454.call(nil, query_595455, nil, formData_595456, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_595439(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_595440, base: "/",
    url: url_PostRemoveTagsFromResource_595441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_595422 = ref object of OpenApiRestCall_593421
proc url_GetRemoveTagsFromResource_595424(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_595423(path: JsonNode; query: JsonNode;
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
  var valid_595425 = query.getOrDefault("ResourceName")
  valid_595425 = validateParameter(valid_595425, JString, required = true,
                                 default = nil)
  if valid_595425 != nil:
    section.add "ResourceName", valid_595425
  var valid_595426 = query.getOrDefault("Action")
  valid_595426 = validateParameter(valid_595426, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_595426 != nil:
    section.add "Action", valid_595426
  var valid_595427 = query.getOrDefault("TagKeys")
  valid_595427 = validateParameter(valid_595427, JArray, required = true, default = nil)
  if valid_595427 != nil:
    section.add "TagKeys", valid_595427
  var valid_595428 = query.getOrDefault("Version")
  valid_595428 = validateParameter(valid_595428, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595428 != nil:
    section.add "Version", valid_595428
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595429 = header.getOrDefault("X-Amz-Date")
  valid_595429 = validateParameter(valid_595429, JString, required = false,
                                 default = nil)
  if valid_595429 != nil:
    section.add "X-Amz-Date", valid_595429
  var valid_595430 = header.getOrDefault("X-Amz-Security-Token")
  valid_595430 = validateParameter(valid_595430, JString, required = false,
                                 default = nil)
  if valid_595430 != nil:
    section.add "X-Amz-Security-Token", valid_595430
  var valid_595431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595431 = validateParameter(valid_595431, JString, required = false,
                                 default = nil)
  if valid_595431 != nil:
    section.add "X-Amz-Content-Sha256", valid_595431
  var valid_595432 = header.getOrDefault("X-Amz-Algorithm")
  valid_595432 = validateParameter(valid_595432, JString, required = false,
                                 default = nil)
  if valid_595432 != nil:
    section.add "X-Amz-Algorithm", valid_595432
  var valid_595433 = header.getOrDefault("X-Amz-Signature")
  valid_595433 = validateParameter(valid_595433, JString, required = false,
                                 default = nil)
  if valid_595433 != nil:
    section.add "X-Amz-Signature", valid_595433
  var valid_595434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595434 = validateParameter(valid_595434, JString, required = false,
                                 default = nil)
  if valid_595434 != nil:
    section.add "X-Amz-SignedHeaders", valid_595434
  var valid_595435 = header.getOrDefault("X-Amz-Credential")
  valid_595435 = validateParameter(valid_595435, JString, required = false,
                                 default = nil)
  if valid_595435 != nil:
    section.add "X-Amz-Credential", valid_595435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595436: Call_GetRemoveTagsFromResource_595422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from an Amazon DocumentDB resource.
  ## 
  let valid = call_595436.validator(path, query, header, formData, body)
  let scheme = call_595436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595436.url(scheme.get, call_595436.host, call_595436.base,
                         call_595436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595436, url, valid)

proc call*(call_595437: Call_GetRemoveTagsFromResource_595422;
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
  var query_595438 = newJObject()
  add(query_595438, "ResourceName", newJString(ResourceName))
  add(query_595438, "Action", newJString(Action))
  if TagKeys != nil:
    query_595438.add "TagKeys", TagKeys
  add(query_595438, "Version", newJString(Version))
  result = call_595437.call(nil, query_595438, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_595422(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_595423, base: "/",
    url: url_GetRemoveTagsFromResource_595424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBClusterParameterGroup_595475 = ref object of OpenApiRestCall_593421
proc url_PostResetDBClusterParameterGroup_595477(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBClusterParameterGroup_595476(path: JsonNode;
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
  var valid_595478 = query.getOrDefault("Action")
  valid_595478 = validateParameter(valid_595478, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_595478 != nil:
    section.add "Action", valid_595478
  var valid_595479 = query.getOrDefault("Version")
  valid_595479 = validateParameter(valid_595479, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595479 != nil:
    section.add "Version", valid_595479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595480 = header.getOrDefault("X-Amz-Date")
  valid_595480 = validateParameter(valid_595480, JString, required = false,
                                 default = nil)
  if valid_595480 != nil:
    section.add "X-Amz-Date", valid_595480
  var valid_595481 = header.getOrDefault("X-Amz-Security-Token")
  valid_595481 = validateParameter(valid_595481, JString, required = false,
                                 default = nil)
  if valid_595481 != nil:
    section.add "X-Amz-Security-Token", valid_595481
  var valid_595482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595482 = validateParameter(valid_595482, JString, required = false,
                                 default = nil)
  if valid_595482 != nil:
    section.add "X-Amz-Content-Sha256", valid_595482
  var valid_595483 = header.getOrDefault("X-Amz-Algorithm")
  valid_595483 = validateParameter(valid_595483, JString, required = false,
                                 default = nil)
  if valid_595483 != nil:
    section.add "X-Amz-Algorithm", valid_595483
  var valid_595484 = header.getOrDefault("X-Amz-Signature")
  valid_595484 = validateParameter(valid_595484, JString, required = false,
                                 default = nil)
  if valid_595484 != nil:
    section.add "X-Amz-Signature", valid_595484
  var valid_595485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595485 = validateParameter(valid_595485, JString, required = false,
                                 default = nil)
  if valid_595485 != nil:
    section.add "X-Amz-SignedHeaders", valid_595485
  var valid_595486 = header.getOrDefault("X-Amz-Credential")
  valid_595486 = validateParameter(valid_595486, JString, required = false,
                                 default = nil)
  if valid_595486 != nil:
    section.add "X-Amz-Credential", valid_595486
  result.add "header", section
  ## parameters in `formData` object:
  ##   Parameters: JArray
  ##             : A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the <code>ResetAllParameters</code> parameter is set to <code>true</code>.
  ##   DBClusterParameterGroupName: JString (required)
  ##                              : The name of the DB cluster parameter group to reset.
  ##   ResetAllParameters: JBool
  ##                     : A value that is set to <code>true</code> to reset all parameters in the DB cluster parameter group to their default values, and <code>false</code> otherwise. You can't use this parameter if there is a list of parameter names specified for the <code>Parameters</code> parameter.
  section = newJObject()
  var valid_595487 = formData.getOrDefault("Parameters")
  valid_595487 = validateParameter(valid_595487, JArray, required = false,
                                 default = nil)
  if valid_595487 != nil:
    section.add "Parameters", valid_595487
  assert formData != nil, "formData argument is necessary due to required `DBClusterParameterGroupName` field"
  var valid_595488 = formData.getOrDefault("DBClusterParameterGroupName")
  valid_595488 = validateParameter(valid_595488, JString, required = true,
                                 default = nil)
  if valid_595488 != nil:
    section.add "DBClusterParameterGroupName", valid_595488
  var valid_595489 = formData.getOrDefault("ResetAllParameters")
  valid_595489 = validateParameter(valid_595489, JBool, required = false, default = nil)
  if valid_595489 != nil:
    section.add "ResetAllParameters", valid_595489
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595490: Call_PostResetDBClusterParameterGroup_595475;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_595490.validator(path, query, header, formData, body)
  let scheme = call_595490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595490.url(scheme.get, call_595490.host, call_595490.base,
                         call_595490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595490, url, valid)

proc call*(call_595491: Call_PostResetDBClusterParameterGroup_595475;
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
  var query_595492 = newJObject()
  var formData_595493 = newJObject()
  if Parameters != nil:
    formData_595493.add "Parameters", Parameters
  add(query_595492, "Action", newJString(Action))
  add(formData_595493, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  add(formData_595493, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_595492, "Version", newJString(Version))
  result = call_595491.call(nil, query_595492, nil, formData_595493, nil)

var postResetDBClusterParameterGroup* = Call_PostResetDBClusterParameterGroup_595475(
    name: "postResetDBClusterParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_PostResetDBClusterParameterGroup_595476, base: "/",
    url: url_PostResetDBClusterParameterGroup_595477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBClusterParameterGroup_595457 = ref object of OpenApiRestCall_593421
proc url_GetResetDBClusterParameterGroup_595459(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBClusterParameterGroup_595458(path: JsonNode;
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
  var valid_595460 = query.getOrDefault("DBClusterParameterGroupName")
  valid_595460 = validateParameter(valid_595460, JString, required = true,
                                 default = nil)
  if valid_595460 != nil:
    section.add "DBClusterParameterGroupName", valid_595460
  var valid_595461 = query.getOrDefault("Parameters")
  valid_595461 = validateParameter(valid_595461, JArray, required = false,
                                 default = nil)
  if valid_595461 != nil:
    section.add "Parameters", valid_595461
  var valid_595462 = query.getOrDefault("Action")
  valid_595462 = validateParameter(valid_595462, JString, required = true, default = newJString(
      "ResetDBClusterParameterGroup"))
  if valid_595462 != nil:
    section.add "Action", valid_595462
  var valid_595463 = query.getOrDefault("ResetAllParameters")
  valid_595463 = validateParameter(valid_595463, JBool, required = false, default = nil)
  if valid_595463 != nil:
    section.add "ResetAllParameters", valid_595463
  var valid_595464 = query.getOrDefault("Version")
  valid_595464 = validateParameter(valid_595464, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595464 != nil:
    section.add "Version", valid_595464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595465 = header.getOrDefault("X-Amz-Date")
  valid_595465 = validateParameter(valid_595465, JString, required = false,
                                 default = nil)
  if valid_595465 != nil:
    section.add "X-Amz-Date", valid_595465
  var valid_595466 = header.getOrDefault("X-Amz-Security-Token")
  valid_595466 = validateParameter(valid_595466, JString, required = false,
                                 default = nil)
  if valid_595466 != nil:
    section.add "X-Amz-Security-Token", valid_595466
  var valid_595467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595467 = validateParameter(valid_595467, JString, required = false,
                                 default = nil)
  if valid_595467 != nil:
    section.add "X-Amz-Content-Sha256", valid_595467
  var valid_595468 = header.getOrDefault("X-Amz-Algorithm")
  valid_595468 = validateParameter(valid_595468, JString, required = false,
                                 default = nil)
  if valid_595468 != nil:
    section.add "X-Amz-Algorithm", valid_595468
  var valid_595469 = header.getOrDefault("X-Amz-Signature")
  valid_595469 = validateParameter(valid_595469, JString, required = false,
                                 default = nil)
  if valid_595469 != nil:
    section.add "X-Amz-Signature", valid_595469
  var valid_595470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595470 = validateParameter(valid_595470, JString, required = false,
                                 default = nil)
  if valid_595470 != nil:
    section.add "X-Amz-SignedHeaders", valid_595470
  var valid_595471 = header.getOrDefault("X-Amz-Credential")
  valid_595471 = validateParameter(valid_595471, JString, required = false,
                                 default = nil)
  if valid_595471 != nil:
    section.add "X-Amz-Credential", valid_595471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595472: Call_GetResetDBClusterParameterGroup_595457;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p> Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters, submit a list of the following: <code>ParameterName</code> and <code>ApplyMethod</code>. To reset the entire DB cluster parameter group, specify the <code>DBClusterParameterGroupName</code> and <code>ResetAllParameters</code> parameters. </p> <p> When you reset the entire group, dynamic parameters are updated immediately and static parameters are set to <code>pending-reboot</code> to take effect on the next DB instance reboot.</p>
  ## 
  let valid = call_595472.validator(path, query, header, formData, body)
  let scheme = call_595472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595472.url(scheme.get, call_595472.host, call_595472.base,
                         call_595472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595472, url, valid)

proc call*(call_595473: Call_GetResetDBClusterParameterGroup_595457;
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
  var query_595474 = newJObject()
  add(query_595474, "DBClusterParameterGroupName",
      newJString(DBClusterParameterGroupName))
  if Parameters != nil:
    query_595474.add "Parameters", Parameters
  add(query_595474, "Action", newJString(Action))
  add(query_595474, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_595474, "Version", newJString(Version))
  result = call_595473.call(nil, query_595474, nil, nil, nil)

var getResetDBClusterParameterGroup* = Call_GetResetDBClusterParameterGroup_595457(
    name: "getResetDBClusterParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBClusterParameterGroup",
    validator: validate_GetResetDBClusterParameterGroup_595458, base: "/",
    url: url_GetResetDBClusterParameterGroup_595459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterFromSnapshot_595521 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBClusterFromSnapshot_595523(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBClusterFromSnapshot_595522(path: JsonNode;
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
  var valid_595524 = query.getOrDefault("Action")
  valid_595524 = validateParameter(valid_595524, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_595524 != nil:
    section.add "Action", valid_595524
  var valid_595525 = query.getOrDefault("Version")
  valid_595525 = validateParameter(valid_595525, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595525 != nil:
    section.add "Version", valid_595525
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595526 = header.getOrDefault("X-Amz-Date")
  valid_595526 = validateParameter(valid_595526, JString, required = false,
                                 default = nil)
  if valid_595526 != nil:
    section.add "X-Amz-Date", valid_595526
  var valid_595527 = header.getOrDefault("X-Amz-Security-Token")
  valid_595527 = validateParameter(valid_595527, JString, required = false,
                                 default = nil)
  if valid_595527 != nil:
    section.add "X-Amz-Security-Token", valid_595527
  var valid_595528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595528 = validateParameter(valid_595528, JString, required = false,
                                 default = nil)
  if valid_595528 != nil:
    section.add "X-Amz-Content-Sha256", valid_595528
  var valid_595529 = header.getOrDefault("X-Amz-Algorithm")
  valid_595529 = validateParameter(valid_595529, JString, required = false,
                                 default = nil)
  if valid_595529 != nil:
    section.add "X-Amz-Algorithm", valid_595529
  var valid_595530 = header.getOrDefault("X-Amz-Signature")
  valid_595530 = validateParameter(valid_595530, JString, required = false,
                                 default = nil)
  if valid_595530 != nil:
    section.add "X-Amz-Signature", valid_595530
  var valid_595531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595531 = validateParameter(valid_595531, JString, required = false,
                                 default = nil)
  if valid_595531 != nil:
    section.add "X-Amz-SignedHeaders", valid_595531
  var valid_595532 = header.getOrDefault("X-Amz-Credential")
  valid_595532 = validateParameter(valid_595532, JString, required = false,
                                 default = nil)
  if valid_595532 != nil:
    section.add "X-Amz-Credential", valid_595532
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
  var valid_595533 = formData.getOrDefault("Port")
  valid_595533 = validateParameter(valid_595533, JInt, required = false, default = nil)
  if valid_595533 != nil:
    section.add "Port", valid_595533
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_595534 = formData.getOrDefault("Engine")
  valid_595534 = validateParameter(valid_595534, JString, required = true,
                                 default = nil)
  if valid_595534 != nil:
    section.add "Engine", valid_595534
  var valid_595535 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_595535 = validateParameter(valid_595535, JArray, required = false,
                                 default = nil)
  if valid_595535 != nil:
    section.add "VpcSecurityGroupIds", valid_595535
  var valid_595536 = formData.getOrDefault("Tags")
  valid_595536 = validateParameter(valid_595536, JArray, required = false,
                                 default = nil)
  if valid_595536 != nil:
    section.add "Tags", valid_595536
  var valid_595537 = formData.getOrDefault("DeletionProtection")
  valid_595537 = validateParameter(valid_595537, JBool, required = false, default = nil)
  if valid_595537 != nil:
    section.add "DeletionProtection", valid_595537
  var valid_595538 = formData.getOrDefault("DBSubnetGroupName")
  valid_595538 = validateParameter(valid_595538, JString, required = false,
                                 default = nil)
  if valid_595538 != nil:
    section.add "DBSubnetGroupName", valid_595538
  var valid_595539 = formData.getOrDefault("AvailabilityZones")
  valid_595539 = validateParameter(valid_595539, JArray, required = false,
                                 default = nil)
  if valid_595539 != nil:
    section.add "AvailabilityZones", valid_595539
  var valid_595540 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_595540 = validateParameter(valid_595540, JArray, required = false,
                                 default = nil)
  if valid_595540 != nil:
    section.add "EnableCloudwatchLogsExports", valid_595540
  var valid_595541 = formData.getOrDefault("KmsKeyId")
  valid_595541 = validateParameter(valid_595541, JString, required = false,
                                 default = nil)
  if valid_595541 != nil:
    section.add "KmsKeyId", valid_595541
  var valid_595542 = formData.getOrDefault("SnapshotIdentifier")
  valid_595542 = validateParameter(valid_595542, JString, required = true,
                                 default = nil)
  if valid_595542 != nil:
    section.add "SnapshotIdentifier", valid_595542
  var valid_595543 = formData.getOrDefault("DBClusterIdentifier")
  valid_595543 = validateParameter(valid_595543, JString, required = true,
                                 default = nil)
  if valid_595543 != nil:
    section.add "DBClusterIdentifier", valid_595543
  var valid_595544 = formData.getOrDefault("EngineVersion")
  valid_595544 = validateParameter(valid_595544, JString, required = false,
                                 default = nil)
  if valid_595544 != nil:
    section.add "EngineVersion", valid_595544
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595545: Call_PostRestoreDBClusterFromSnapshot_595521;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_595545.validator(path, query, header, formData, body)
  let scheme = call_595545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595545.url(scheme.get, call_595545.host, call_595545.base,
                         call_595545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595545, url, valid)

proc call*(call_595546: Call_PostRestoreDBClusterFromSnapshot_595521;
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
  var query_595547 = newJObject()
  var formData_595548 = newJObject()
  add(formData_595548, "Port", newJInt(Port))
  add(formData_595548, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_595548.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if Tags != nil:
    formData_595548.add "Tags", Tags
  add(formData_595548, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_595548, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595547, "Action", newJString(Action))
  if AvailabilityZones != nil:
    formData_595548.add "AvailabilityZones", AvailabilityZones
  if EnableCloudwatchLogsExports != nil:
    formData_595548.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_595548, "KmsKeyId", newJString(KmsKeyId))
  add(formData_595548, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(formData_595548, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(formData_595548, "EngineVersion", newJString(EngineVersion))
  add(query_595547, "Version", newJString(Version))
  result = call_595546.call(nil, query_595547, nil, formData_595548, nil)

var postRestoreDBClusterFromSnapshot* = Call_PostRestoreDBClusterFromSnapshot_595521(
    name: "postRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_PostRestoreDBClusterFromSnapshot_595522, base: "/",
    url: url_PostRestoreDBClusterFromSnapshot_595523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterFromSnapshot_595494 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBClusterFromSnapshot_595496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBClusterFromSnapshot_595495(path: JsonNode;
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
  var valid_595497 = query.getOrDefault("Engine")
  valid_595497 = validateParameter(valid_595497, JString, required = true,
                                 default = nil)
  if valid_595497 != nil:
    section.add "Engine", valid_595497
  var valid_595498 = query.getOrDefault("AvailabilityZones")
  valid_595498 = validateParameter(valid_595498, JArray, required = false,
                                 default = nil)
  if valid_595498 != nil:
    section.add "AvailabilityZones", valid_595498
  var valid_595499 = query.getOrDefault("DBClusterIdentifier")
  valid_595499 = validateParameter(valid_595499, JString, required = true,
                                 default = nil)
  if valid_595499 != nil:
    section.add "DBClusterIdentifier", valid_595499
  var valid_595500 = query.getOrDefault("VpcSecurityGroupIds")
  valid_595500 = validateParameter(valid_595500, JArray, required = false,
                                 default = nil)
  if valid_595500 != nil:
    section.add "VpcSecurityGroupIds", valid_595500
  var valid_595501 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_595501 = validateParameter(valid_595501, JArray, required = false,
                                 default = nil)
  if valid_595501 != nil:
    section.add "EnableCloudwatchLogsExports", valid_595501
  var valid_595502 = query.getOrDefault("Tags")
  valid_595502 = validateParameter(valid_595502, JArray, required = false,
                                 default = nil)
  if valid_595502 != nil:
    section.add "Tags", valid_595502
  var valid_595503 = query.getOrDefault("DeletionProtection")
  valid_595503 = validateParameter(valid_595503, JBool, required = false, default = nil)
  if valid_595503 != nil:
    section.add "DeletionProtection", valid_595503
  var valid_595504 = query.getOrDefault("Action")
  valid_595504 = validateParameter(valid_595504, JString, required = true, default = newJString(
      "RestoreDBClusterFromSnapshot"))
  if valid_595504 != nil:
    section.add "Action", valid_595504
  var valid_595505 = query.getOrDefault("DBSubnetGroupName")
  valid_595505 = validateParameter(valid_595505, JString, required = false,
                                 default = nil)
  if valid_595505 != nil:
    section.add "DBSubnetGroupName", valid_595505
  var valid_595506 = query.getOrDefault("KmsKeyId")
  valid_595506 = validateParameter(valid_595506, JString, required = false,
                                 default = nil)
  if valid_595506 != nil:
    section.add "KmsKeyId", valid_595506
  var valid_595507 = query.getOrDefault("EngineVersion")
  valid_595507 = validateParameter(valid_595507, JString, required = false,
                                 default = nil)
  if valid_595507 != nil:
    section.add "EngineVersion", valid_595507
  var valid_595508 = query.getOrDefault("Port")
  valid_595508 = validateParameter(valid_595508, JInt, required = false, default = nil)
  if valid_595508 != nil:
    section.add "Port", valid_595508
  var valid_595509 = query.getOrDefault("SnapshotIdentifier")
  valid_595509 = validateParameter(valid_595509, JString, required = true,
                                 default = nil)
  if valid_595509 != nil:
    section.add "SnapshotIdentifier", valid_595509
  var valid_595510 = query.getOrDefault("Version")
  valid_595510 = validateParameter(valid_595510, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595510 != nil:
    section.add "Version", valid_595510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595511 = header.getOrDefault("X-Amz-Date")
  valid_595511 = validateParameter(valid_595511, JString, required = false,
                                 default = nil)
  if valid_595511 != nil:
    section.add "X-Amz-Date", valid_595511
  var valid_595512 = header.getOrDefault("X-Amz-Security-Token")
  valid_595512 = validateParameter(valid_595512, JString, required = false,
                                 default = nil)
  if valid_595512 != nil:
    section.add "X-Amz-Security-Token", valid_595512
  var valid_595513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595513 = validateParameter(valid_595513, JString, required = false,
                                 default = nil)
  if valid_595513 != nil:
    section.add "X-Amz-Content-Sha256", valid_595513
  var valid_595514 = header.getOrDefault("X-Amz-Algorithm")
  valid_595514 = validateParameter(valid_595514, JString, required = false,
                                 default = nil)
  if valid_595514 != nil:
    section.add "X-Amz-Algorithm", valid_595514
  var valid_595515 = header.getOrDefault("X-Amz-Signature")
  valid_595515 = validateParameter(valid_595515, JString, required = false,
                                 default = nil)
  if valid_595515 != nil:
    section.add "X-Amz-Signature", valid_595515
  var valid_595516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595516 = validateParameter(valid_595516, JString, required = false,
                                 default = nil)
  if valid_595516 != nil:
    section.add "X-Amz-SignedHeaders", valid_595516
  var valid_595517 = header.getOrDefault("X-Amz-Credential")
  valid_595517 = validateParameter(valid_595517, JString, required = false,
                                 default = nil)
  if valid_595517 != nil:
    section.add "X-Amz-Credential", valid_595517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595518: Call_GetRestoreDBClusterFromSnapshot_595494;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new DB cluster from a DB snapshot or DB cluster snapshot.</p> <p>If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group.</p> <p>If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.</p>
  ## 
  let valid = call_595518.validator(path, query, header, formData, body)
  let scheme = call_595518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595518.url(scheme.get, call_595518.host, call_595518.base,
                         call_595518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595518, url, valid)

proc call*(call_595519: Call_GetRestoreDBClusterFromSnapshot_595494;
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
  var query_595520 = newJObject()
  add(query_595520, "Engine", newJString(Engine))
  if AvailabilityZones != nil:
    query_595520.add "AvailabilityZones", AvailabilityZones
  add(query_595520, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_595520.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_595520.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_595520.add "Tags", Tags
  add(query_595520, "DeletionProtection", newJBool(DeletionProtection))
  add(query_595520, "Action", newJString(Action))
  add(query_595520, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595520, "KmsKeyId", newJString(KmsKeyId))
  add(query_595520, "EngineVersion", newJString(EngineVersion))
  add(query_595520, "Port", newJInt(Port))
  add(query_595520, "SnapshotIdentifier", newJString(SnapshotIdentifier))
  add(query_595520, "Version", newJString(Version))
  result = call_595519.call(nil, query_595520, nil, nil, nil)

var getRestoreDBClusterFromSnapshot* = Call_GetRestoreDBClusterFromSnapshot_595494(
    name: "getRestoreDBClusterFromSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterFromSnapshot",
    validator: validate_GetRestoreDBClusterFromSnapshot_595495, base: "/",
    url: url_GetRestoreDBClusterFromSnapshot_595496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBClusterToPointInTime_595575 = ref object of OpenApiRestCall_593421
proc url_PostRestoreDBClusterToPointInTime_595577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBClusterToPointInTime_595576(path: JsonNode;
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
  var valid_595578 = query.getOrDefault("Action")
  valid_595578 = validateParameter(valid_595578, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_595578 != nil:
    section.add "Action", valid_595578
  var valid_595579 = query.getOrDefault("Version")
  valid_595579 = validateParameter(valid_595579, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595579 != nil:
    section.add "Version", valid_595579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595580 = header.getOrDefault("X-Amz-Date")
  valid_595580 = validateParameter(valid_595580, JString, required = false,
                                 default = nil)
  if valid_595580 != nil:
    section.add "X-Amz-Date", valid_595580
  var valid_595581 = header.getOrDefault("X-Amz-Security-Token")
  valid_595581 = validateParameter(valid_595581, JString, required = false,
                                 default = nil)
  if valid_595581 != nil:
    section.add "X-Amz-Security-Token", valid_595581
  var valid_595582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595582 = validateParameter(valid_595582, JString, required = false,
                                 default = nil)
  if valid_595582 != nil:
    section.add "X-Amz-Content-Sha256", valid_595582
  var valid_595583 = header.getOrDefault("X-Amz-Algorithm")
  valid_595583 = validateParameter(valid_595583, JString, required = false,
                                 default = nil)
  if valid_595583 != nil:
    section.add "X-Amz-Algorithm", valid_595583
  var valid_595584 = header.getOrDefault("X-Amz-Signature")
  valid_595584 = validateParameter(valid_595584, JString, required = false,
                                 default = nil)
  if valid_595584 != nil:
    section.add "X-Amz-Signature", valid_595584
  var valid_595585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595585 = validateParameter(valid_595585, JString, required = false,
                                 default = nil)
  if valid_595585 != nil:
    section.add "X-Amz-SignedHeaders", valid_595585
  var valid_595586 = header.getOrDefault("X-Amz-Credential")
  valid_595586 = validateParameter(valid_595586, JString, required = false,
                                 default = nil)
  if valid_595586 != nil:
    section.add "X-Amz-Credential", valid_595586
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
  var valid_595587 = formData.getOrDefault("SourceDBClusterIdentifier")
  valid_595587 = validateParameter(valid_595587, JString, required = true,
                                 default = nil)
  if valid_595587 != nil:
    section.add "SourceDBClusterIdentifier", valid_595587
  var valid_595588 = formData.getOrDefault("UseLatestRestorableTime")
  valid_595588 = validateParameter(valid_595588, JBool, required = false, default = nil)
  if valid_595588 != nil:
    section.add "UseLatestRestorableTime", valid_595588
  var valid_595589 = formData.getOrDefault("Port")
  valid_595589 = validateParameter(valid_595589, JInt, required = false, default = nil)
  if valid_595589 != nil:
    section.add "Port", valid_595589
  var valid_595590 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_595590 = validateParameter(valid_595590, JArray, required = false,
                                 default = nil)
  if valid_595590 != nil:
    section.add "VpcSecurityGroupIds", valid_595590
  var valid_595591 = formData.getOrDefault("RestoreToTime")
  valid_595591 = validateParameter(valid_595591, JString, required = false,
                                 default = nil)
  if valid_595591 != nil:
    section.add "RestoreToTime", valid_595591
  var valid_595592 = formData.getOrDefault("Tags")
  valid_595592 = validateParameter(valid_595592, JArray, required = false,
                                 default = nil)
  if valid_595592 != nil:
    section.add "Tags", valid_595592
  var valid_595593 = formData.getOrDefault("DeletionProtection")
  valid_595593 = validateParameter(valid_595593, JBool, required = false, default = nil)
  if valid_595593 != nil:
    section.add "DeletionProtection", valid_595593
  var valid_595594 = formData.getOrDefault("DBSubnetGroupName")
  valid_595594 = validateParameter(valid_595594, JString, required = false,
                                 default = nil)
  if valid_595594 != nil:
    section.add "DBSubnetGroupName", valid_595594
  var valid_595595 = formData.getOrDefault("EnableCloudwatchLogsExports")
  valid_595595 = validateParameter(valid_595595, JArray, required = false,
                                 default = nil)
  if valid_595595 != nil:
    section.add "EnableCloudwatchLogsExports", valid_595595
  var valid_595596 = formData.getOrDefault("KmsKeyId")
  valid_595596 = validateParameter(valid_595596, JString, required = false,
                                 default = nil)
  if valid_595596 != nil:
    section.add "KmsKeyId", valid_595596
  var valid_595597 = formData.getOrDefault("DBClusterIdentifier")
  valid_595597 = validateParameter(valid_595597, JString, required = true,
                                 default = nil)
  if valid_595597 != nil:
    section.add "DBClusterIdentifier", valid_595597
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595598: Call_PostRestoreDBClusterToPointInTime_595575;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_595598.validator(path, query, header, formData, body)
  let scheme = call_595598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595598.url(scheme.get, call_595598.host, call_595598.base,
                         call_595598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595598, url, valid)

proc call*(call_595599: Call_PostRestoreDBClusterToPointInTime_595575;
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
  var query_595600 = newJObject()
  var formData_595601 = newJObject()
  add(formData_595601, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(formData_595601, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_595601, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    formData_595601.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_595601, "RestoreToTime", newJString(RestoreToTime))
  if Tags != nil:
    formData_595601.add "Tags", Tags
  add(formData_595601, "DeletionProtection", newJBool(DeletionProtection))
  add(formData_595601, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595600, "Action", newJString(Action))
  if EnableCloudwatchLogsExports != nil:
    formData_595601.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  add(formData_595601, "KmsKeyId", newJString(KmsKeyId))
  add(formData_595601, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_595600, "Version", newJString(Version))
  result = call_595599.call(nil, query_595600, nil, formData_595601, nil)

var postRestoreDBClusterToPointInTime* = Call_PostRestoreDBClusterToPointInTime_595575(
    name: "postRestoreDBClusterToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_PostRestoreDBClusterToPointInTime_595576, base: "/",
    url: url_PostRestoreDBClusterToPointInTime_595577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBClusterToPointInTime_595549 = ref object of OpenApiRestCall_593421
proc url_GetRestoreDBClusterToPointInTime_595551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBClusterToPointInTime_595550(path: JsonNode;
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
  var valid_595552 = query.getOrDefault("RestoreToTime")
  valid_595552 = validateParameter(valid_595552, JString, required = false,
                                 default = nil)
  if valid_595552 != nil:
    section.add "RestoreToTime", valid_595552
  assert query != nil, "query argument is necessary due to required `DBClusterIdentifier` field"
  var valid_595553 = query.getOrDefault("DBClusterIdentifier")
  valid_595553 = validateParameter(valid_595553, JString, required = true,
                                 default = nil)
  if valid_595553 != nil:
    section.add "DBClusterIdentifier", valid_595553
  var valid_595554 = query.getOrDefault("VpcSecurityGroupIds")
  valid_595554 = validateParameter(valid_595554, JArray, required = false,
                                 default = nil)
  if valid_595554 != nil:
    section.add "VpcSecurityGroupIds", valid_595554
  var valid_595555 = query.getOrDefault("EnableCloudwatchLogsExports")
  valid_595555 = validateParameter(valid_595555, JArray, required = false,
                                 default = nil)
  if valid_595555 != nil:
    section.add "EnableCloudwatchLogsExports", valid_595555
  var valid_595556 = query.getOrDefault("Tags")
  valid_595556 = validateParameter(valid_595556, JArray, required = false,
                                 default = nil)
  if valid_595556 != nil:
    section.add "Tags", valid_595556
  var valid_595557 = query.getOrDefault("DeletionProtection")
  valid_595557 = validateParameter(valid_595557, JBool, required = false, default = nil)
  if valid_595557 != nil:
    section.add "DeletionProtection", valid_595557
  var valid_595558 = query.getOrDefault("UseLatestRestorableTime")
  valid_595558 = validateParameter(valid_595558, JBool, required = false, default = nil)
  if valid_595558 != nil:
    section.add "UseLatestRestorableTime", valid_595558
  var valid_595559 = query.getOrDefault("Action")
  valid_595559 = validateParameter(valid_595559, JString, required = true, default = newJString(
      "RestoreDBClusterToPointInTime"))
  if valid_595559 != nil:
    section.add "Action", valid_595559
  var valid_595560 = query.getOrDefault("DBSubnetGroupName")
  valid_595560 = validateParameter(valid_595560, JString, required = false,
                                 default = nil)
  if valid_595560 != nil:
    section.add "DBSubnetGroupName", valid_595560
  var valid_595561 = query.getOrDefault("KmsKeyId")
  valid_595561 = validateParameter(valid_595561, JString, required = false,
                                 default = nil)
  if valid_595561 != nil:
    section.add "KmsKeyId", valid_595561
  var valid_595562 = query.getOrDefault("Port")
  valid_595562 = validateParameter(valid_595562, JInt, required = false, default = nil)
  if valid_595562 != nil:
    section.add "Port", valid_595562
  var valid_595563 = query.getOrDefault("SourceDBClusterIdentifier")
  valid_595563 = validateParameter(valid_595563, JString, required = true,
                                 default = nil)
  if valid_595563 != nil:
    section.add "SourceDBClusterIdentifier", valid_595563
  var valid_595564 = query.getOrDefault("Version")
  valid_595564 = validateParameter(valid_595564, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595564 != nil:
    section.add "Version", valid_595564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595565 = header.getOrDefault("X-Amz-Date")
  valid_595565 = validateParameter(valid_595565, JString, required = false,
                                 default = nil)
  if valid_595565 != nil:
    section.add "X-Amz-Date", valid_595565
  var valid_595566 = header.getOrDefault("X-Amz-Security-Token")
  valid_595566 = validateParameter(valid_595566, JString, required = false,
                                 default = nil)
  if valid_595566 != nil:
    section.add "X-Amz-Security-Token", valid_595566
  var valid_595567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595567 = validateParameter(valid_595567, JString, required = false,
                                 default = nil)
  if valid_595567 != nil:
    section.add "X-Amz-Content-Sha256", valid_595567
  var valid_595568 = header.getOrDefault("X-Amz-Algorithm")
  valid_595568 = validateParameter(valid_595568, JString, required = false,
                                 default = nil)
  if valid_595568 != nil:
    section.add "X-Amz-Algorithm", valid_595568
  var valid_595569 = header.getOrDefault("X-Amz-Signature")
  valid_595569 = validateParameter(valid_595569, JString, required = false,
                                 default = nil)
  if valid_595569 != nil:
    section.add "X-Amz-Signature", valid_595569
  var valid_595570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595570 = validateParameter(valid_595570, JString, required = false,
                                 default = nil)
  if valid_595570 != nil:
    section.add "X-Amz-SignedHeaders", valid_595570
  var valid_595571 = header.getOrDefault("X-Amz-Credential")
  valid_595571 = validateParameter(valid_595571, JString, required = false,
                                 default = nil)
  if valid_595571 != nil:
    section.add "X-Amz-Credential", valid_595571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595572: Call_GetRestoreDBClusterToPointInTime_595549;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before <code>LatestRestorableTime</code> for up to <code>BackupRetentionPeriod</code> days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. 
  ## 
  let valid = call_595572.validator(path, query, header, formData, body)
  let scheme = call_595572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595572.url(scheme.get, call_595572.host, call_595572.base,
                         call_595572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595572, url, valid)

proc call*(call_595573: Call_GetRestoreDBClusterToPointInTime_595549;
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
  var query_595574 = newJObject()
  add(query_595574, "RestoreToTime", newJString(RestoreToTime))
  add(query_595574, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  if VpcSecurityGroupIds != nil:
    query_595574.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  if EnableCloudwatchLogsExports != nil:
    query_595574.add "EnableCloudwatchLogsExports", EnableCloudwatchLogsExports
  if Tags != nil:
    query_595574.add "Tags", Tags
  add(query_595574, "DeletionProtection", newJBool(DeletionProtection))
  add(query_595574, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_595574, "Action", newJString(Action))
  add(query_595574, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_595574, "KmsKeyId", newJString(KmsKeyId))
  add(query_595574, "Port", newJInt(Port))
  add(query_595574, "SourceDBClusterIdentifier",
      newJString(SourceDBClusterIdentifier))
  add(query_595574, "Version", newJString(Version))
  result = call_595573.call(nil, query_595574, nil, nil, nil)

var getRestoreDBClusterToPointInTime* = Call_GetRestoreDBClusterToPointInTime_595549(
    name: "getRestoreDBClusterToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBClusterToPointInTime",
    validator: validate_GetRestoreDBClusterToPointInTime_595550, base: "/",
    url: url_GetRestoreDBClusterToPointInTime_595551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStartDBCluster_595618 = ref object of OpenApiRestCall_593421
proc url_PostStartDBCluster_595620(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostStartDBCluster_595619(path: JsonNode; query: JsonNode;
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
  var valid_595621 = query.getOrDefault("Action")
  valid_595621 = validateParameter(valid_595621, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_595621 != nil:
    section.add "Action", valid_595621
  var valid_595622 = query.getOrDefault("Version")
  valid_595622 = validateParameter(valid_595622, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595622 != nil:
    section.add "Version", valid_595622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595623 = header.getOrDefault("X-Amz-Date")
  valid_595623 = validateParameter(valid_595623, JString, required = false,
                                 default = nil)
  if valid_595623 != nil:
    section.add "X-Amz-Date", valid_595623
  var valid_595624 = header.getOrDefault("X-Amz-Security-Token")
  valid_595624 = validateParameter(valid_595624, JString, required = false,
                                 default = nil)
  if valid_595624 != nil:
    section.add "X-Amz-Security-Token", valid_595624
  var valid_595625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595625 = validateParameter(valid_595625, JString, required = false,
                                 default = nil)
  if valid_595625 != nil:
    section.add "X-Amz-Content-Sha256", valid_595625
  var valid_595626 = header.getOrDefault("X-Amz-Algorithm")
  valid_595626 = validateParameter(valid_595626, JString, required = false,
                                 default = nil)
  if valid_595626 != nil:
    section.add "X-Amz-Algorithm", valid_595626
  var valid_595627 = header.getOrDefault("X-Amz-Signature")
  valid_595627 = validateParameter(valid_595627, JString, required = false,
                                 default = nil)
  if valid_595627 != nil:
    section.add "X-Amz-Signature", valid_595627
  var valid_595628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595628 = validateParameter(valid_595628, JString, required = false,
                                 default = nil)
  if valid_595628 != nil:
    section.add "X-Amz-SignedHeaders", valid_595628
  var valid_595629 = header.getOrDefault("X-Amz-Credential")
  valid_595629 = validateParameter(valid_595629, JString, required = false,
                                 default = nil)
  if valid_595629 != nil:
    section.add "X-Amz-Credential", valid_595629
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_595630 = formData.getOrDefault("DBClusterIdentifier")
  valid_595630 = validateParameter(valid_595630, JString, required = true,
                                 default = nil)
  if valid_595630 != nil:
    section.add "DBClusterIdentifier", valid_595630
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595631: Call_PostStartDBCluster_595618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_595631.validator(path, query, header, formData, body)
  let scheme = call_595631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595631.url(scheme.get, call_595631.host, call_595631.base,
                         call_595631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595631, url, valid)

proc call*(call_595632: Call_PostStartDBCluster_595618;
          DBClusterIdentifier: string; Action: string = "StartDBCluster";
          Version: string = "2014-10-31"): Recallable =
  ## postStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_595633 = newJObject()
  var formData_595634 = newJObject()
  add(query_595633, "Action", newJString(Action))
  add(formData_595634, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_595633, "Version", newJString(Version))
  result = call_595632.call(nil, query_595633, nil, formData_595634, nil)

var postStartDBCluster* = Call_PostStartDBCluster_595618(
    name: "postStartDBCluster", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=StartDBCluster",
    validator: validate_PostStartDBCluster_595619, base: "/",
    url: url_PostStartDBCluster_595620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStartDBCluster_595602 = ref object of OpenApiRestCall_593421
proc url_GetStartDBCluster_595604(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetStartDBCluster_595603(path: JsonNode; query: JsonNode;
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
  var valid_595605 = query.getOrDefault("DBClusterIdentifier")
  valid_595605 = validateParameter(valid_595605, JString, required = true,
                                 default = nil)
  if valid_595605 != nil:
    section.add "DBClusterIdentifier", valid_595605
  var valid_595606 = query.getOrDefault("Action")
  valid_595606 = validateParameter(valid_595606, JString, required = true,
                                 default = newJString("StartDBCluster"))
  if valid_595606 != nil:
    section.add "Action", valid_595606
  var valid_595607 = query.getOrDefault("Version")
  valid_595607 = validateParameter(valid_595607, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595607 != nil:
    section.add "Version", valid_595607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595608 = header.getOrDefault("X-Amz-Date")
  valid_595608 = validateParameter(valid_595608, JString, required = false,
                                 default = nil)
  if valid_595608 != nil:
    section.add "X-Amz-Date", valid_595608
  var valid_595609 = header.getOrDefault("X-Amz-Security-Token")
  valid_595609 = validateParameter(valid_595609, JString, required = false,
                                 default = nil)
  if valid_595609 != nil:
    section.add "X-Amz-Security-Token", valid_595609
  var valid_595610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595610 = validateParameter(valid_595610, JString, required = false,
                                 default = nil)
  if valid_595610 != nil:
    section.add "X-Amz-Content-Sha256", valid_595610
  var valid_595611 = header.getOrDefault("X-Amz-Algorithm")
  valid_595611 = validateParameter(valid_595611, JString, required = false,
                                 default = nil)
  if valid_595611 != nil:
    section.add "X-Amz-Algorithm", valid_595611
  var valid_595612 = header.getOrDefault("X-Amz-Signature")
  valid_595612 = validateParameter(valid_595612, JString, required = false,
                                 default = nil)
  if valid_595612 != nil:
    section.add "X-Amz-Signature", valid_595612
  var valid_595613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595613 = validateParameter(valid_595613, JString, required = false,
                                 default = nil)
  if valid_595613 != nil:
    section.add "X-Amz-SignedHeaders", valid_595613
  var valid_595614 = header.getOrDefault("X-Amz-Credential")
  valid_595614 = validateParameter(valid_595614, JString, required = false,
                                 default = nil)
  if valid_595614 != nil:
    section.add "X-Amz-Credential", valid_595614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595615: Call_GetStartDBCluster_595602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_595615.validator(path, query, header, formData, body)
  let scheme = call_595615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595615.url(scheme.get, call_595615.host, call_595615.base,
                         call_595615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595615, url, valid)

proc call*(call_595616: Call_GetStartDBCluster_595602; DBClusterIdentifier: string;
          Action: string = "StartDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStartDBCluster
  ## Restarts the stopped cluster that is specified by <code>DBClusterIdentifier</code>. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to restart. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595617 = newJObject()
  add(query_595617, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_595617, "Action", newJString(Action))
  add(query_595617, "Version", newJString(Version))
  result = call_595616.call(nil, query_595617, nil, nil, nil)

var getStartDBCluster* = Call_GetStartDBCluster_595602(name: "getStartDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StartDBCluster", validator: validate_GetStartDBCluster_595603,
    base: "/", url: url_GetStartDBCluster_595604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostStopDBCluster_595651 = ref object of OpenApiRestCall_593421
proc url_PostStopDBCluster_595653(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostStopDBCluster_595652(path: JsonNode; query: JsonNode;
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
  var valid_595654 = query.getOrDefault("Action")
  valid_595654 = validateParameter(valid_595654, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_595654 != nil:
    section.add "Action", valid_595654
  var valid_595655 = query.getOrDefault("Version")
  valid_595655 = validateParameter(valid_595655, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595655 != nil:
    section.add "Version", valid_595655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595656 = header.getOrDefault("X-Amz-Date")
  valid_595656 = validateParameter(valid_595656, JString, required = false,
                                 default = nil)
  if valid_595656 != nil:
    section.add "X-Amz-Date", valid_595656
  var valid_595657 = header.getOrDefault("X-Amz-Security-Token")
  valid_595657 = validateParameter(valid_595657, JString, required = false,
                                 default = nil)
  if valid_595657 != nil:
    section.add "X-Amz-Security-Token", valid_595657
  var valid_595658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595658 = validateParameter(valid_595658, JString, required = false,
                                 default = nil)
  if valid_595658 != nil:
    section.add "X-Amz-Content-Sha256", valid_595658
  var valid_595659 = header.getOrDefault("X-Amz-Algorithm")
  valid_595659 = validateParameter(valid_595659, JString, required = false,
                                 default = nil)
  if valid_595659 != nil:
    section.add "X-Amz-Algorithm", valid_595659
  var valid_595660 = header.getOrDefault("X-Amz-Signature")
  valid_595660 = validateParameter(valid_595660, JString, required = false,
                                 default = nil)
  if valid_595660 != nil:
    section.add "X-Amz-Signature", valid_595660
  var valid_595661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595661 = validateParameter(valid_595661, JString, required = false,
                                 default = nil)
  if valid_595661 != nil:
    section.add "X-Amz-SignedHeaders", valid_595661
  var valid_595662 = header.getOrDefault("X-Amz-Credential")
  valid_595662 = validateParameter(valid_595662, JString, required = false,
                                 default = nil)
  if valid_595662 != nil:
    section.add "X-Amz-Credential", valid_595662
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBClusterIdentifier: JString (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBClusterIdentifier` field"
  var valid_595663 = formData.getOrDefault("DBClusterIdentifier")
  valid_595663 = validateParameter(valid_595663, JString, required = true,
                                 default = nil)
  if valid_595663 != nil:
    section.add "DBClusterIdentifier", valid_595663
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595664: Call_PostStopDBCluster_595651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_595664.validator(path, query, header, formData, body)
  let scheme = call_595664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595664.url(scheme.get, call_595664.host, call_595664.base,
                         call_595664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595664, url, valid)

proc call*(call_595665: Call_PostStopDBCluster_595651; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## postStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   Action: string (required)
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Version: string (required)
  var query_595666 = newJObject()
  var formData_595667 = newJObject()
  add(query_595666, "Action", newJString(Action))
  add(formData_595667, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_595666, "Version", newJString(Version))
  result = call_595665.call(nil, query_595666, nil, formData_595667, nil)

var postStopDBCluster* = Call_PostStopDBCluster_595651(name: "postStopDBCluster",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_PostStopDBCluster_595652,
    base: "/", url: url_PostStopDBCluster_595653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStopDBCluster_595635 = ref object of OpenApiRestCall_593421
proc url_GetStopDBCluster_595637(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetStopDBCluster_595636(path: JsonNode; query: JsonNode;
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
  var valid_595638 = query.getOrDefault("DBClusterIdentifier")
  valid_595638 = validateParameter(valid_595638, JString, required = true,
                                 default = nil)
  if valid_595638 != nil:
    section.add "DBClusterIdentifier", valid_595638
  var valid_595639 = query.getOrDefault("Action")
  valid_595639 = validateParameter(valid_595639, JString, required = true,
                                 default = newJString("StopDBCluster"))
  if valid_595639 != nil:
    section.add "Action", valid_595639
  var valid_595640 = query.getOrDefault("Version")
  valid_595640 = validateParameter(valid_595640, JString, required = true,
                                 default = newJString("2014-10-31"))
  if valid_595640 != nil:
    section.add "Version", valid_595640
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595641 = header.getOrDefault("X-Amz-Date")
  valid_595641 = validateParameter(valid_595641, JString, required = false,
                                 default = nil)
  if valid_595641 != nil:
    section.add "X-Amz-Date", valid_595641
  var valid_595642 = header.getOrDefault("X-Amz-Security-Token")
  valid_595642 = validateParameter(valid_595642, JString, required = false,
                                 default = nil)
  if valid_595642 != nil:
    section.add "X-Amz-Security-Token", valid_595642
  var valid_595643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595643 = validateParameter(valid_595643, JString, required = false,
                                 default = nil)
  if valid_595643 != nil:
    section.add "X-Amz-Content-Sha256", valid_595643
  var valid_595644 = header.getOrDefault("X-Amz-Algorithm")
  valid_595644 = validateParameter(valid_595644, JString, required = false,
                                 default = nil)
  if valid_595644 != nil:
    section.add "X-Amz-Algorithm", valid_595644
  var valid_595645 = header.getOrDefault("X-Amz-Signature")
  valid_595645 = validateParameter(valid_595645, JString, required = false,
                                 default = nil)
  if valid_595645 != nil:
    section.add "X-Amz-Signature", valid_595645
  var valid_595646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595646 = validateParameter(valid_595646, JString, required = false,
                                 default = nil)
  if valid_595646 != nil:
    section.add "X-Amz-SignedHeaders", valid_595646
  var valid_595647 = header.getOrDefault("X-Amz-Credential")
  valid_595647 = validateParameter(valid_595647, JString, required = false,
                                 default = nil)
  if valid_595647 != nil:
    section.add "X-Amz-Credential", valid_595647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595648: Call_GetStopDBCluster_595635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ## 
  let valid = call_595648.validator(path, query, header, formData, body)
  let scheme = call_595648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595648.url(scheme.get, call_595648.host, call_595648.base,
                         call_595648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595648, url, valid)

proc call*(call_595649: Call_GetStopDBCluster_595635; DBClusterIdentifier: string;
          Action: string = "StopDBCluster"; Version: string = "2014-10-31"): Recallable =
  ## getStopDBCluster
  ## Stops the running cluster that is specified by <code>DBClusterIdentifier</code>. The cluster must be in the <i>available</i> state. For more information, see <a href="https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-stop-start.html">Stopping and Starting an Amazon DocumentDB Cluster</a>.
  ##   DBClusterIdentifier: string (required)
  ##                      : The identifier of the cluster to stop. Example: <code>docdb-2019-05-28-15-24-52</code> 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595650 = newJObject()
  add(query_595650, "DBClusterIdentifier", newJString(DBClusterIdentifier))
  add(query_595650, "Action", newJString(Action))
  add(query_595650, "Version", newJString(Version))
  result = call_595649.call(nil, query_595650, nil, nil, nil)

var getStopDBCluster* = Call_GetStopDBCluster_595635(name: "getStopDBCluster",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=StopDBCluster", validator: validate_GetStopDBCluster_595636,
    base: "/", url: url_GetStopDBCluster_595637,
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
